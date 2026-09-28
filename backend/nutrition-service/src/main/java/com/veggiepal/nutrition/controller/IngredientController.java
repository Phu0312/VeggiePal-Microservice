package com.veggiepal.nutrition.controller;

import java.time.LocalDate;
import java.util.List;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import com.veggiepal.nutrition.dto.response.ApiResponse;
import com.veggiepal.nutrition.entity.UserIngredient;
import com.veggiepal.nutrition.service.UserIngredientService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

@RestController
@RequestMapping("/nutrition/me/ingredients")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
@Tag(name = "User Ingredients", description = "Manage ingredients the user currently has")
public class IngredientController {

    UserIngredientService userIngredientService;

    @Operation(summary = "List current user's ingredients")
    @GetMapping
    ApiResponse<List<UserIngredient>> getIngredients(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt
    ) {
        return ApiResponse.<List<UserIngredient>>builder()
                .result(userIngredientService.getIngredients(CurrentUser.id(jwt)))
                .build();
    }

    @Operation(summary = "Add an ingredient")
    @PostMapping
    ApiResponse<UserIngredient> addIngredient(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt,
            @RequestBody java.util.Map<String, Object> body
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
    ApiResponse<UserIngredient> updateIngredient(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt,
            @PathVariable("id") Long id,
            @RequestBody java.util.Map<String, Object> body
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
    ApiResponse<Void> deleteIngredient(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt,
            @PathVariable("id") Long id
    ) {
        userIngredientService.deleteIngredient(CurrentUser.id(jwt), id);
        return ApiResponse.<Void>builder().build();
    }
}
