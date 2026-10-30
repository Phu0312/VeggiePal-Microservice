package com.veggiepal.blog.dto.response;

import com.fasterxml.jackson.annotation.JsonInclude;

import lombok.*;
import lombok.experimental.FieldDefaults;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class VoteResponse {

    @JsonInclude(JsonInclude.Include.NON_NULL)
    Long blogId;

    @JsonInclude(JsonInclude.Include.NON_NULL)
    Long videoId;

    /** The caller's own vote: 1, -1, or null when they have not voted. */
    Integer myVote;

    Integer voteScore;
}
