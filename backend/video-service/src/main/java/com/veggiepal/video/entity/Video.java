package com.veggiepal.video.entity;

import java.time.LocalDateTime;

import jakarta.persistence.*;

import com.veggiepal.video.enums.ContentStatus;

import lombok.*;
import lombok.experimental.FieldDefaults;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
@Entity
@Table(name = "videos")
public class Video {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    Long id;

    @Column(name = "author_id", nullable = false)
    Long authorId;

    @Column(name = "category_id", nullable = false)
    Long categoryId;

    @Column(name = "category_name")
    String categoryName;

    @Column(nullable = false)
    String title;

    @Column(columnDefinition = "TEXT")
    String description;

    @Column(name = "video_url", nullable = false)
    String videoUrl;

    @Column(name = "thumbnail_url")
    String thumbnailUrl;

    @Column(name = "duration_seconds")
    Integer durationSeconds;

    @Column(columnDefinition = "TEXT")
    String summary;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    ContentStatus status;

    @Column(name = "view_count", nullable = false)
    Integer viewCount;

    @Column(name = "vote_score", nullable = false)
    Integer voteScore;

    @Column(name = "created_at", nullable = false, updatable = false)
    LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    LocalDateTime updatedAt;

    @Column(name = "published_at")
    LocalDateTime publishedAt;

    @Column(name = "moderation_reason")
    String moderationReason;

    @PrePersist
    void prePersist() {
        LocalDateTime now = LocalDateTime.now();
        createdAt = now;
        updatedAt = now;
        if (viewCount == null) viewCount = 0;
        if (voteScore == null) voteScore = 0;
        if (status == null) status = ContentStatus.DRAFT;
    }

    @PreUpdate
    void preUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
