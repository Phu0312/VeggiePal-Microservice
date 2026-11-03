package com.veggiepal.ai.recommendation;

import com.veggiepal.ai.provider.LocalAiClient;
import static com.veggiepal.ai.recommendation.RecommendationDtos.*;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.Locale;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.veggiepal.ai.common.AppException;
import com.veggiepal.ai.common.ErrorCode;
import com.veggiepal.ai.provider.AiMessage;
import com.veggiepal.ai.monitoring.UsageService;
import com.veggiepal.ai.mealplan.MealPlanValidator;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

@Service
public class RecommendationService {
    private static final Logger log = LoggerFactory.getLogger(RecommendationService.class);
    private static final int MAX_PROMPT_CANDIDATES = 24;
    private static final int RECOMMENDATION_MAX_TOKENS = 650;
    private static final double RECOMMENDATION_TEMPERATURE = 0.2;

    private final RestClient http;
    private final String blogUrl;
    private final String recipeUrl;
    private final LocalAiClient ai;
    private final ObjectMapper mapper;
    private final UsageService usage;
    private final MealPlanValidator validator;
    private final String nutritionUrl;

    @Autowired
    public RecommendationService(@Qualifier("serviceRestClient") RestClient http,
            @Value("${services.blog.base-url}") String blogUrl, @Value("${services.recipe.base-url}") String recipeUrl,
            LocalAiClient ai, ObjectMapper mapper, UsageService usage,
            MealPlanValidator validator, @Value("${services.nutrition.base-url}") String nutritionUrl) {
        this.http = http;
        this.blogUrl = blogUrl;
        this.recipeUrl = recipeUrl;
        this.ai = ai;
        this.mapper = mapper;
        this.usage = usage;
        this.validator = validator;
        this.nutritionUrl = nutritionUrl;
    }

    public RecommendationService(RestClient http, String blogUrl, String recipeUrl,
            LocalAiClient ai, ObjectMapper mapper, UsageService usage) {
        this.http = http;
        this.blogUrl = blogUrl;
        this.recipeUrl = recipeUrl;
        this.ai = ai;
        this.mapper = mapper;
        this.usage = usage;
        this.validator = null;
        this.nutritionUrl = null;
    }

    public List<Recommendation> recommend(Long userId, String interest, int limit) {
        return recommend(userId, null, interest, limit);
    }

    public List<Recommendation> recommend(Long userId, String jwt, String interest, int limit) {
        int safeLimit = Math.max(1, Math.min(limit, 10));
        String normalizedInterest = (interest == null || interest.isBlank()) ? "" : interest.trim();
        List<Candidate> candidates = fetchCandidates(query(normalizedInterest));
        // A keyword that matches no title would leave the AI nothing to rank; let it pick from the latest items.
        if (candidates.isEmpty() && !query(normalizedInterest).isEmpty()) {
            candidates = fetchCandidates("");
        }
        if (candidates.isEmpty()) {
            return List.of();
        }
        if (validator != null) {
            JsonNode allergies = allergies(jwt);
            candidates = candidates.stream()
                    .filter(c -> !"RECIPE".equals(c.type)
                            || (validator.isVegan(c.node) && validator.isAllergySafe(c.node, allergies)))
                    .toList();
        }
        if (candidates.isEmpty()) {
            return List.of();
        }

        List<Candidate> promptCandidates = candidates.size() > MAX_PROMPT_CANDIDATES
                ? candidates.subList(0, MAX_PROMPT_CANDIDATES)
                : candidates;

        usage.reserveLocalTestRequest("user:" + userId, "RECOMMENDATION");
        usage.checkTextBudget("user:" + userId);
        String compact;
        try {
            compact = mapper.writeValueAsString(promptCandidates.stream()
                    .map(c -> Map.of("type", c.type, "id", c.id, "title", c.node.path("title").asText("")))
                    .toList());
        } catch (Exception e) {
            throw new AppException(ErrorCode.INVALID_REQUEST, e);
        }

        String displayInterest = normalizedInterest.isEmpty() ? "ăn chay lành mạnh" : normalizedInterest;
        String prompt = """
                Chọn tối đa %d nội dung thuần chay phù hợp nhất với sở thích '%s'.
                Chỉ chọn từ danh sách Candidates đã cho, không lặp lại id.
                Mỗi mục BẮT BUỘC có trường "reason" giải thích cụ thể vì sao nội dung đó phù hợp sở thích '%s'.
                Trả về DUY NHẤT JSON array ví dụ: [{"type":"RECIPE","id":101,"reason":"Món ăn thanh đạm giàu dinh dưỡng phù hợp cho bữa ăn thuần chay"}].
                TUYỆT ĐỐI không chép lại câu ví dụ trên vào kết quả, phải viết lý do thực tế theo món.
                Candidates: %s""".formatted(safeLimit, displayInterest, displayInterest, compact);

        long start = System.nanoTime();
        try {
            var result = ai.complete(List.of(new AiMessage("user", prompt)), RECOMMENDATION_TEMPERATURE, RECOMMENDATION_MAX_TOKENS);
            usage.success(userId, "user:" + userId, "RECOMMENDATION", ai.configuredModel(), result, elapsed(start));
            JsonNode ranked = mapper.readTree(cleanJson(result.content()));
            if (!ranked.isArray()) {
                throw new AppException(ErrorCode.INVALID_AI_RESPONSE);
            }
            Map<String, Candidate> byKey = new HashMap<>();
            candidates.forEach(c -> byKey.put(c.type + ":" + c.id, c));
            List<Recommendation> response = new ArrayList<>();
            Set<String> seen = new HashSet<>();
            for (JsonNode item : ranked) {
                String type = item.path("type").asText("").trim().toUpperCase();
                long id = item.path("id").asLong(-1);
                String key = type + ":" + id;
                Candidate c = byKey.get(key);
                if (c != null && seen.add(key) && response.size() < safeLimit) {
                    String rawReason = item.path("reason").asText("");
                    String finalReason = ensureMeaningfulReason(rawReason, c, displayInterest);
                    response.add(new Recommendation(type, id, finalReason, mapper.convertValue(c.node, Object.class)));
                }
            }
            if (response.isEmpty() && !promptCandidates.isEmpty()) {
                for (Candidate c : promptCandidates) {
                    if (response.size() >= safeLimit) break;
                    String key = c.type + ":" + c.id;
                    if (seen.add(key)) {
                        String fallbackReason = buildFallbackReason(c, displayInterest);
                        response.add(new Recommendation(c.type, c.id, fallbackReason, mapper.convertValue(c.node, Object.class)));
                    }
                }
            }
            return response;
        } catch (AppException e) {
            usage.failure(userId, "user:" + userId, "RECOMMENDATION", ai.configuredModel(), elapsed(start), e);
            throw e;
        } catch (Exception e) {
            usage.failure(userId, "user:" + userId, "RECOMMENDATION", ai.configuredModel(), elapsed(start), e);
            throw new AppException(ErrorCode.INVALID_AI_RESPONSE, e);
        }
    }

    String ensureMeaningfulReason(String rawReason, Candidate candidate, String displayInterest) {
        if (rawReason != null && !isPlaceholderOrGeneric(rawReason)) {
            return rawReason.trim();
        }
        return buildFallbackReason(candidate, displayInterest);
    }

    private boolean isPlaceholderOrGeneric(String reason) {
        if (reason == null || reason.isBlank()) {
            return true;
        }
        String lower = reason.trim().toLowerCase(Locale.ROOT);
        return lower.contains("lý do gợi ý")
                || lower.contains("ngắn gọn bằng tiếng việt")
                || lower.contains("placeholder")
                || lower.contains("món ăn thanh đạm giàu dinh dưỡng phù hợp cho bữa ăn thuần chay")
                || lower.equals("...")
                || lower.equals("null")
                || lower.equals("chưa có lý do");
    }

    private String buildFallbackReason(Candidate candidate, String displayInterest) {
        String title = candidate.node.path("title").asText("").trim();
        String typeLabel = "RECIPE".equals(candidate.type) ? "Món chay" : "Bài viết";
        String cleanInterest = (displayInterest == null || displayInterest.isBlank())
                ? "ẩm thực thuần chay lành mạnh"
                : displayInterest.trim();
        if (!title.isEmpty()) {
            return "%s \"%s\" phù hợp với nhu cầu tìm kiếm về %s.".formatted(typeLabel, title, cleanInterest);
        }
        return "%s thuần chay phù hợp với sở thích %s của bạn.".formatted(typeLabel, cleanInterest);
    }

    private JsonNode allergies(String jwt) {
        if (jwt == null || jwt.isBlank()) throw new AppException(ErrorCode.UNAUTHENTICATED);
        try {
            JsonNode response = http.get().uri(nutritionUrl + "/nutrition/me/allergies")
                    .header(HttpHeaders.AUTHORIZATION, "Bearer " + jwt).retrieve().body(JsonNode.class);
            JsonNode items = response == null ? null : response.path("result");
            if (items == null || !items.isArray()) throw new AppException(ErrorCode.DOWNSTREAM_UNAVAILABLE);
            return items;
        } catch (AppException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new AppException(ErrorCode.DOWNSTREAM_UNAVAILABLE, ex);
        }
    }

    // One source down still leaves the other to recommend from; only both down is an outage.
    private List<Candidate> fetchCandidates(String keywordQuery) {
        List<Candidate> output = new ArrayList<>();
        boolean blogs = readItems(blogUrl + "/blogs?size=20" + keywordQuery, "items", "BLOG", output);
        boolean recipes = readItems(recipeUrl + "/recipes?size=20" + keywordQuery, "content", "RECIPE", output);
        if (!blogs && !recipes) throw new AppException(ErrorCode.DOWNSTREAM_UNAVAILABLE);
        return output;
    }

    private boolean readItems(String url, String field, String type, List<Candidate> output) {
        try {
            JsonNode root = http.get().uri(url).retrieve().body(JsonNode.class);
            JsonNode items = root == null ? null : root.path("result").path(field);
            if (items != null && items.isArray()) {
                items.forEach(n -> {
                    if (n.path("id").canConvertToLong()) {
                        output.add(new Candidate(type, n.path("id").asLong(), n));
                    }
                });
            }
            return true;
        } catch (Exception e) {
            log.warn("Recommendation candidates unavailable from {}: {}", url, e.getMessage());
            return false;
        }
    }

    private String query(String value) {
        return value == null || value.isBlank()
                ? ""
                : "&keyword=" + java.net.URLEncoder.encode(value, java.nio.charset.StandardCharsets.UTF_8);
    }

    // Models often wrap the array in a sentence or a ```json fence; keep only the outermost [...].
    private String cleanJson(String raw) {
        if (raw == null) return "[]";
        int start = raw.indexOf('[');
        int end = raw.lastIndexOf(']');
        if (start >= 0 && end > start) {
            return raw.substring(start, end + 1);
        }
        if (start >= 0) {
            int lastBrace = raw.lastIndexOf('}');
            if (lastBrace > start) {
                return raw.substring(start, lastBrace + 1) + "]";
            }
        }
        return raw.trim();
    }

    private long elapsed(long start) {
        return (System.nanoTime() - start) / 1_000_000;
    }

    record Candidate(String type, long id, JsonNode node) {}
}
