package com.veggiepal.blog.dto.response;

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
public class LeaderboardEntryResponse {

    Long authorId;
    long articlesCount;
    long videosCount;
    long postsCount;
    long totalLikes;
    long followersCount;
    boolean following;
}

