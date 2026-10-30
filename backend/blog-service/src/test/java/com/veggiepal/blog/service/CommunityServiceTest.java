package com.veggiepal.blog.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.veggiepal.blog.dto.response.ChallengeProgressResponse;
import com.veggiepal.blog.dto.response.FollowResponse;
import com.veggiepal.blog.dto.response.LeaderboardEntryResponse;
import com.veggiepal.blog.entity.UserChallenge;
import com.veggiepal.blog.entity.UserFollow;
import com.veggiepal.blog.enums.ContentStatus;
import com.veggiepal.blog.exception.AppException;
import com.veggiepal.blog.exception.ErrorCode;
import com.veggiepal.blog.repository.BlogRepository;
import com.veggiepal.blog.repository.CategoryRepository;
import com.veggiepal.blog.repository.CommentRepository;
import com.veggiepal.blog.repository.UserChallengeRepository;
import com.veggiepal.blog.repository.UserFollowRepository;
import com.veggiepal.blog.repository.VideoRepository;

@ExtendWith(MockitoExtension.class)
class CommunityServiceTest {

    @Mock BlogRepository blogRepository;
    @Mock VideoRepository videoRepository;
    @Mock CategoryRepository categoryRepository;
    @Mock CommentRepository commentRepository;
    @Mock UserFollowRepository userFollowRepository;
    @Mock UserChallengeRepository userChallengeRepository;

    @InjectMocks
    CommunityService communityService;

    @Test
    void follow_self_isRejected() {
        assertThatThrownBy(() -> communityService.followAuthor(5L, 5L))
                .isInstanceOf(AppException.class)
                .extracting("errorCode")
                .isEqualTo(ErrorCode.CANNOT_FOLLOW_SELF);
    }

    @Test
    void follow_createsRowAndReturnsFollowerCount() {
        when(userFollowRepository.findByFollowerIdAndFolloweeId(1L, 2L)).thenReturn(Optional.empty());
        when(userFollowRepository.save(any(UserFollow.class))).thenAnswer(inv -> inv.getArgument(0));
        when(userFollowRepository.countByFolloweeId(2L)).thenReturn(3L);

        FollowResponse response = communityService.followAuthor(1L, 2L);

        assertThat(response.isFollowing()).isTrue();
        assertThat(response.getFollowersCount()).isEqualTo(3L);
    }

    @Test
    void leaderboard_ranksByPostsThenLikes() {
        BlogRepository.AuthorAggregate a = new BlogRepository.AuthorAggregate() {
            public Long getAuthorId() { return 10L; }
            public Long getPostCount() { return 2L; }
            public Long getTotalLikes() { return 5L; }
        };
        BlogRepository.AuthorAggregate b = new BlogRepository.AuthorAggregate() {
            public Long getAuthorId() { return 20L; }
            public Long getPostCount() { return 4L; }
            public Long getTotalLikes() { return 1L; }
        };
        when(blogRepository.aggregateByAuthor(ContentStatus.PUBLISHED)).thenReturn(List.of(a, b));
        when(videoRepository.aggregateCreators(ContentStatus.PUBLISHED)).thenReturn(List.of());
        when(userFollowRepository.countByFolloweeIds(any())).thenReturn(List.of());

        List<LeaderboardEntryResponse> result = communityService.getLeaderboard(null, 5);

        assertThat(result).extracting(LeaderboardEntryResponse::getAuthorId).containsExactly(20L, 10L);
        assertThat(result.get(0).getPostsCount()).isEqualTo(4L);
    }

    @Test
    void challenge_sevenConsecutiveDays_completes_andGapBreaksStreak() {
        UserChallenge record = UserChallenge.builder().userId(1L).build();
        when(userChallengeRepository.findByUserId(1L)).thenReturn(Optional.of(record));
        when(userChallengeRepository.save(any(UserChallenge.class))).thenAnswer(inv -> inv.getArgument(0));

        LocalDate start = LocalDate.of(2026, 10, 1);
        ChallengeProgressResponse last = null;
        for (int i = 0; i < 7; i++) {
            last = communityService.checkInChallengeOnDate(1L, start.plusDays(i));
        }

        assertThat(last.isCompleted()).isTrue();
        assertThat(last.isJustCompleted()).isTrue();
        assertThat(last.getDays()).isEqualTo(7);

        UserChallenge broken = UserChallenge.builder().userId(2L).checkInDates("2026-10-01,2026-10-02").build();
        ChallengeProgressResponse progress = communityService.evaluateProgress(broken, LocalDate.of(2026, 10, 10), false);
        assertThat(progress.isBroken()).isTrue();
        assertThat(progress.getDays()).isZero();
    }

    @Test
    void toHashtag_stripsVietnameseDiacritics() {
        assertThat(CommunityService.toHashtag("Món chay đặc biệt")).isEqualTo("MonChayDacBiet");
    }
}

