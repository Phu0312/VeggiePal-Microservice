package com.veggiepal.meal.service;

import java.time.LocalDate;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.veggiepal.meal.entity.UserIngredient;
import com.veggiepal.meal.exception.AppException;
import com.veggiepal.meal.exception.ErrorCode;
import com.veggiepal.meal.repository.UserIngredientRepository;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class UserIngredientService {

    UserIngredientRepository userIngredientRepository;

    public List<UserIngredient> getIngredients(Long userId) {
        return userIngredientRepository.findByUserId(userId);
    }

    public UserIngredient addIngredient(Long userId, String name, String quantity, String unit, LocalDate expiryDate) {
        UserIngredient ingredient = UserIngredient.builder()
                .userId(userId)
                .name(name.trim())
                .quantity(quantity)
                .unit(unit)
                .expiryDate(expiryDate)
                .build();

        return userIngredientRepository.save(ingredient);
    }

    public UserIngredient updateIngredient(Long userId, Long ingredientId, String name, String quantity, String unit, LocalDate expiryDate) {
        UserIngredient ingredient = userIngredientRepository.findByIdAndUserId(ingredientId, userId)
                .orElseThrow(() -> new AppException(ErrorCode.INGREDIENT_NOT_FOUND));

        if (name != null) ingredient.setName(name.trim());
        if (quantity != null) ingredient.setQuantity(quantity);
        if (unit != null) ingredient.setUnit(unit);
        if (expiryDate != null) ingredient.setExpiryDate(expiryDate);

        return userIngredientRepository.save(ingredient);
    }

    @Transactional
    public void deleteIngredient(Long userId, Long ingredientId) {
        UserIngredient ingredient = userIngredientRepository.findByIdAndUserId(ingredientId, userId)
                .orElseThrow(() -> new AppException(ErrorCode.INGREDIENT_NOT_FOUND));

        userIngredientRepository.delete(ingredient);
    }
}
