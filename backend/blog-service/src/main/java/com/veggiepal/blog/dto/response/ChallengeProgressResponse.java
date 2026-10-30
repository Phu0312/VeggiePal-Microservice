package com.veggiepal.blog.dto.response;

import java.time.LocalDate;
import java.util.List;

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
public class ChallengeProgressResponse {

    int days;
    int total;
    boolean checkedToday;
    boolean completed;
    boolean broken;
    boolean justCompleted;
    LocalDate completedAt;
    List<String> checkIns;
    String badgeName;
}

