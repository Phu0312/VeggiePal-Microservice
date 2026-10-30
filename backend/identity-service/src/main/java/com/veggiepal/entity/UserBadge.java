package com.veggiepal.entity;

import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

import com.veggiepal.enums.BadgeCode;

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
        name = "user_badges",
        uniqueConstraints = {
                @UniqueConstraint(name = "uk_user_badges_code", columnNames = {"user_id", "badge_code"})
        }
)
public class UserBadge {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    Long id;

    @Column(name = "user_id", nullable = false, updatable = false)
    Long userId;

    @Enumerated(EnumType.STRING)
    @Column(name = "badge_code", nullable = false, updatable = false, length = 40)
    BadgeCode badgeCode;

    @Column(name = "earned_at", nullable = false, updatable = false)
    LocalDateTime earnedAt;

    @PrePersist
    void prePersist() {
        if (earnedAt == null) {
            earnedAt = LocalDateTime.now();
        }
    }
}

