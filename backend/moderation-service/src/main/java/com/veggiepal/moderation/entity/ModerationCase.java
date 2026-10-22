package com.veggiepal.moderation.entity;

import java.time.LocalDateTime;

import jakarta.persistence.*;

import com.veggiepal.moderation.enums.ModerationDecision;
import com.veggiepal.moderation.enums.TargetType;

import lombok.*;
import lombok.experimental.FieldDefaults;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
@Entity
@Table(name = "moderation_cases")
public class ModerationCase {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    Long id;

    @Enumerated(EnumType.STRING)
    @Column(name = "target_type", nullable = false)
    TargetType targetType;

    @Column(name = "target_id", nullable = false)
    Long targetId;

    @Column(name = "author_id", nullable = false)
    Long authorId;

    @Column(name = "content_snippet", length = 500)
    String contentSnippet;

    @Column(name = "matched_keywords")
    String matchedKeywords;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    ModerationDecision decision;

    @Column(length = 500)
    String reason;

    @Column(name = "reviewed_by")
    Long reviewedBy;

    @Column(name = "reviewed_at")
    LocalDateTime reviewedAt;

    @Column(name = "created_at", nullable = false, updatable = false)
    LocalDateTime createdAt;

    @PrePersist
    void prePersist() {
        createdAt = LocalDateTime.now();
    }
}
