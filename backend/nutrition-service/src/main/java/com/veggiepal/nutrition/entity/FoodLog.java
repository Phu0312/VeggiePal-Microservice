package com.veggiepal.nutrition.entity;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;

import com.veggiepal.nutrition.enums.MealType;

import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
@Entity
@Table(
        name = "food_logs",
        indexes = {
                @Index(name = "idx_food_logs_user_date", columnList = "user_id, log_date")
        }
)
public class FoodLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    Long id;

    @Column(name = "user_id", nullable = false, updatable = false)
    Long userId;

    @Column(name = "log_date", nullable = false)
    LocalDate logDate;

    @Enumerated(EnumType.STRING)
    @Column(name = "meal_type", nullable = false, length = 20)
    MealType mealType;

    @Column(name = "food_name", nullable = false, length = 200)
    String foodName;

    @Column(name = "recipe_id")
    Long recipeId;

    @Column(nullable = false)
    Integer calories;

    @Column(name = "protein_g", nullable = false, precision = 8, scale = 2)
    BigDecimal proteinG;

    @Column(name = "carbs_g", nullable = false, precision = 8, scale = 2)
    BigDecimal carbsG;

    @Column(name = "fat_g", nullable = false, precision = 8, scale = 2)
    BigDecimal fatG;

    @Column(name = "fiber_g", nullable = false, precision = 8, scale = 2)
    BigDecimal fiberG;

    @Column(name = "created_at", nullable = false, updatable = false)
    LocalDateTime createdAt;

    @PrePersist
    void prePersist() {
        if (createdAt == null) {
            createdAt = LocalDateTime.now();
        }
        if (logDate == null) {
            logDate = LocalDate.now();
        }
        if (mealType == null) {
            mealType = MealType.SNACK;
        }
        if (calories == null) {
            calories = 0;
        }
        if (proteinG == null) {
            proteinG = BigDecimal.ZERO;
        }
        if (carbsG == null) {
            carbsG = BigDecimal.ZERO;
        }
        if (fatG == null) {
            fatG = BigDecimal.ZERO;
        }
        if (fiberG == null) {
            fiberG = BigDecimal.ZERO;
        }
    }
}

