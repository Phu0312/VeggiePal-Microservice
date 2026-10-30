package com.veggiepal.blog.service;

import java.text.Normalizer;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.veggiepal.blog.dto.response.ChallengeProgressResponse;
import com.veggiepal.blog.dto.response.CommunityStatsResponse;
import com.veggiepal.blog.dto.response.FollowResponse;
import com.veggiepal.blog.dto.response.LeaderboardEntryResponse;
import com.veggiepal.blog.dto.response.TrendingTopicResponse;
import com.veggiepal.blog.dto.response.VideoChannelResponse;
import com.veggiepal.blog.entity.Category;
import com.veggiepal.blog.entity.UserChallenge;
import com.veggiepal.blog.entity.UserFollow;
import com.veggiepal.blog.enums.CommentStatus;
import com.veggiepal.blog.enums.ContentStatus;
import com.veggiepal.blog.exception.AppException;
import com.veggiepal.blog.exception.ErrorCode;
import com.veggiepal.blog.repository.BlogRepository;
import com.veggiepal.blog.repository.CategoryRepository;
import com.veggiepal.blog.repository.CommentRepository;
import com.veggiepal.blog.repository.UserChallengeRepository;
import com.veggiepal.blog.repository.UserFollowRepository;
import com.veggiepal.blog.repository.VideoRepository;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class CommunityService {

    public static final int CHALLENGE_DAYS = 7;
    public static final String CHALLENGE_BADGE_NAME = "Trái Tim Xanh Veggie";

    BlogRepository blogRepository;
    VideoRepository videoRepository;
    CategoryRepository categoryRepository;
    CommentRepository commentRepository;
    UserFollowRepository userFollowRepository;
    UserChallengeRepository userChallengeRepository;

    @Transactional(readOnly = true)
    public List<LeaderboardEntryResponse> getLeaderboard(Long viewerId, int limit) {
        int safeLimit = Math.max(1, Math.min(20, limit));

        Map<Long, long[]> statsByAuthor = new HashMap<>();
        // [0]=articles, [1]=videos, [2]=likes
        for (BlogRepository.AuthorAggregate row : blogRepository.aggregateByAuthor(ContentStatus.PUBLISHED)) {
            long[] arr = statsByAuthor.computeIfAbsent(row.getAuthorId(), k -> new long[3]);
            arr[0] += row.getPostCount() != null ? row.getPostCount() : 0L;
            arr[2] += row.getTotalLikes() != null ? row.getTotalLikes() : 0L;
        }
        for (VideoRepository.CreatorAggregate row : videoRepository.aggregateCreators(ContentStatus.PUBLISHED)) {
            long[] arr = statsByAuthor.computeIfAbsent(row.getAuthorId(), k -> new long[3]);
            arr[1] += row.getVideoCount() != null ? row.getVideoCount() : 0L;
            arr[2] += row.getTotalLikes() != null ? row.getTotalLikes() : 0L;
        }

        if (statsByAuthor.isEmpty()) {
            return List.of();
        }

        List<Long> topAuthorIds = statsByAuthor.entrySet().stream()
                .sorted(Comparator.<Map.Entry<Long, long[]>>comparingLong(
                                e -> (e.getValue()[0] + e.getValue()[1]) * 10L + e.getValue()[2])
                        .reversed()
                        .thenComparing(Map.Entry::getKey))
                .limit(safeLimit)
                .map(Map.Entry::getKey)
                .toList();

        Map<Long, Long> followersMap = countFollowers(topAuthorIds);
        Set<Long> viewerFollowing = findFollowingSet(viewerId);

        List<LeaderboardEntryResponse> result = new ArrayList<>();
        for (Long authorId : topAuthorIds) {
            long[] arr = statsByAuthor.get(authorId);
            result.add(LeaderboardEntryResponse.builder()
                    .authorId(authorId)
                    .articlesCount(arr[0])
                    .videosCount(arr[1])
                    .postsCount(arr[0] + arr[1])
                    .totalLikes(arr[2])
                    .followersCount(followersMap.getOrDefault(authorId, 0L))
                    .following(viewerFollowing.contains(authorId))
                    .build());
        }
        return result;
    }

    @Transactional(readOnly = true)
    public List<VideoChannelResponse> getVideoChannels(Long viewerId, int limit) {
        int safeLimit = Math.max(1, Math.min(20, limit));
        List<VideoRepository.CreatorAggregate> creators = videoRepository
                .aggregateCreators(ContentStatus.PUBLISHED)
                .stream()
                .sorted(Comparator.<VideoRepository.CreatorAggregate>comparingLong(
                                c -> c.getVideoCount() != null ? c.getVideoCount() : 0L)
                        .reversed()
                        .thenComparing(Comparator.<VideoRepository.CreatorAggregate>comparingLong(
                                c -> c.getTotalViews() != null ? c.getTotalViews() : 0L).reversed())
                        .thenComparing(VideoRepository.CreatorAggregate::getAuthorId))
                .limit(safeLimit)
                .toList();

        if (creators.isEmpty()) {
            return List.of();
        }

        List<Long> authorIds = creators.stream()
                .map(VideoRepository.CreatorAggregate::getAuthorId)
                .toList();
        Map<Long, Long> followersMap = countFollowers(authorIds);
        Set<Long> viewerFollowing = findFollowingSet(viewerId);

        return creators.stream()
                .map(c -> VideoChannelResponse.builder()
                        .authorId(c.getAuthorId())
                        .videoCount(c.getVideoCount() != null ? c.getVideoCount() : 0L)
                        .totalViews(c.getTotalViews() != null ? c.getTotalViews() : 0L)
                        .totalLikes(c.getTotalLikes() != null ? c.getTotalLikes() : 0L)
                        .followersCount(followersMap.getOrDefault(c.getAuthorId(), 0L))
                        .following(viewerFollowing.contains(c.getAuthorId()))
                        .build())
                .toList();
    }

    @Transactional(readOnly = true)
    public List<TrendingTopicResponse> getTrendingTopics(int limit) {
        int safeLimit = Math.max(1, Math.min(20, limit));
        Map<Long, TrendingTopicResponse> topics = new LinkedHashMap<>();

        for (BlogRepository.CategoryAggregate row : blogRepository.countByCategory(ContentStatus.PUBLISHED)) {
            topics.put(row.getCategoryId(), TrendingTopicResponse.builder()
                    .categoryId(row.getCategoryId())
                    .name(row.getCategoryName())
                    .tag(toHashtag(row.getCategoryName()))
                    .count(row.getPostCount() != null ? row.getPostCount() : 0L)
                    .build());
        }

        for (BlogRepository.CategoryAggregate row : videoRepository.countByCategory(ContentStatus.PUBLISHED)) {
            long count = row.getPostCount() != null ? row.getPostCount() : 0L;
            topics.compute(row.getCategoryId(), (id, existing) -> {
                if (existing == null) {
                    return TrendingTopicResponse.builder()
                            .categoryId(id)
                            .name(row.getCategoryName())
                            .tag(toHashtag(row.getCategoryName()))
                            .count(count)
                            .build();
                }
                existing.setCount(existing.getCount() + count);
                return existing;
            });
        }

        if (topics.size() < safeLimit) {
            for (Category category : categoryRepository.findAll()) {
                if (Boolean.TRUE.equals(category.getActive()) && !topics.containsKey(category.getId())) {
                    topics.put(category.getId(), TrendingTopicResponse.builder()
                            .categoryId(category.getId())
                            .name(category.getName())
                            .tag(toHashtag(category.getName()))
                            .count(0L)
                            .build());
                }
                if (topics.size() >= safeLimit * 2) {
                    break;
                }
            }
        }

        return topics.values().stream()
                .sorted(Comparator.comparingLong(TrendingTopicResponse::getCount).reversed()
                        .thenComparing(TrendingTopicResponse::getCategoryId))
                .limit(safeLimit)
                .toList();
    }

    @Transactional(readOnly = true)
    public CommunityStatsResponse getCommunityStats() {
        long blogs = blogRepository.countByStatus(ContentStatus.PUBLISHED);
        long videos = videoRepository.countByStatus(ContentStatus.PUBLISHED);
        long comments = commentRepository.countByStatus(CommentStatus.VISIBLE);

        Set<Long> authors = new HashSet<>();
        blogRepository.aggregateByAuthor(ContentStatus.PUBLISHED)
                .forEach(a -> authors.add(a.getAuthorId()));
        videoRepository.aggregateCreators(ContentStatus.PUBLISHED)
                .forEach(a -> authors.add(a.getAuthorId()));

        return CommunityStatsResponse.builder()
                .publishedBlogs(blogs)
                .publishedVideos(videos)
                .totalPosts(blogs + videos)
                .activeAuthors(authors.size())
                .totalComments(comments)
                .build();
    }

    @Transactional
    public FollowResponse followAuthor(Long followerId, Long followeeId) {
        if (followerId.equals(followeeId)) {
            throw new AppException(ErrorCode.CANNOT_FOLLOW_SELF);
        }
        userFollowRepository.findByFollowerIdAndFolloweeId(followerId, followeeId)
                .orElseGet(() -> userFollowRepository.save(UserFollow.builder()
                        .followerId(followerId)
                        .followeeId(followeeId)
                        .build()));

        return FollowResponse.builder()
                .authorId(followeeId)
                .following(true)
                .followersCount(userFollowRepository.countByFolloweeId(followeeId))
                .build();
    }

    @Transactional
    public FollowResponse unfollowAuthor(Long followerId, Long followeeId) {
        userFollowRepository.findByFollowerIdAndFolloweeId(followerId, followeeId)
                .ifPresent(userFollowRepository::delete);

        return FollowResponse.builder()
                .authorId(followeeId)
                .following(false)
                .followersCount(userFollowRepository.countByFolloweeId(followeeId))
                .build();
    }

    @Transactional(readOnly = true)
    public List<Long> getMyFollowingIds(Long followerId) {
        return userFollowRepository.findByFollowerIdOrderByCreatedAtDesc(followerId).stream()
                .map(UserFollow::getFolloweeId)
                .toList();
    }

    @Transactional(readOnly = true)
    public ChallengeProgressResponse getChallengeProgress(Long userId) {
        LocalDate today = LocalDate.now();
        return userChallengeRepository.findByUserId(userId)
                .map(record -> evaluateProgress(record, today, false))
                .orElseGet(() -> ChallengeProgressResponse.builder()
                        .days(0)
                        .total(CHALLENGE_DAYS)
                        .checkedToday(false)
                        .completed(false)
                        .broken(false)
                        .justCompleted(false)
                        .completedAt(null)
                        .checkIns(List.of())
                        .badgeName(CHALLENGE_BADGE_NAME)
                        .build());
    }

    @Transactional
    public ChallengeProgressResponse checkInChallenge(Long userId) {
        return checkInChallengeOnDate(userId, LocalDate.now());
    }

    @Transactional
    ChallengeProgressResponse checkInChallengeOnDate(Long userId, LocalDate today) {
        UserChallenge challenge = userChallengeRepository.findByUserId(userId)
                .orElseGet(() -> UserChallenge.builder().userId(userId).build());

        ChallengeProgressResponse current = evaluateProgress(challenge, today, false);
        if (current.isCompleted() || current.isCheckedToday()) {
            return current;
        }

        List<LocalDate> dates = parseDates(challenge.getCheckInDates());
        List<LocalDate> nextDates = current.getDays() == 0
                ? List.of(today)
                : appendDate(dates, today);

        boolean justCompleted = nextDates.size() >= CHALLENGE_DAYS;
        challenge.setCheckInDates(formatDates(nextDates));
        if (justCompleted) {
            challenge.setCompletedAt(today);
        }

        UserChallenge saved = userChallengeRepository.save(challenge);
        return evaluateProgress(saved, today, justCompleted);
    }

    ChallengeProgressResponse evaluateProgress(UserChallenge record, LocalDate today, boolean justCompleted) {
        List<LocalDate> dates = parseDates(record.getCheckInDates());
        List<String> isoDates = dates.stream().map(LocalDate::toString).toList();

        if (record.getCompletedAt() != null) {
            return ChallengeProgressResponse.builder()
                    .days(CHALLENGE_DAYS)
                    .total(CHALLENGE_DAYS)
                    .checkedToday(today.equals(record.getCompletedAt()))
                    .completed(true)
                    .broken(false)
                    .justCompleted(justCompleted)
                    .completedAt(record.getCompletedAt())
                    .checkIns(isoDates)
                    .badgeName(CHALLENGE_BADGE_NAME)
                    .build();
        }

        if (dates.isEmpty()) {
            return ChallengeProgressResponse.builder()
                    .days(0)
                    .total(CHALLENGE_DAYS)
                    .checkedToday(false)
                    .completed(false)
                    .broken(false)
                    .justCompleted(false)
                    .completedAt(null)
                    .checkIns(List.of())
                    .badgeName(CHALLENGE_BADGE_NAME)
                    .build();
        }

        LocalDate last = dates.getLast();
        long gap = ChronoUnit.DAYS.between(last, today);
        if (gap <= 1) {
            return ChallengeProgressResponse.builder()
                    .days(dates.size())
                    .total(CHALLENGE_DAYS)
                    .checkedToday(gap <= 0)
                    .completed(false)
                    .broken(false)
                    .justCompleted(false)
                    .completedAt(null)
                    .checkIns(isoDates)
                    .badgeName(CHALLENGE_BADGE_NAME)
                    .build();
        }

        return ChallengeProgressResponse.builder()
                .days(0)
                .total(CHALLENGE_DAYS)
                .checkedToday(false)
                .completed(false)
                .broken(true)
                .justCompleted(false)
                .completedAt(null)
                .checkIns(List.of())
                .badgeName(CHALLENGE_BADGE_NAME)
                .build();
    }

    private Map<Long, Long> countFollowers(List<Long> authorIds) {
        return userFollowRepository.countByFolloweeIds(authorIds).stream()
                .collect(Collectors.toMap(
                        UserFollowRepository.FollowerCount::getFolloweeId,
                        UserFollowRepository.FollowerCount::getTotal
                ));
    }

    private Set<Long> findFollowingSet(Long viewerId) {
        if (viewerId == null) {
            return Set.of();
        }
        return userFollowRepository.findByFollowerIdOrderByCreatedAtDesc(viewerId).stream()
                .map(UserFollow::getFolloweeId)
                .collect(Collectors.toSet());
    }

    static List<LocalDate> parseDates(String csv) {
        if (csv == null || csv.isBlank()) {
            return List.of();
        }
        List<LocalDate> dates = new ArrayList<>();
        for (String part : csv.split(",")) {
            String trimmed = part.trim();
            if (!trimmed.isEmpty()) {
                dates.add(LocalDate.parse(trimmed));
            }
        }
        return dates;
    }

    private static List<LocalDate> appendDate(List<LocalDate> existing, LocalDate next) {
        List<LocalDate> copy = new ArrayList<>(existing);
        copy.add(next);
        return copy;
    }

    private static String formatDates(List<LocalDate> dates) {
        return dates.stream().map(LocalDate::toString).collect(Collectors.joining(","));
    }

    static String toHashtag(String rawName) {
        if (rawName == null || rawName.isBlank()) {
            return "VeggiePal";
        }
        String normalized = Normalizer.normalize(rawName.replace('đ', 'd').replace('Đ', 'D'), Normalizer.Form.NFD)
                .replaceAll("\\p{M}+", "");
        StringBuilder sb = new StringBuilder();
        for (String token : normalized.split("[^A-Za-z0-9]+")) {
            if (!token.isEmpty()) {
                sb.append(Character.toUpperCase(token.charAt(0)));
                if (token.length() > 1) {
                    sb.append(token.substring(1));
                }
            }
        }
        return sb.isEmpty() ? "VeggiePal" : sb.toString();
    }
}
