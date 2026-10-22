package com.veggiepal.video.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import lombok.*;
import lombok.experimental.FieldDefaults;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class VideoRequest {

    @NotBlank(message = "VIDEO_TITLE_REQUIRED")
    @Size(max = 200, message = "INVALID_REQUEST")
    String title;

    String description;

    @NotBlank(message = "VIDEO_URL_REQUIRED")
    String videoUrl;

    String thumbnailUrl;

    Integer durationSeconds;

    @NotNull(message = "CATEGORY_ID_REQUIRED")
    Long categoryId;

    String categoryName;

    /**
     * false (or absent) saves a draft. true publishes directly.
     */
    Boolean publish;
}
