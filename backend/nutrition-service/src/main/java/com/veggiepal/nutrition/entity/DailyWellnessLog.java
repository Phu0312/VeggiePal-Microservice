package com.veggiepal.nutrition.entity;

import java.time.LocalDate;
import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

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
        name = "daily_wellness_logs",
        uniqueConstraints = {
                @UniqueConstraint(name = "uk_daily_wellness_user_date", columnNames = {"user_id", "log_date"})
        }
)
public class DailyWellnessLog {

    public static final int DEFAULT_WATER_TARGET_ML = 2400;

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    Long id;

    @Column(name = "user_id", nullable = false, updatable = false)
    Long userId;

    @Column(name = "log_date", nullable = false, updatable = false)
    LocalDate logDate;

    @Column(name = "water_ml", nullable = false)
    Integer waterMl;

    @Column(name = "water_target_ml", nullable = false)
    Integer waterTargetMl;

    @Column(name = "exercise_minutes", nullable = false)
    Integer exerciseMinutes;

    @Column(nullable = false)
    Integer steps;

    @Column(name = "calories_burned", nullable = false)
    Integer caloriesBurned;

    @Column(name = "activity_note", length = 200)
    String activityNote;

    @Column(name = "updated_at", nullable = false)
    LocalDateTime updatedAt;

    @PrePersist
    void prePersist() {
        updatedAt = LocalDateTime.now();
        if (logDate == null) {
            logDate = LocalDate.now();
        }
        if (waterMl == null) {
            waterMl = 0;
        }
        if (waterTargetMl == null || waterTargetMl <= 0) {
            waterTargetMl = DEFAULT_WATER_TARGET_ML;
        }
        if (exerciseMinutes == null) {
            exerciseMinutes = 0;
        }
        if (steps == null) {
            steps = 0;
        }
        if (caloriesBurned == null) {
            caloriesBurned = 0;
        }
    }

    @PreUpdate
    void preUpdate() {
        updatedAt = LocalDateTime.now();
    }
}

