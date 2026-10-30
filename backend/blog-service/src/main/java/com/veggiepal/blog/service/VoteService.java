package com.veggiepal.blog.service;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.veggiepal.blog.dto.response.VoteResponse;
import com.veggiepal.blog.entity.Blog;
import com.veggiepal.blog.entity.ContentVote;
import com.veggiepal.blog.entity.Video;
import com.veggiepal.blog.enums.TargetType;
import com.veggiepal.blog.exception.AppException;
import com.veggiepal.blog.exception.ErrorCode;
import com.veggiepal.blog.repository.BlogRepository;
import com.veggiepal.blog.repository.ContentVoteRepository;
import com.veggiepal.blog.repository.VideoRepository;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class VoteService {

    static final int MAX_TARGET_IDS = 100;

    ContentVoteRepository contentVoteRepository;
    BlogRepository blogRepository;
    BlogService blogService;
    VideoRepository videoRepository;
    VideoService videoService;

    @Transactional
    public VoteResponse vote(Long userId, Long blogId, Integer value) {

        validateVoteValue(value);

        Blog blog = requireVotableBlog(userId, blogId);

        Optional<ContentVote> existing = findVote(userId, TargetType.BLOG, blogId);

        Integer previous = existing.map(ContentVote::getValue).orElse(null);

        // Task sheet US5: the same vote a second time takes it back, so a heart button can
        // send 1 on every click. The opposite value still switches the vote, keeping downvote.
        if (value.equals(previous)) {
            contentVoteRepository.delete(existing.get());
            return applyBlogDelta(blog, previous, null);
        }

        ContentVote vote = existing.orElseGet(() -> ContentVote.builder()
                .userId(userId)
                .targetType(TargetType.BLOG)
                .targetId(blogId)
                .build());

        vote.setValue(value);
        contentVoteRepository.save(vote);

        return applyBlogDelta(blog, previous, value);
    }

    @Transactional
    public VoteResponse removeVote(Long userId, Long blogId) {

        Blog blog = blogService.requirePublishedBlog(blogId);

        Optional<ContentVote> existing = findVote(userId, TargetType.BLOG, blogId);

        if (existing.isEmpty()) {
            // Nothing to undo; the caller already has what they asked for
            return blogResponse(blogId, null, blog.getVoteScore());
        }

        Integer previous = existing.get().getValue();
        contentVoteRepository.delete(existing.get());

        return applyBlogDelta(blog, previous, null);
    }

    public List<VoteResponse> getMyVotes(Long userId, List<Long> blogIds) {

        if (blogIds == null || blogIds.isEmpty()) {
            throw new AppException(ErrorCode.BLOG_IDS_REQUIRED);
        }

        if (blogIds.size() > MAX_TARGET_IDS) {
            throw new AppException(ErrorCode.INVALID_REQUEST);
        }

        Map<Long, Integer> byBlogId = contentVoteRepository
                .findByUserIdAndTargetTypeAndTargetIdIn(userId, TargetType.BLOG, blogIds)
                .stream()
                .collect(Collectors.toMap(ContentVote::getTargetId, ContentVote::getValue));

        // One entry per requested id, so the client can index the result directly
        return blogIds.stream()
                .map(blogId -> blogResponse(blogId, byBlogId.get(blogId), null))
                .toList();
    }

    @Transactional
    public VoteResponse voteVideo(Long userId, Long videoId, Integer value) {

        validateVoteValue(value);

        Video video = requireVotableVideo(userId, videoId);

        Optional<ContentVote> existing = findVote(userId, TargetType.VIDEO, videoId);

        Integer previous = existing.map(ContentVote::getValue).orElse(null);

        if (value.equals(previous)) {
            contentVoteRepository.delete(existing.get());
            return applyVideoDelta(video, previous, null);
        }

        ContentVote vote = existing.orElseGet(() -> ContentVote.builder()
                .userId(userId)
                .targetType(TargetType.VIDEO)
                .targetId(videoId)
                .build());

        vote.setValue(value);
        contentVoteRepository.save(vote);

        return applyVideoDelta(video, previous, value);
    }

    @Transactional
    public VoteResponse removeVideoVote(Long userId, Long videoId) {

        Video video = videoService.requirePublishedVideo(videoId);

        Optional<ContentVote> existing = findVote(userId, TargetType.VIDEO, videoId);

        if (existing.isEmpty()) {
            int score = video.getVoteScore() == null ? 0 : video.getVoteScore();
            return videoResponse(videoId, null, score);
        }

        Integer previous = existing.get().getValue();
        contentVoteRepository.delete(existing.get());

        return applyVideoDelta(video, previous, null);
    }

    public List<VoteResponse> getMyVideoVotes(Long userId, List<Long> videoIds) {

        if (videoIds == null || videoIds.isEmpty()) {
            throw new AppException(ErrorCode.VIDEO_IDS_REQUIRED);
        }

        if (videoIds.size() > MAX_TARGET_IDS) {
            throw new AppException(ErrorCode.INVALID_REQUEST);
        }

        Map<Long, Integer> byVideoId = contentVoteRepository
                .findByUserIdAndTargetTypeAndTargetIdIn(userId, TargetType.VIDEO, videoIds)
                .stream()
                .collect(Collectors.toMap(ContentVote::getTargetId, ContentVote::getValue));

        return videoIds.stream()
                .map(videoId -> videoResponse(videoId, byVideoId.get(videoId), null))
                .toList();
    }

    private static void validateVoteValue(Integer value) {
        if (value == null || (value != 1 && value != -1)) {
            throw new AppException(ErrorCode.INVALID_VOTE_VALUE);
        }
    }

    private Blog requireVotableBlog(Long userId, Long blogId) {

        Blog blog = blogService.requirePublishedBlog(blogId);

        // UC-04: members vote on OTHER people's posts
        if (blog.getAuthorId().equals(userId)) {
            throw new AppException(ErrorCode.CANNOT_VOTE_OWN_CONTENT);
        }

        return blog;
    }

    private Video requireVotableVideo(Long userId, Long videoId) {

        Video video = videoService.requirePublishedVideo(videoId);

        if (video.getAuthorId().equals(userId)) {
            throw new AppException(ErrorCode.CANNOT_VOTE_OWN_CONTENT);
        }

        return video;
    }

    private Optional<ContentVote> findVote(Long userId, TargetType targetType, Long targetId) {

        return contentVoteRepository
                .findByUserIdAndTargetTypeAndTargetId(userId, targetType, targetId);
    }

    private VoteResponse applyBlogDelta(Blog blog, Integer previous, Integer next) {

        int delta = voteDelta(previous, next);

        if (delta != 0) {
            blogRepository.addVoteScore(blog.getId(), delta);
        }

        int current = blog.getVoteScore() == null ? 0 : blog.getVoteScore();
        // The JPQL update bypasses the persistence context, so add the delta here too
        return blogResponse(blog.getId(), next, current + delta);
    }

    private VoteResponse applyVideoDelta(Video video, Integer previous, Integer next) {

        int delta = voteDelta(previous, next);

        if (delta != 0) {
            videoRepository.addVoteScore(video.getId(), delta);
        }

        int current = video.getVoteScore() == null ? 0 : video.getVoteScore();
        return videoResponse(video.getId(), next, current + delta);
    }

    /**
     * The whole delta table in the spec collapses to "new minus old" once
     * "not voted" counts as zero.
     */
    static int voteDelta(Integer previous, Integer next) {

        return (next == null ? 0 : next) - (previous == null ? 0 : previous);
    }

    private static VoteResponse blogResponse(Long blogId, Integer myVote, Integer voteScore) {

        return VoteResponse.builder()
                .blogId(blogId)
                .myVote(myVote)
                .voteScore(voteScore)
                .build();
    }

    private static VoteResponse videoResponse(Long videoId, Integer myVote, Integer voteScore) {

        return VoteResponse.builder()
                .videoId(videoId)
                .myVote(myVote)
                .voteScore(voteScore)
                .build();
    }
}
