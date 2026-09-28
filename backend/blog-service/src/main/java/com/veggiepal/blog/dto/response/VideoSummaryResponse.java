package com.veggiepal.blog.dto.response;

import java.time.LocalDateTime;

import com.veggiepal.blog.enums.ContentStatus;

import lombok.*;
import lombok.experimental.FieldDefaults;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class VideoSummaryResponse {

    Long id;

    Long authorId;

    Long categoryId;

    String categoryName;

    String title;

    String videoUrl;

    String thumbnailUrl;

    Integer durationSeconds;

    ContentStatus status;

    Integer viewCount;

    Integer voteScore;

    LocalDateTime publishedAt;
}
