package com.veggiepal.ai.chat;

import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.veggiepal.ai.mealplan.AllergenDetector;

/**
 * Resolves user food allergies and dietary exclusions from conversational queries,
 * multi-turn chat history, and stored profile allergies in nutrition-service.
 * Distinguishes explicit personal restrictions from purely educational discussions.
 */
@Component
public class DietaryRestrictionResolver {

    private static final Logger log = LoggerFactory.getLogger(DietaryRestrictionResolver.class);

    public record AllergenDefinition(
            String code,
            String vietnameseName,
            List<String> primaryAliases,
            List<String> derivativeKeywords) {}

    private static final Map<String, AllergenDefinition> DEFINITIONS = new LinkedHashMap<>();

    static {
        register("SOY", "đậu nành",
                List.of("dau nanh", "dau tuong", "soy", "soya", "soybean", "dau hu", "dau phu", "tau hu", "tofu", "tempeh"),
                List.of("dau nanh", "dau tuong", "dau hu", "dau phu", "tau hu", "sua dau nanh", "tau hu ky", "tau hu ki",
                        "vang dau", "tempeh", "tofu", "chao", "natto", "tuong ban", "nuoc tuong", "xi dau", "miso", "edamame"));

        register("PEANUT", "đậu phộng",
                List.of("dau phong", "lac", "peanut", "groundnut", "bo dau phong", "bo lac"),
                List.of("dau phong", "lac", "bo dau phong", "bo lac", "dau dau phong", "dau lac", "keo lac", "keo dau phong"));

        register("SESAME", "mè",
                List.of("me", "vung", "sesame", "dau me", "dau vung"),
                List.of("me", "vung", "dau me", "dau vung", "tahini", "sot me", "xot me", "muoi me", "muoi vung"));

        register("GLUTEN", "gluten",
                List.of("gluten", "lua mi", "lua mach", "bot mi", "celiac", "seitan", "mi can"),
                List.of("gluten", "lua mi", "lua mach", "bot mi", "celiac", "seitan", "mi can", "can mi", "banh mi", "mi soi", "hoanh thanh", "mi an lien"));

        register("CASHEW", "hạt điều",
                List.of("hat dieu", "dieu", "cashew"),
                List.of("hat dieu", "dieu", "bo hat dieu", "sua hat dieu"));

        register("TREE_NUT", "các loại hạt cây",
                List.of("hat cay", "tree nut", "hanh nhan", "oc cho", "mac ca", "hat de", "hat phi", "ho dao", "hat thong", "hat pecan", "almond", "walnut"),
                List.of("hat cay", "tree nut", "hanh nhan", "oc cho", "mac ca", "hat de", "hat phi", "ho dao", "hat thong", "hat pecan", "almond", "walnut",
                        "sua hanh nhan", "bo hanh nhan", "hat dieu", "bo hat dieu", "sua hat dieu"));

        register("MUSHROOM", "nấm",
                List.of("nam", "mushroom", "moc nhi", "nam tai meo"),
                List.of("nam", "mushroom", "nam rom", "nam huong", "nam dui ga", "nam bao ngu", "nam kim cham",
                        "moc nhi", "nam tai meo", "nam dong co", "nam linh chi", "nam tuyet", "nam mo"));

        register("CORN", "bắp (ngô)",
                List.of("bap", "ngo", "corn"),
                List.of("bap", "ngo", "bap ngot", "ngo ngot", "tinh bot bap", "bot bap", "bot ngo"));

        register("TOMATO", "cà chua",
                List.of("ca chua", "tomato"),
                List.of("ca chua", "sot ca chua", "xot ca chua", "ca chua bi"));

        register("EGGPLANT", "cà tím",
                List.of("ca tim", "ca phao"),
                List.of("ca tim", "ca phao"));

        register("CELERY", "cần tây",
                List.of("can tay", "celery"),
                List.of("can tay", "celery"));

        register("CHILI", "ớt",
                List.of("ot", "chili", "hot pepper"),
                List.of("ot", "ot chuong", "ot bot", "tuong ot", "sa te"));
    }

    private static void register(String code, String vietnameseName, List<String> primaryAliases, List<String> derivativeKeywords) {
        DEFINITIONS.put(code, new AllergenDefinition(code, vietnameseName, primaryAliases, derivativeKeywords));
    }

    public static String vietnameseNameFor(String code) {
        if (code == null) return null;
        AllergenDefinition def = DEFINITIONS.get(code.toUpperCase(Locale.ROOT));
        return def != null ? def.vietnameseName() : null;
    }

    /**
     * Merges user profile allergies from nutrition-service with explicit dietary restrictions
     * or exclusions declared in request preferences (e.g. "Dị ứng đậu nành", "Không đậu hũ").
     */
    public ArrayNode mergeAllergies(JsonNode profileAllergies, List<String> preferences, ObjectMapper mapper) {
        ArrayNode merged = mapper.createArrayNode();
        Set<String> presentCodes = new HashSet<>();
        Set<String> presentTerms = new HashSet<>();

        if (profileAllergies != null && profileAllergies.isArray()) {
            for (JsonNode item : profileAllergies) {
                merged.add(item.deepCopy());
                String code = item.path("code").asText("").trim().toUpperCase(Locale.ROOT);
                if (!code.isBlank()) presentCodes.add(code);
                String name = item.path("name").asText("").trim().toLowerCase(Locale.ROOT);
                if (!name.isBlank()) presentTerms.add(name);
            }
        }

        if (preferences != null && !preferences.isEmpty()) {
            String combinedText = String.join(". ", preferences);
            DietaryRestrictions restrictions = resolveSingleQuery(combinedText);

            for (String code : restrictions.allergenCodes()) {
                String upper = code.toUpperCase(Locale.ROOT);
                if (presentCodes.add(upper)) {
                    ObjectNode item = mapper.createObjectNode();
                    item.put("code", upper);
                    String vnName = vietnameseNameFor(upper);
                    item.put("name", vnName != null ? vnName : upper);
                    merged.add(item);
                }
            }

            for (String kw : restrictions.excludedKeywords()) {
                String lower = kw.toLowerCase(Locale.ROOT).trim();
                if (!lower.isBlank() && presentTerms.add(lower)) {
                    ObjectNode item = mapper.createObjectNode();
                    item.put("code", "EXCLUSION");
                    item.put("name", lower);
                    merged.add(item);
                }
            }
        }

        return merged;
    }

    // Pattern to detect explicit allergy or dietary exclusion declaration
    private static final Pattern EXCLUSION_TRIGGER = Pattern.compile(
            "\\b(di ung|dị ứng|khong an duoc|không ăn được|khong an|không ăn|khong dung duoc|không dùng được|khong dung|không dùng"
                    + "|tranh|tránh|kieng|kiêng|loai bo|loại bỏ|loai tru|loại trừ|khong chua|không chứa|khong co|không có"
                    + "|khong kem|không kèm|khong bao gom|không bao gồm|noi khong voi|nói không với|bi celiac|bị celiac)\\b",
            Pattern.CASE_INSENSITIVE | Pattern.UNICODE_CASE);

    // Negative triggers for purely educational / hypothetical inquiries
    private static final Pattern HYPOTHETICAL_TRIGGER = Pattern.compile(
            "\\b(vi sao|vì sao|tai sao|tại sao|nguyen nhan|nguyên nhân|co che|cơ chế|la gi|là gì|nhu the nao|như thế nào"
                    + "|co nguy hiem khong|có nguy hiểm không|co phai la|có phải là|chua di ung|chữa dị ứng|xet nghiem|xét nghiệm)\\b",
            Pattern.CASE_INSENSITIVE | Pattern.UNICODE_CASE);

    // Personal / actionable indicators that override a hypothetical appearance
    private static final Pattern PERSONAL_INTENT = Pattern.compile(
            "\\b(toi|tôi|minh|mình|em|cho toi|cho tôi|giup toi|giúp tôi|goi y|gợi ý|thuc don|thực đơn|mon|món|bua|bữa"
                    + "|an gi|ăn gì|nau gi|nấu gì|thay the|thay thế|phu hop|phù hợp)\\b",
            Pattern.CASE_INSENSITIVE | Pattern.UNICODE_CASE);

    // Revocation triggers (e.g. "Tôi không còn dị ứng đậu nành nữa", "Ăn được đậu phộng rồi")
    private static final Pattern REVOCATION_TRIGGER = Pattern.compile(
            "\\b(khong con di ung|không còn dị ứng|het di ung|hết dị ứng|an duoc .* roi|ăn được .* rồi|khong can kieng|không cần kiêng)\\b",
            Pattern.CASE_INSENSITIVE | Pattern.UNICODE_CASE);

    private final RestClient http;
    private final String nutritionUrl;

    @Autowired
    public DietaryRestrictionResolver(
            @Qualifier("serviceRestClient") RestClient http,
            @Value("${services.nutrition.base-url}") String nutritionUrl) {
        this.http = http;
        this.nutritionUrl = nutritionUrl;
    }

    // Default constructor for testing without Spring context
    public DietaryRestrictionResolver() {
        this(null, null);
    }

    /**
     * Resolves dietary restrictions combining current user message, multi-turn conversation history,
     * and saved profile allergies in nutrition-service if JWT is present.
     */
    public DietaryRestrictions resolve(String currentMessage, List<String> historyUserMessages, String jwt) {
        Set<String> activeAllergenCodes = new LinkedHashSet<>();
        Set<String> activeSpecificKeywords = new LinkedHashSet<>();

        // 1. Fetch saved profile allergies from nutrition-service if authenticated
        if (jwt != null && !jwt.isBlank() && http != null && nutritionUrl != null && !nutritionUrl.isBlank()) {
            try {
                JsonNode response = http.get().uri(nutritionUrl + "/nutrition/me/allergies")
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + jwt)
                        .retrieve().body(JsonNode.class);
                JsonNode items = response == null ? null : response.path("result");
                if (items != null && items.isArray()) {
                    items.forEach(node -> {
                        String code = node.path("code").asText("").trim().toUpperCase(Locale.ROOT);
                        if (!code.isBlank()) {
                            activeAllergenCodes.add(code);
                        }
                    });
                }
            } catch (Exception ex) {
                log.warn("Unable to fetch user allergies from nutrition-service: {}", ex.getMessage());
            }
        }

        // 2. Scan conversation history user messages chronologically
        if (historyUserMessages != null) {
            for (String histMsg : historyUserMessages) {
                processMessageIntoRestrictions(histMsg, activeAllergenCodes, activeSpecificKeywords);
            }
        }

        // 3. Scan the current user message
        processMessageIntoRestrictions(currentMessage, activeAllergenCodes, activeSpecificKeywords);

        return buildDietaryRestrictions(activeAllergenCodes, activeSpecificKeywords);
    }

    /**
     * Convenience method for a single standalone query (e.g. guest chat or unit test).
     */
    public DietaryRestrictions resolveSingleQuery(String query) {
        Set<String> codes = new LinkedHashSet<>();
        Set<String> keywords = new LinkedHashSet<>();
        processMessageIntoRestrictions(query, codes, keywords);
        return buildDietaryRestrictions(codes, keywords);
    }

    private void processMessageIntoRestrictions(String message, Set<String> codes, Set<String> specificKeywords) {
        if (message == null || message.isBlank()) {
            return;
        }

        String norm = AllergenDetector.normalizeText(message);

        // Check for hypothetical question without personal declaration
        if (HYPOTHETICAL_TRIGGER.matcher(norm).find() && !PERSONAL_INTENT.matcher(norm).find()) {
            return;
        }

        // Check for revocation (e.g. "không còn dị ứng đậu nành")
        if (REVOCATION_TRIGGER.matcher(norm).find()) {
            for (AllergenDefinition def : DEFINITIONS.values()) {
                for (String alias : def.primaryAliases()) {
                    if (AllergenDetector.matchesWord(norm, alias)) {
                        codes.remove(def.code());
                        specificKeywords.remove(alias);
                        break;
                    }
                }
            }
            return;
        }

        // Check for exclusion triggers (e.g. "dị ứng đậu nành", "không ăn đậu phộng", "tránh mè")
        boolean hasExclusionTrigger = EXCLUSION_TRIGGER.matcher(norm).find();

        // Also check short patterns like "không nấm", "không đậu", "không gluten"
        boolean hasShortNegation = norm.contains("khong ") || norm.contains("tranh ") || norm.contains("kieng ");

        if (!hasExclusionTrigger && !hasShortNegation) {
            return;
        }

        // Match against known allergen definitions
        for (AllergenDefinition def : DEFINITIONS.values()) {
            for (String alias : def.primaryAliases()) {
                if (isTargetOfExclusion(norm, alias)) {
                    codes.add(def.code());
                    break;
                }
            }
        }

        // Also check individual ingredient terms from AllergenDetector if not mapped to top definitions
        for (String alias : List.of("chao", "miso", "tau hu ky", "tau hu ki", "sua dau nanh", "tempeh", "dau hu", "dau phu")) {
            if (isTargetOfExclusion(norm, alias)) {
                codes.add("SOY");
                specificKeywords.add(alias);
            }
        }
    }

    private boolean isTargetOfExclusion(String normalizedText, String term) {
        if (!AllergenDetector.matchesWord(normalizedText, term)) {
            return false;
        }

        // Find position of the term
        int idx = (" " + normalizedText + " ").indexOf(" " + term + " ");
        if (idx < 0) {
            return false;
        }

        // Check nearby context (window before or after the term)
        int start = Math.max(0, idx - 45);
        int end = Math.min(normalizedText.length(), idx + term.length() + 35);
        String context = normalizedText.substring(start, end);

        return EXCLUSION_TRIGGER.matcher(context).find()
                || context.contains("khong " + term)
                || context.contains("tranh " + term)
                || context.contains("kieng " + term)
                || context.contains("khong an " + term)
                || context.contains("khong dung " + term)
                || context.contains("khong co " + term)
                || context.contains("khong chua " + term);
    }

    private DietaryRestrictions buildDietaryRestrictions(Set<String> activeCodes, Set<String> activeSpecificKeywords) {
        Set<String> allExcludedKeywords = new LinkedHashSet<>(activeSpecificKeywords);
        List<String> friendlyDescriptions = new ArrayList<>();

        for (String code : activeCodes) {
            AllergenDefinition def = DEFINITIONS.get(code);
            if (def != null) {
                allExcludedKeywords.addAll(def.derivativeKeywords());
                friendlyDescriptions.add(def.vietnameseName());
            } else {
                allExcludedKeywords.add(code.toLowerCase(Locale.ROOT));
                friendlyDescriptions.add(code);
            }
        }

        return new DietaryRestrictions(activeCodes, allExcludedKeywords, friendlyDescriptions);
    }
}
