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
public class CommunityStatsResponse {

    long publishedBlogs;
    long publishedVideos;
    long totalPosts;
    long activeAuthors;
    long totalComments;
}

