package com.veggiepal.ai.chat;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

import java.util.List;
import java.util.Set;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.web.client.RestClient;
import com.fasterxml.jackson.databind.ObjectMapper;

class DietaryRestrictionResolverTest {

    private DietaryRestrictionResolver resolver;

    @BeforeEach
    void setUp() {
        resolver = new DietaryRestrictionResolver();
    }

    @Test
    void extractsSoyAllergyFromExplicitAccentedVietnamese() {
        String msg = "Tôi bị dị ứng đậu nành, hãy gợi ý 3 món thuần chay giàu protein không chứa đậu nành.";
        DietaryRestrictions restrictions = resolver.resolveSingleQuery(msg);

        assertFalse(restrictions.isEmpty());
        assertTrue(restrictions.allergenCodes().contains("SOY"));
        assertTrue(restrictions.violates("đậu hũ"));
        assertTrue(restrictions.violates("đậu phụ"));
        assertTrue(restrictions.violates("sữa đậu nành"));
        assertTrue(restrictions.violates("tempeh"));
        assertTrue(restrictions.violates("tàu hũ ky"));
        assertTrue(restrictions.violates("chao"));
        assertTrue(restrictions.violates("miso"));
        assertFalse(restrictions.violates("đậu gà"));
        assertFalse(restrictions.violates("đậu lăng đỏ"));
        assertFalse(restrictions.violates("gạo lứt"));
    }

    @Test
    void extractsSoyAndPeanutAndSesameAllergiesSimultaneously() {
        String msg = "Tôi dị ứng đậu nành, kiêng đậu phộng và mè (vừng). Có món gì giàu đạm không?";
        DietaryRestrictions restrictions = resolver.resolveSingleQuery(msg);

        assertEquals(Set.of("SOY", "PEANUT", "SESAME"), restrictions.allergenCodes());
        assertTrue(restrictions.violates("đậu hũ"));
        assertTrue(restrictions.violates("bơ đậu phộng"));
        assertTrue(restrictions.violates("dầu mè"));
        assertTrue(restrictions.violates("muối vừng"));
        assertFalse(restrictions.violates("hạt bí xanh"));
        assertFalse(restrictions.violates("hạt sen"));
    }

    @Test
    void extractsGlutenAndCeliacRestrictions() {
        String msg = "Tôi bị bệnh Celiac, cần tránh gluten và lúa mì. Ăn chay món gì?";
        DietaryRestrictions restrictions = resolver.resolveSingleQuery(msg);

        assertTrue(restrictions.allergenCodes().contains("GLUTEN"));
        assertTrue(restrictions.violates("mì căn"));
        assertTrue(restrictions.violates("seitan"));
        assertTrue(restrictions.violates("bột mì"));
        assertTrue(restrictions.violates("bánh mì"));
        assertFalse(restrictions.violates("bún gạo lứt"));
    }

    @Test
    void extractsTreeNutAndCashewRestrictions() {
        String msg = "Em bị dị ứng hạt điều và các loại hạt cây, xin tư vấn.";
        DietaryRestrictions restrictions = resolver.resolveSingleQuery(msg);

        assertTrue(restrictions.allergenCodes().contains("CASHEW"));
        assertTrue(restrictions.allergenCodes().contains("TREE_NUT"));
        assertTrue(restrictions.violates("hạt điều"));
        assertTrue(restrictions.violates("bơ hạt điều"));
        assertTrue(restrictions.violates("hạnh nhân"));
        assertTrue(restrictions.violates("quả óc chó"));
    }

    @Test
    void extractsMushroomRestrictions() {
        String msg = "Mình không ăn được nấm (dị ứng nấm rơm, nấm hương).";
        DietaryRestrictions restrictions = resolver.resolveSingleQuery(msg);

        assertTrue(restrictions.allergenCodes().contains("MUSHROOM"));
        assertTrue(restrictions.violates("nấm rơm"));
        assertTrue(restrictions.violates("nấm đùi gà"));
        assertTrue(restrictions.violates("nấm đông cô"));
        assertFalse(restrictions.violates("cà rốt"));
    }

    @Test
    void extractsRestrictionsFromUnaccentedVietnamese() {
        String msg = "Toi bi di ung dau nanh va me, hay goi y mon chay khong dau nanh";
        DietaryRestrictions restrictions = resolver.resolveSingleQuery(msg);

        assertTrue(restrictions.allergenCodes().contains("SOY"));
        assertTrue(restrictions.allergenCodes().contains("SESAME"));
        assertTrue(restrictions.violates("dau hu"));
        assertTrue(restrictions.violates("dau me"));
    }

    @Test
    void ignoresHypotheticalAndEducationalQuestionsWithoutPersonalExclusion() {
        String q1 = "Vì sao người ăn chay thường bị dị ứng đậu nành?";
        String q2 = "Cơ chế dị ứng đậu phộng là gì và có nguy hiểm không?";
        String q3 = "Xét nghiệm dị ứng gluten ở đâu?";

        assertTrue(resolver.resolveSingleQuery(q1).isEmpty());
        assertTrue(resolver.resolveSingleQuery(q2).isEmpty());
        assertTrue(resolver.resolveSingleQuery(q3).isEmpty());
    }

    @Test
    void resolvesAllergiesFromMultiTurnHistory() {
        List<String> history = List.of(
                "Chào bạn, tôi là người mới ăn chay.",
                "Tôi bị dị ứng đậu nành nặng từ nhỏ."
        );
        String currentQuery = "Hôm nay hãy gợi ý cho tôi 3 món ăn giàu đạm.";

        DietaryRestrictions restrictions = resolver.resolve(currentQuery, history, null);

        assertTrue(restrictions.allergenCodes().contains("SOY"),
                "Should preserve soy allergy declared in previous conversational turn");
        assertTrue(restrictions.violates("đậu hũ"));
    }

    @Test
    void handlesAllergyRevocationInConversation() {
        List<String> history = List.of(
                "Tôi bị dị ứng đậu phộng.",
                "Bác sĩ vừa xét nghiệm lại, tôi không còn dị ứng đậu phộng nữa."
        );
        String currentQuery = "Gợi ý món ăn có đậu phộng giúp tôi.";

        DietaryRestrictions restrictions = resolver.resolve(currentQuery, history, null);

        assertFalse(restrictions.allergenCodes().contains("PEANUT"),
                "Peanut allergy should be revoked after explicit correction");
    }

    @Test
    void fetchesSavedProfileAllergiesWhenJwtProvided() throws Exception {
        RestClient http = mock(RestClient.class);
        @SuppressWarnings("rawtypes")
        RestClient.RequestHeadersUriSpec uriSpec = mock(RestClient.RequestHeadersUriSpec.class);
        @SuppressWarnings("rawtypes")
        RestClient.RequestHeadersSpec headersSpec = mock(RestClient.RequestHeadersSpec.class);
        RestClient.ResponseSpec responseSpec = mock(RestClient.ResponseSpec.class);

        when(http.get()).thenReturn(uriSpec);
        when(uriSpec.uri("http://localhost:8082/nutrition/me/allergies")).thenReturn(headersSpec);
        when(headersSpec.header(eq("Authorization"), eq("Bearer sample-jwt"))).thenReturn(headersSpec);
        when(headersSpec.retrieve()).thenReturn(responseSpec);

        String json = """
                {
                  "code": 200,
                  "result": [
                    {"code": "SOY", "name": "Đậu nành"},
                    {"code": "PEANUT", "name": "Đậu phộng"}
                  ]
                }
                """;
        ObjectMapper mapper = new ObjectMapper();
        var jsonNode = mapper.readTree(json);
        when(responseSpec.body(com.fasterxml.jackson.databind.JsonNode.class)).thenReturn(jsonNode);

        DietaryRestrictionResolver authResolver = new DietaryRestrictionResolver(http, "http://localhost:8082");
        DietaryRestrictions restrictions = authResolver.resolve("Gợi ý cho tôi bữa tối", List.of(), "sample-jwt");

        assertTrue(restrictions.allergenCodes().contains("SOY"));
        assertTrue(restrictions.allergenCodes().contains("PEANUT"));
        assertTrue(restrictions.violates("đậu phụ"));
        assertTrue(restrictions.violates("kẹo lạc"));
    }
}
