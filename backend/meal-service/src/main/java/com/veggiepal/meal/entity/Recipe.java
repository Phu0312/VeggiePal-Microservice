package com.veggiepal.meal.entity;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import jakarta.persistence.*;

import lombok.*;
import lombok.experimental.FieldDefaults;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
@Entity
@Table(name = "recipes")
public class Recipe {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    Long id;

    @Column(nullable = false)
    String name;

    @Column(name = "meal_type", nullable = false)
    String mealType;

    @Column(nullable = false, columnDefinition = "TEXT")
    String ingredients;

    @Column(precision = 6, scale = 1)
    BigDecimal calories;

    @Column(precision = 5, scale = 1)
    BigDecimal protein;

    @Column(precision = 5, scale = 1)
    BigDecimal carbs;

    @Column(precision = 5, scale = 1)
    BigDecimal fat;

    @Column(columnDefinition = "TEXT")
    String instructions;

    @Column(nullable = false)
    @Builder.Default
    Boolean vegan = true;

    @Column(name = "allergen_codes")
    String allergenCodes;

    @Column(name = "created_at", nullable = false, updatable = false)
    LocalDateTime createdAt;

    @PrePersist
    void prePersist() {
        createdAt = LocalDateTime.now();
    }
}
