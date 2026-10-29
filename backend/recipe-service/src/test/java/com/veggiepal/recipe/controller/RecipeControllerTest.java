package com.veggiepal.recipe.controller;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.List;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.RequestPostProcessor;

import com.veggiepal.recipe.configuration.JwtConfig;
import com.veggiepal.recipe.configuration.SecurityConfig;
import com.veggiepal.recipe.configuration.SecurityExceptionHandler;
import com.veggiepal.recipe.dto.response.ImageUploadResponse;
import com.veggiepal.recipe.dto.response.PageResponse;
import com.veggiepal.recipe.dto.response.RecipeLikeResponse;
import com.veggiepal.recipe.dto.response.RecipeResponse;
import com.veggiepal.recipe.enums.RecipeStatus;
import com.veggiepal.recipe.exception.AppException;
import com.veggiepal.recipe.exception.ErrorCode;
import com.veggiepal.recipe.service.RecipeService;

@WebMvcTest(RecipeController.class)
@Import({SecurityConfig.class, JwtConfig.class, SecurityExceptionHandler.class})
class RecipeControllerTest {

    static final Long USER_ID = 100L;

    @Autowired
    MockMvc mockMvc;

    @MockitoBean
    RecipeService recipeService;

    static RequestPostProcessor member() {
        return jwt().jwt(token -> token.claim("userId", USER_ID).claim("role", "USER"));
    }

    static RequestPostProcessor admin() {
        return jwt().jwt(token -> token.claim("userId", 1L).claim("role", "ADMIN"));
    }

    @Test
    void getRecipe_ownerCanReadOwnDraft() throws Exception {
        RecipeResponse response = RecipeResponse.builder().id(10L).status(RecipeStatus.DRAFT).build();
        when(recipeService.getRecipe(10L, USER_ID, false)).thenReturn(response);

        mockMvc.perform(get("/recipes/10").with(member()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.id").value(10))
                .andExpect(jsonPath("$.result.status").value("DRAFT"));
    }

    @Test
    void getRecipe_adminCanReadAnyDraft() throws Exception {
        RecipeResponse response = RecipeResponse.builder().id(10L).status(RecipeStatus.DRAFT).build();
        when(recipeService.getRecipe(10L, 1L, true)).thenReturn(response);

        mockMvc.perform(get("/recipes/10").with(admin()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.id").value(10))
                .andExpect(jsonPath("$.result.status").value("DRAFT"));
    }

    @Test
    void getRecipe_guestIsHiddenFromDraft() throws Exception {
        when(recipeService.getRecipe(10L, null, false))
                .thenThrow(new AppException(ErrorCode.RECIPE_NOT_EXISTED));

        mockMvc.perform(get("/recipes/10"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value(4100));
    }

    @Test
    void getRecipe_invalidTokenDoesNotCause401OnPublicEndpoint() throws Exception {
        RecipeResponse response = RecipeResponse.builder().id(10L).status(RecipeStatus.PUBLISHED).build();
        // Since token is invalid, resolver strips it so requesterId is null, but request succeeds as guest
        when(recipeService.getRecipe(10L, null, false)).thenReturn(response);

        mockMvc.perform(get("/recipes/10")
                        .header(HttpHeaders.AUTHORIZATION, "Bearer invalid.malformed.token"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.id").value(10));
    }

    @Test
    void getPopularRecipes_isPublicWithoutJwt() throws Exception {
        PageResponse<RecipeResponse> page = PageResponse.<RecipeResponse>builder()
                .content(List.of(RecipeResponse.builder().id(7L).title("Phở chay").likeCount(42).build()))
                .page(0)
                .size(10)
                .totalElements(1)
                .totalPages(1)
                .first(true)
                .last(true)
                .build();
        when(recipeService.getPopularRecipes(0, 10)).thenReturn(page);

        mockMvc.perform(get("/recipes/popular"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.items[0].id").value(7))
                .andExpect(jsonPath("$.result.items[0].likeCount").value(42));
    }

    @Test
    void uploadRecipeImage_returnsUpdatedRecipe() throws Exception {
        MockMultipartFile file = new MockMultipartFile("file", "photo.png", "image/png", new byte[]{1, 2, 3});
        when(recipeService.uploadRecipeImage(eq(10L), eq(USER_ID), eq(false), any()))
                .thenReturn(RecipeResponse.builder().id(10L).imageUrl("https://cdn.example.com/10.png").build());

        mockMvc.perform(multipart("/recipes/10/image").file(file).with(member()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.imageUrl").value("https://cdn.example.com/10.png"));
    }

    @Test
    void uploadStandaloneImage_returnsUploadedUrl() throws Exception {
        MockMultipartFile file = new MockMultipartFile("file", "photo.png", "image/png", new byte[]{1, 2, 3});
        when(recipeService.uploadStandaloneImage(eq(USER_ID), any()))
                .thenReturn(ImageUploadResponse.builder().imageUrl("https://cdn.example.com/raw.png").build());

        mockMvc.perform(multipart("/recipes/images").file(file).with(member()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.imageUrl").value("https://cdn.example.com/raw.png"));
    }

    @Test
    void likeUnlikeAndMyLikesEndpointsWorkForAuthenticatedUser() throws Exception {
        when(recipeService.likeRecipe(USER_ID, 10L))
                .thenReturn(RecipeLikeResponse.builder().recipeId(10L).liked(true).likeCount(5).build());
        when(recipeService.unlikeRecipe(USER_ID, 10L))
                .thenReturn(RecipeLikeResponse.builder().recipeId(10L).liked(false).likeCount(4).build());
        when(recipeService.getMyLikes(USER_ID, List.of(10L, 11L)))
                .thenReturn(List.of(RecipeLikeResponse.builder().recipeId(10L).liked(true).likeCount(4).build()));

        mockMvc.perform(post("/recipes/10/like").with(member()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.liked").value(true))
                .andExpect(jsonPath("$.result.likeCount").value(5));

        mockMvc.perform(delete("/recipes/10/like").with(member()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.liked").value(false))
                .andExpect(jsonPath("$.result.likeCount").value(4));

        mockMvc.perform(get("/recipes/me/likes").param("recipeIds", "10,11").with(member()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result[0].recipeId").value(10))
                .andExpect(jsonPath("$.result[0].liked").value(true));
    }

    @Test
    void getMyRecipes_requiresAuthentication() throws Exception {
        mockMvc.perform(get("/recipes/me"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void createRecipe_titleTooLong_returns400() throws Exception {
        String body = recipeJson("t".repeat(201), "desc", "https://img.example.com/a.jpg", "GRAM", "note", "Cook well");

        mockMvc.perform(post("/recipes").with(member())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(4109));
        verifyNoInteractions(recipeService);
    }

    @Test
    void createRecipe_descriptionTooLong_returns400() throws Exception {
        String body = recipeJson("Valid Title", "d".repeat(2001), "https://img.example.com/a.jpg", "GRAM", "note", "Cook well");

        mockMvc.perform(post("/recipes").with(member())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(4110));
        verifyNoInteractions(recipeService);
    }

    @Test
    void createRecipe_imageUrlTooLong_returns400() throws Exception {
        String body = recipeJson("Valid Title", "desc", "https://img.example.com/" + "a".repeat(500), "GRAM", "note", "Cook well");

        mockMvc.perform(post("/recipes").with(member())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(4111));
        verifyNoInteractions(recipeService);
    }

    @Test
    void createRecipe_unitTooLong_returns400() throws Exception {
        String body = recipeJson("Valid Title", "desc", "https://img.example.com/a.jpg", "U".repeat(31), "note", "Cook well");

        mockMvc.perform(post("/recipes").with(member())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(4121));
        verifyNoInteractions(recipeService);
    }

    @Test
    void createRecipe_noteTooLong_returns400() throws Exception {
        String body = recipeJson("Valid Title", "desc", "https://img.example.com/a.jpg", "GRAM", "n".repeat(301), "Cook well");

        mockMvc.perform(post("/recipes").with(member())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(4122));
        verifyNoInteractions(recipeService);
    }

    @Test
    void createRecipe_stepInstructionTooLong_returns400() throws Exception {
        String body = recipeJson("Valid Title", "desc", "https://img.example.com/a.jpg", "GRAM", "note", "s".repeat(2001));

        mockMvc.perform(post("/recipes").with(member())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(4126));
        verifyNoInteractions(recipeService);
    }

    private static String recipeJson(String title, String description, String imageUrl,
                                     String unit, String note, String instruction) {
        return """
                {
                  "title": "%s",
                  "description": "%s",
                  "imageUrl": "%s",
                  "servings": 2,
                  "prepTime": 10,
                  "cookTime": 15,
                  "ingredients": [{"ingredientId": 1, "quantity": 100, "unit": "%s", "note": "%s"}],
                  "steps": [{"stepNumber": 1, "instruction": "%s"}]
                }
                """.formatted(title, description, imageUrl, unit, note, instruction);
    }
}
