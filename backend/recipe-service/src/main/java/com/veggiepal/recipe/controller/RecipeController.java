package com.veggiepal.recipe.controller;

import java.util.List;

import org.springframework.http.MediaType;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import com.veggiepal.recipe.dto.request.RecipeRequest;
import com.veggiepal.recipe.dto.response.ApiResponse;
import com.veggiepal.recipe.dto.response.ImageUploadResponse;
import com.veggiepal.recipe.dto.response.PageResponse;
import com.veggiepal.recipe.dto.response.RecipeLikeResponse;
import com.veggiepal.recipe.dto.response.RecipeResponse;
import com.veggiepal.recipe.service.RecipeService;

import jakarta.validation.Valid;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

@RestController
@RequestMapping("/recipes")
@RequiredArgsConstructor
@FieldDefaults(
        level = AccessLevel.PRIVATE,
        makeFinal = true
)
public class RecipeController {

    RecipeService recipeService;

    @GetMapping
    ApiResponse<PageResponse<RecipeResponse>>
    getPublishedRecipes(
            @RequestParam(
                    required = false
            )
            String keyword,

            @RequestParam(
                    required = false
            )
            String sort,

            @RequestParam(
                    defaultValue = "0"
            )
            int page,

            @RequestParam(
                    defaultValue = "10"
            )
            int size
    ) {

        return ApiResponse
                .<PageResponse<RecipeResponse>>
                        builder()
                .result(
                        recipeService
                                .getPublishedRecipes(
                                        keyword,
                                        sort,
                                        page,
                                        size
                                )
                )
                .build();
    }

    @GetMapping("/popular")
    ApiResponse<PageResponse<RecipeResponse>> getPopularRecipes(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size
    ) {
        return ApiResponse
                .<PageResponse<RecipeResponse>>builder()
                .result(recipeService.getPopularRecipes(page, size))
                .build();
    }

    @GetMapping("/{id}")
    ApiResponse<RecipeResponse> getRecipe(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable Long id
    ) {
        return ApiResponse
                .<RecipeResponse>builder()
                .result(
                        recipeService.getRecipe(
                                id,
                                jwt == null ? null : CurrentUser.id(jwt),
                                jwt != null && CurrentUser.isAdmin(jwt)
                        )
                )
                .build();
    }

    @GetMapping("/me")
    ApiResponse<PageResponse<RecipeResponse>>
    getMyRecipes(
            @AuthenticationPrincipal
            Jwt jwt,

            @RequestParam(
                    defaultValue = "0"
            )
            int page,

            @RequestParam(
                    defaultValue = "10"
            )
            int size
    ) {

        Long userId =
                CurrentUser.id(jwt);

        return ApiResponse
                .<PageResponse<RecipeResponse>>
                        builder()
                .result(
                        recipeService
                                .getMyRecipes(
                                        userId,
                                        page,
                                        size
                                )
                )
                .build();
    }

    @GetMapping("/me/likes")
    ApiResponse<List<RecipeLikeResponse>> getMyLikes(
            @AuthenticationPrincipal Jwt jwt,
            @RequestParam("recipeIds") List<Long> recipeIds
    ) {
        return ApiResponse
                .<List<RecipeLikeResponse>>builder()
                .result(recipeService.getMyLikes(CurrentUser.id(jwt), recipeIds))
                .build();
    }

    @PostMapping
    ApiResponse<RecipeResponse>
    createRecipe(
            @AuthenticationPrincipal
            Jwt jwt,

            @RequestBody
            @Valid
            RecipeRequest request
    ) {

        Long userId =
                CurrentUser.id(jwt);

        return ApiResponse
                .<RecipeResponse>builder()
                .result(
                        recipeService
                                .createRecipe(
                                        userId,
                                        request
                                )
                )
                .build();
    }

    @PostMapping(value = "/images", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    ApiResponse<ImageUploadResponse> uploadStandaloneImage(
            @AuthenticationPrincipal Jwt jwt,
            @RequestParam("file") MultipartFile file
    ) {
        return ApiResponse
                .<ImageUploadResponse>builder()
                .result(recipeService.uploadStandaloneImage(CurrentUser.id(jwt), file))
                .build();
    }

    @PostMapping(value = "/{id}/image", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    ApiResponse<RecipeResponse> uploadRecipeImage(
            @PathVariable Long id,
            @AuthenticationPrincipal Jwt jwt,
            @RequestParam("file") MultipartFile file
    ) {
        return ApiResponse
                .<RecipeResponse>builder()
                .result(
                        recipeService.uploadRecipeImage(
                                id,
                                CurrentUser.id(jwt),
                                CurrentUser.isAdmin(jwt),
                                file
                        )
                )
                .build();
    }

    @PostMapping("/{id}/like")
    ApiResponse<RecipeLikeResponse> likeRecipe(
            @PathVariable Long id,
            @AuthenticationPrincipal Jwt jwt
    ) {
        return ApiResponse
                .<RecipeLikeResponse>builder()
                .result(recipeService.likeRecipe(CurrentUser.id(jwt), id))
                .build();
    }

    @DeleteMapping("/{id}/like")
    ApiResponse<RecipeLikeResponse> unlikeRecipe(
            @PathVariable Long id,
            @AuthenticationPrincipal Jwt jwt
    ) {
        return ApiResponse
                .<RecipeLikeResponse>builder()
                .result(recipeService.unlikeRecipe(CurrentUser.id(jwt), id))
                .build();
    }

    @PutMapping("/{id}")
    ApiResponse<RecipeResponse>
    updateRecipe(
            @PathVariable Long id,

            @AuthenticationPrincipal
            Jwt jwt,

            @RequestBody
            @Valid
            RecipeRequest request
    ) {

        Long userId =
                CurrentUser.id(jwt);

        boolean admin =
                CurrentUser.isAdmin(jwt);

        return ApiResponse
                .<RecipeResponse>builder()
                .result(
                        recipeService
                                .updateRecipe(
                                        id,
                                        userId,
                                        admin,
                                        request
                                )
                )
                .build();
    }

    @PostMapping("/{id}/publish")
    ApiResponse<RecipeResponse>
    publishRecipe(
            @PathVariable Long id,

            @AuthenticationPrincipal
            Jwt jwt
    ) {

        Long userId =
                CurrentUser.id(jwt);

        boolean admin =
                CurrentUser.isAdmin(jwt);

        return ApiResponse
                .<RecipeResponse>builder()
                .result(
                        recipeService
                                .publishRecipe(
                                        id,
                                        userId,
                                        admin
                                )
                )
                .build();
    }

    @DeleteMapping("/{id}")
    ApiResponse<Void>
    deleteRecipe(
            @PathVariable Long id,

            @AuthenticationPrincipal
            Jwt jwt
    ) {

        Long userId =
                CurrentUser.id(jwt);

        boolean admin =
                CurrentUser.isAdmin(jwt);

        recipeService.deleteRecipe(
                id,
                userId,
                admin
        );

        return ApiResponse
                .<Void>builder()
                .build();
    }
}
