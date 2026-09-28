package com.veggiepal.blog.entity;

import java.time.LocalDateTime;

import jakarta.persistence.*;

import com.veggiepal.blog.enums.ContentStatus;

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

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id", nullable = false)
    Category category;

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

    @PrePersist
    void prePersist() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
        if (viewCount == null) {
            viewCount = 0;
        }
        if (voteScore == null) {
            voteScore = 0;
        }
    }

    @PreUpdate
    void preUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
