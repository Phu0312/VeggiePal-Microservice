package com.veggiepal.entity;

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

import com.veggiepal.enums.OtpPurpose;

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
        name = "user_otps",
        indexes = {
                @Index(name = "idx_user_otps_email_purpose", columnList = "email, purpose"),
                @Index(name = "idx_user_otps_reset_token", columnList = "reset_token")
        }
)
public class UserOtp {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    Long id;

    @Column(name = "user_id", nullable = false)
    Long userId;

    @Column(nullable = false, length = 255)
    String email;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    OtpPurpose purpose;

    @Column(name = "code_hash", nullable = false, length = 64)
    String codeHash;

    @Column(name = "reset_token", length = 64)
    String resetToken;

    @Column(nullable = false)
    @Builder.Default
    Integer attempts = 0;

    @Column(nullable = false)
    @Builder.Default
    Boolean used = false;

    @Column(name = "expires_at", nullable = false)
    LocalDateTime expiresAt;

    @Column(name = "created_at", nullable = false, updatable = false)
    LocalDateTime createdAt;

    @PrePersist
    void prePersist() {
        if (createdAt == null) {
            createdAt = LocalDateTime.now();
        }
        if (attempts == null) {
            attempts = 0;
        }
        if (used == null) {
            used = false;
        }
    }
}

