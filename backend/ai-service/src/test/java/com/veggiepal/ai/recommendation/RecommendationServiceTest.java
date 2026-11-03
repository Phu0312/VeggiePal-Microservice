package com.veggiepal.ai.recommendation;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyDouble;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.contains;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.veggiepal.ai.common.AppException;
import com.veggiepal.ai.common.ErrorCode;
import com.veggiepal.ai.provider.LocalAiClient;
import com.veggiepal.ai.monitoring.UsageService;
import com.veggiepal.ai.mealplan.MealPlanValidator;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.web.client.RestClient;

class RecommendationServiceTest {

    private RestClient http;
    private RestClient.RequestHeadersUriSpec uriSpec;
    private RestClient.ResponseSpec responseSpec;
    private LocalAiClient ai;
    private ObjectMapper mapper;
    private UsageService usage;
    private RecommendationService service;

    @BeforeEach
    void setUp() {
        http = mock(RestClient.class);
        uriSpec = mock(RestClient.RequestHeadersUriSpec.class);
        responseSpec = mock(RestClient.ResponseSpec.class);
        ai = mock(LocalAiClient.class);
        mapper = new ObjectMapper();
        usage = mock(UsageService.class);

        when(http.get()).thenReturn(uriSpec);
        when(uriSpec.uri(anyString())).thenReturn(uriSpec);
        when(uriSpec.retrieve()).thenReturn(responseSpec);

        service = new RecommendationService(
                http,
                "http://blog-service",
                "http://recipe-service",
                ai,
                mapper,
                usage
        );
    }

    @Test
    void recommendReturnsEmptyListWhenNoCandidatesFound() throws Exception {
        JsonNode emptyBlog = mapper.readTree("{\"result\":{\"items\":[]}}");
        JsonNode emptyRecipe = mapper.readTree("{\"result\":{\"content\":[]}}");

        when(uriSpec.uri(contains("http://blog-service"))).thenReturn(uriSpec);
        when(uriSpec.uri(contains("http://recipe-service"))).thenReturn(uriSpec);
        when(responseSpec.body(JsonNode.class)).thenReturn(emptyBlog, emptyRecipe);

        List<RecommendationDtos.Recommendation> result = service.recommend(1L, "vegan salad", 5);

        assertNotNull(result);
        assertTrue(result.isEmpty());
        verifyNoInteractions(ai);
    }

    @Test
    void recipeCandidatesAreFilteredAgainstUserAllergiesBeforeInference() throws Exception {
        JsonNode blogs = mapper.readTree("{\"result\":{\"items\":[]}}");
        JsonNode recipes = mapper.readTree("{\"result\":{\"content\":[{\"id\":20,\"title\":\"Peanut dish\"}]}}");
        JsonNode allergies = mapper.readTree("{\"result\":[{\"code\":\"PEANUT\",\"name\":\"Peanut\"}]}");
        when(responseSpec.body(JsonNode.class)).thenReturn(blogs, recipes, allergies);
        when(uriSpec.header(anyString(), any(String[].class))).thenReturn(uriSpec);
        MealPlanValidator validator = mock(MealPlanValidator.class);
        when(validator.isVegan(any())).thenReturn(true);
        when(validator.isAllergySafe(any(), any())).thenReturn(false);
        var secured = new RecommendationService(http, "http://blog-service", "http://recipe-service",
                ai, mapper, usage, validator, "http://nutrition-service");

        assertTrue(secured.recommend(1L, "token", "peanut", 5).isEmpty());
        verifyNoInteractions(ai);
    }

    @Test
    void recommendSuccessfullyRanksAndReturnsCandidates() throws Exception {
        JsonNode blogData = mapper.readTree("{\"result\":{\"items\":[{\"id\":10,\"title\":\"Vegan Salad Guide\"}]}}");
        JsonNode recipeData = mapper.readTree("{\"result\":{\"content\":[{\"id\":20,\"title\":\"Avocado Salad\"}]}}");

        when(responseSpec.body(JsonNode.class)).thenReturn(blogData, recipeData);

        String aiOutput = "[{\"type\":\"BLOG\",\"id\":10,\"reason\":\"Great salad tips\"},{\"type\":\"RECIPE\",\"id\":20,\"reason\":\"Fresh salad recipe\"}]";
        when(ai.complete(anyList(), anyDouble(), anyInt()))
                .thenReturn(new LocalAiClient.AiResult(aiOutput, 100, 50));

        List<RecommendationDtos.Recommendation> result = service.recommend(1L, "salad", 5);

        assertEquals(2, result.size());
        assertEquals("BLOG", result.get(0).type());
        assertEquals(10L, result.get(0).id());
        assertEquals("Great salad tips", result.get(0).reason());
        assertEquals("RECIPE", result.get(1).type());
        assertEquals(20L, result.get(1).id());
        assertEquals("Fresh salad recipe", result.get(1).reason());
        verify(usage).reserveLocalTestRequest("user:1", "RECOMMENDATION");
        verify(usage).checkTextBudget("user:1");
    }

    @Test
    void recommendReturnsContentThatSpringMvcWritesAsJson() throws Exception {
        JsonNode blogData = mapper.readTree("{\"result\":{\"items\":[{\"id\":10,\"title\":\"Vegan Salad Guide\"}]}}");
        JsonNode recipeData = mapper.readTree("{\"result\":{\"content\":[]}}");
        when(responseSpec.body(JsonNode.class)).thenReturn(blogData, recipeData);
        when(ai.complete(anyList(), anyDouble(), anyInt()))
                .thenReturn(new LocalAiClient.AiResult("[{\"type\":\"BLOG\",\"id\":10,\"reason\":\"tips\"}]", 100, 50));

        // Spring MVC writes responses with Jackson 3, not this service's Jackson 2 mapper.
        var json = tools.jackson.databind.json.JsonMapper.builder().build();
        var written = json.readTree(json.writeValueAsString(service.recommend(1L, "salad", 5)));

        assertEquals("Vegan Salad Guide", written.path(0).path("content").path("title").asString());
    }

    @Test
    void recommendThrowsInvalidAiResponseWhenLocalAiReturnsNonArray() throws Exception {
        JsonNode blogData = mapper.readTree("{\"result\":{\"items\":[{\"id\":10,\"title\":\"Vegan Salad Guide\"}]}}");
        JsonNode recipeData = mapper.readTree("{\"result\":{\"content\":[]}}");

        when(responseSpec.body(JsonNode.class)).thenReturn(blogData, recipeData);

        String aiOutput = "{\"message\":\"not an array\"}";
        when(ai.complete(anyList(), anyDouble(), anyInt()))
                .thenReturn(new LocalAiClient.AiResult(aiOutput, 100, 50));

        AppException ex = assertThrows(AppException.class, () -> service.recommend(1L, "salad", 5));
        assertEquals(ErrorCode.INVALID_AI_RESPONSE, ex.getErrorCode());
    }

    @Test
    void recommendStillUsesRecipesWhenBlogServiceIsDown() throws Exception {
        JsonNode recipeData = mapper.readTree("{\"result\":{\"content\":[{\"id\":20,\"title\":\"Avocado Salad\"}]}}");
        when(responseSpec.body(JsonNode.class)).thenThrow(new RuntimeException("Connection refused")).thenReturn(recipeData);
        when(ai.complete(anyList(), anyDouble(), anyInt()))
                .thenReturn(new LocalAiClient.AiResult("[{\"type\":\"RECIPE\",\"id\":20,\"reason\":\"fresh\"}]", 100, 50));

        List<RecommendationDtos.Recommendation> result = service.recommend(1L, null, 5);

        assertEquals(1, result.size());
        assertEquals(20L, result.get(0).id());
    }

    @Test
    void recommendFallsBackToLatestItemsWhenKeywordMatchesNothing() throws Exception {
        JsonNode emptyBlog = mapper.readTree("{\"result\":{\"items\":[]}}");
        JsonNode emptyRecipe = mapper.readTree("{\"result\":{\"content\":[]}}");
        JsonNode latestBlogs = mapper.readTree("{\"result\":{\"items\":[{\"id\":10,\"title\":\"Rau củ ít calo\"}]}}");
        when(responseSpec.body(JsonNode.class)).thenReturn(emptyBlog, emptyRecipe, latestBlogs, emptyRecipe);
        when(ai.complete(anyList(), anyDouble(), anyInt()))
                .thenReturn(new LocalAiClient.AiResult("[{\"type\":\"BLOG\",\"id\":10,\"reason\":\"ít calo\"}]", 100, 50));

        List<RecommendationDtos.Recommendation> result = service.recommend(1L, "giảm cân", 5);

        assertEquals(1, result.size());
        assertEquals(10L, result.get(0).id());
        verify(uriSpec).uri("http://blog-service/blogs?size=20");
    }

    @Test
    void recommendReadsJsonArrayWrappedInProse() throws Exception {
        JsonNode blogData = mapper.readTree("{\"result\":{\"items\":[{\"id\":10,\"title\":\"Vegan Salad Guide\"}]}}");
        JsonNode recipeData = mapper.readTree("{\"result\":{\"content\":[]}}");
        when(responseSpec.body(JsonNode.class)).thenReturn(blogData, recipeData);
        String aiOutput = "Dưới đây là gợi ý cho bạn:\n```json\n[{\"type\":\"BLOG\",\"id\":10,\"reason\":\"tips\"}]\n```";
        when(ai.complete(anyList(), anyDouble(), anyInt()))
                .thenReturn(new LocalAiClient.AiResult(aiOutput, 100, 50));

        List<RecommendationDtos.Recommendation> result = service.recommend(1L, "salad", 5);

        assertEquals(1, result.size());
        assertEquals("tips", result.get(0).reason());
    }

    @Test
    void recommendThrowsDownstreamUnavailableWhenRestClientFails() {
        when(responseSpec.body(JsonNode.class)).thenThrow(new RuntimeException("Connection refused"));

        AppException ex = assertThrows(AppException.class, () -> service.recommend(1L, "salad", 5));
        assertEquals(ErrorCode.DOWNSTREAM_UNAVAILABLE, ex.getErrorCode());
    }

    @Test
    void blankModelReasonGeneratesDeterministicFactualVietnameseExplanation() throws Exception {
        JsonNode blogData = mapper.readTree("{\"result\":{\"items\":[{\"id\":10,\"title\":\"Cách ủ tempeh tại nhà\"}]}}");
        JsonNode recipeData = mapper.readTree("{\"result\":{\"content\":[{\"id\":108,\"title\":\"Bún cà ri chay đậu hũ\"}]}}");
        when(responseSpec.body(JsonNode.class)).thenReturn(blogData, recipeData);

        String aiOutput = "[{\"type\":\"RECIPE\",\"id\":108,\"reason\":\"\"},{\"type\":\"BLOG\",\"id\":10,\"reason\":\"   \"}]";
        when(ai.complete(anyList(), anyDouble(), anyInt()))
                .thenReturn(new LocalAiClient.AiResult(aiOutput, 120, 45));

        List<RecommendationDtos.Recommendation> result = service.recommend(1L, "món kho chay đậm đà", 3);

        assertEquals(2, result.size());
        assertFalse(result.get(0).reason().isBlank());
        assertTrue(result.get(0).reason().contains("Bún cà ri chay đậu hũ"));
        assertTrue(result.get(0).reason().contains("món kho chay đậm đà"));
        assertFalse(result.get(1).reason().isBlank());
        assertTrue(result.get(1).reason().contains("Cách ủ tempeh tại nhà"));
    }

    @Test
    void limitClampingDeduplicationAndFabricatedIdFilteringWorkAcrossBoundaryLimits() throws Exception {
        StringBuilder recipesJson = new StringBuilder("{\"result\":{\"content\":[");
        for (int i = 1; i <= 12; i++) {
            if (i > 1) recipesJson.append(",");
            recipesJson.append("{\"id\":").append(i).append(",\"title\":\"Món chay ").append(i).append("\"}");
        }
        recipesJson.append("]}}");
        JsonNode emptyBlog = mapper.readTree("{\"result\":{\"items\":[]}}");
        JsonNode recipeData = mapper.readTree(recipesJson.toString());

        when(responseSpec.body(JsonNode.class)).thenReturn(emptyBlog, recipeData, emptyBlog, recipeData);

        // Model returns duplicate id=1, fabricated id=999, and 11 valid items
        StringBuilder aiArray = new StringBuilder("[{\"type\":\"RECIPE\",\"id\":999,\"reason\":\"fake\"},{\"type\":\"RECIPE\",\"id\":1,\"reason\":\"dup\"},");
        for (int i = 1; i <= 12; i++) {
            if (i > 1) aiArray.append(",");
            aiArray.append("{\"type\":\"RECIPE\",\"id\":").append(i).append(",\"reason\":\"\"}");
        }
        aiArray.append("]");
        when(ai.complete(anyList(), anyDouble(), anyInt()))
                .thenReturn(new LocalAiClient.AiResult(aiArray.toString(), 200, 100));

        // limit = 0 clamps to 1
        List<RecommendationDtos.Recommendation> limitZeroResult = service.recommend(1L, "", 0);
        assertEquals(1, limitZeroResult.size());
        assertEquals(1L, limitZeroResult.get(0).id());

        // limit = 15 clamps to 10, deduplicates id=1, ignores fabricated id=999, and populates fallback reasons
        List<RecommendationDtos.Recommendation> limitMaxResult = service.recommend(1L, null, 15);
        assertEquals(10, limitMaxResult.size());
        assertTrue(limitMaxResult.stream().noneMatch(r -> r.id() == 999L));
        assertTrue(limitMaxResult.stream().allMatch(r -> r.reason() != null && !r.reason().isBlank()));
    }

    @Test
    void placeholderReasonFromModelIsRejectedAndReplacedByMeaningfulGroundedReason() throws Exception {
        JsonNode emptyBlog = mapper.readTree("{\"result\":{\"items\":[]}}");
        JsonNode recipeData = mapper.readTree("{\"result\":{\"content\":[{\"id\":102,\"title\":\"Cơm gạo lứt chiên hạt sen\"}]}}");
        when(responseSpec.body(JsonNode.class)).thenReturn(emptyBlog, recipeData);

        // Model returns the prompt template placeholder literally
        String aiOutput = "[{\"type\":\"RECIPE\",\"id\":102,\"reason\":\"Lý do gợi ý ngắn gọn bằng tiếng Việt\"}]";
        when(ai.complete(anyList(), anyDouble(), anyInt()))
                .thenReturn(new LocalAiClient.AiResult(aiOutput, 100, 30));

        List<RecommendationDtos.Recommendation> result = service.recommend(1L, "cơm chay thanh đạm", 1);

        assertEquals(1, result.size());
        assertEquals(102L, result.get(0).id());
        String reason = result.get(0).reason();
        assertFalse(reason.contains("Lý do gợi ý ngắn gọn"), "Placeholder must not be passed to user");
        assertTrue(reason.contains("Cơm gạo lứt chiên hạt sen"), "Fallback reason must be grounded with item title");
        assertTrue(reason.contains("cơm chay thanh đạm"), "Fallback reason must reference user interest");
    }
}
