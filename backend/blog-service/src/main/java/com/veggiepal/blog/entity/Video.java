package com.veggiepal.blog.entity;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import jakarta.persistence.*;

import com.veggiepal.blog.enums.ContentStatus;
import com.veggiepal.blog.enums.VideoSource;

import lombok.*;
import lombok.experimental.FieldDefaults;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
@Entity
@Table(
        name = "videos",
        indexes = {
                @Index(name = "idx_videos_status_published", columnList = "status, published_at"),
                @Index(name = "idx_videos_author", columnList = "author_id, created_at"),
                @Index(name = "idx_videos_category", columnList = "category_id, status")
        }
)
public class Video {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    Long id;

    // From the JWT userId claim. No FK: users live in another service's database.
    @Column(name = "author_id", nullable = false)
    Long authorId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "category_id", nullable = false)
    @ToString.Exclude
    @EqualsAndHashCode.Exclude
    Category category;

    @Column(nullable = false, length = 200)
    String title;

    // TEXT through columnDefinition, never @Lob: see the note on Blog.content
    @Column(columnDefinition = "TEXT")
    String description;

    @Enumerated(EnumType.STRING)
    @org.hibernate.annotations.JdbcTypeCode(org.hibernate.type.SqlTypes.VARCHAR)
    @Column(name = "source_type", nullable = false)
    VideoSource sourceType;

    /** Built by VideoService (a Cloudinary secure_url or a YouTube embed URL), never user input. */
    @Column(name = "video_url", nullable = false, length = 512)
    String videoUrl;

    @Column(name = "thumbnail_url", length = 512)
    String thumbnailUrl;

    @Enumerated(EnumType.STRING)
    @org.hibernate.annotations.JdbcTypeCode(org.hibernate.type.SqlTypes.VARCHAR)
    @Column(nullable = false)
    ContentStatus status;

    @Column(name = "view_count", nullable = false)
    Integer viewCount;

    @Column(name = "vote_score", nullable = false, columnDefinition = "INT NOT NULL DEFAULT 0")
    Integer voteScore;

    @Column(name = "serving_label", length = 100)
    String servingLabel;

    @Column(name = "calories")
    Integer calories;

    @Column(name = "protein_g", precision = 8, scale = 2)
    BigDecimal proteinG;

    @Column(name = "carbs_g", precision = 8, scale = 2)
    BigDecimal carbsG;

    @Column(name = "fat_g", precision = 8, scale = 2)
    BigDecimal fatG;

    @Column(name = "fiber_g", precision = 8, scale = 2)
    BigDecimal fiberG;

    // Newline-separated "name|amount" lines; columnDefinition TEXT avoids @Lob CLOB issues
    @Column(name = "ingredients_text", columnDefinition = "TEXT")
    String ingredientsText;

    @Column(name = "published_at")
    LocalDateTime publishedAt;

    @Column(name = "created_at", nullable = false, updatable = false)
    LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    LocalDateTime updatedAt;

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
