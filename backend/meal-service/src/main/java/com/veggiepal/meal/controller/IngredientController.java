package com.veggiepal.meal.controller;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import com.veggiepal.meal.configuration.CurrentUser;
import com.veggiepal.meal.dto.response.ApiResponse;
import com.veggiepal.meal.entity.UserIngredient;
import com.veggiepal.meal.service.UserIngredientService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

@RestController
@RequestMapping({"/nutrition/me/ingredients", "/meal/me/ingredients"})
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
@Tag(name = "User Ingredients", description = "Manage ingredients the user currently has in pantry")
public class IngredientController {

    UserIngredientService userIngredientService;

    @Operation(summary = "List current user's ingredients")
    @GetMapping
    public ApiResponse<List<UserIngredient>> getIngredients(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt
    ) {
        return ApiResponse.<List<UserIngredient>>builder()
                .result(userIngredientService.getIngredients(CurrentUser.id(jwt)))
                .build();
    }

    @Operation(summary = "Add an ingredient")
    @PostMapping
    public ApiResponse<UserIngredient> addIngredient(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt,
            @RequestBody Map<String, Object> body
    ) {
        String name = (String) body.get("name");
        String quantity = (String) body.get("quantity");
        String unit = (String) body.get("unit");
        String expiryStr = (String) body.get("expiryDate");
        LocalDate expiryDate = expiryStr != null ? LocalDate.parse(expiryStr) : null;

        return ApiResponse.<UserIngredient>builder()
                .result(userIngredientService.addIngredient(CurrentUser.id(jwt), name, quantity, unit, expiryDate))
                .build();
    }

    @Operation(summary = "Update an ingredient")
    @PatchMapping("/{id}")
    public ApiResponse<UserIngredient> updateIngredient(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt,
            @PathVariable Long id,
            @RequestBody Map<String, Object> body
    ) {
        String name = (String) body.get("name");
        String quantity = (String) body.get("quantity");
        String unit = (String) body.get("unit");
        String expiryStr = (String) body.get("expiryDate");
        LocalDate expiryDate = expiryStr != null ? LocalDate.parse(expiryStr) : null;

        return ApiResponse.<UserIngredient>builder()
                .result(userIngredientService.updateIngredient(CurrentUser.id(jwt), id, name, quantity, unit, expiryDate))
                .build();
    }

    @Operation(summary = "Delete an ingredient")
    @DeleteMapping("/{id}")
    public ApiResponse<Void> deleteIngredient(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt,
            @PathVariable Long id
    ) {
        userIngredientService.deleteIngredient(CurrentUser.id(jwt), id);
        return ApiResponse.<Void>builder()
                .message("Ingredient deleted successfully")
                .build();
    }
}
