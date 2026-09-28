package com.veggiepal.blog.service;

import java.time.LocalDateTime;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.veggiepal.blog.dto.request.VideoRequest;
import com.veggiepal.blog.dto.response.PageResponse;
import com.veggiepal.blog.dto.response.VideoResponse;
import com.veggiepal.blog.dto.response.VideoSummaryResponse;
import com.veggiepal.blog.entity.Video;
import com.veggiepal.blog.enums.ContentStatus;
import com.veggiepal.blog.enums.TargetType;
import com.veggiepal.blog.exception.AppException;
import com.veggiepal.blog.exception.ErrorCode;
import com.veggiepal.blog.mapper.VideoMapper;
import com.veggiepal.blog.moderation.ContentModerationService;
import com.veggiepal.blog.moderation.ModerationDecision;
import com.veggiepal.blog.moderation.ModerationResult;
import com.veggiepal.blog.repository.VideoRepository;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class VideoService {

    static final int MAX_PAGE_SIZE = 50;
    static final Sort RECENTLY_PUBLISHED_FIRST =
            Sort.by(Sort.Order.desc("publishedAt"), Sort.Order.desc("id"));

    VideoRepository videoRepository;
    CategoryService categoryService;
    ContentModerationService contentModerationService;
    VideoSummarizationService videoSummarizationService;
    ModerationService moderationService;
    VideoMapper videoMapper;

    @Transactional
    public VideoResponse createVideo(Long authorId, VideoRequest request) {
        Video video = Video.builder()
                .authorId(authorId)
                .category(categoryService.requireActiveCategory(request.getCategoryId()))
                .title(request.getTitle().trim())
                .description(request.getDescription())
                .videoUrl(request.getVideoUrl().trim())
                .thumbnailUrl(request.getThumbnailUrl())
                .durationSeconds(request.getDurationSeconds())
                .status(ContentStatus.DRAFT)
                .viewCount(0)
                .voteScore(0)
                .build();

        // Generate AI cooking summary automatically
        video.setSummary(videoSummarizationService.generateSummary(video));

        String reason = null;
        if (Boolean.TRUE.equals(request.getPublish())) {
            ModerationResult result = contentModerationService.moderate(
                    video.getTitle() + "\n" + (video.getDescription() != null ? video.getDescription() : "")
            );
            reason = applyModerationResult(video, result);
            videoRepository.save(video);

            if (result.decision() != ModerationDecision.APPROVED) {
                moderationService.recordCase(
                        TargetType.VIDEO,
                        video.getId(),
                        authorId,
                        video.getTitle(),
                        result
                );
            }
        } else {
            videoRepository.save(video);
        }

        return withReason(video, reason);
    }

    @Transactional
    public VideoResponse updateVideo(Long userId, boolean admin, Long videoId, VideoRequest request) {
        Video video = findOwnedVideo(userId, admin, videoId);

        if (video.getStatus() == ContentStatus.BANNED) {
            throw new AppException(ErrorCode.INVALID_VIDEO_STATUS_TRANSITION);
        }

        video.setCategory(categoryService.requireActiveCategory(request.getCategoryId()));
        video.setTitle(request.getTitle().trim());
        video.setDescription(request.getDescription());
        video.setVideoUrl(request.getVideoUrl().trim());
        if (request.getThumbnailUrl() != null) {
            video.setThumbnailUrl(request.getThumbnailUrl());
        }
        if (request.getDurationSeconds() != null) {
            video.setDurationSeconds(request.getDurationSeconds());
        }

        // Regenerate summary on update
        video.setSummary(videoSummarizationService.generateSummary(video));

        String reason = null;
        if (video.getStatus() != ContentStatus.DRAFT) {
            ModerationResult result = contentModerationService.moderate(
                    video.getTitle() + "\n" + (video.getDescription() != null ? video.getDescription() : "")
            );
            reason = applyModerationResult(video, result);
            if (result.decision() != ModerationDecision.APPROVED) {
                moderationService.recordCase(
                        TargetType.VIDEO,
                        video.getId(),
                        video.getAuthorId(),
                        video.getTitle(),
                        result
                );
            }
        }

        videoRepository.save(video);
        return withReason(video, reason);
    }

    @Transactional
    public VideoResponse submitVideo(Long userId, Long videoId) {
        Video video = findOwnedVideo(userId, false, videoId);

        if (video.getStatus() != ContentStatus.DRAFT) {
            throw new AppException(ErrorCode.INVALID_VIDEO_STATUS_TRANSITION);
        }

        categoryService.requireActiveCategory(video.getCategory().getId());

        ModerationResult result = contentModerationService.moderate(
                video.getTitle() + "\n" + (video.getDescription() != null ? video.getDescription() : "")
        );
        String reason = applyModerationResult(video, result);
        videoRepository.save(video);

        if (result.decision() != ModerationDecision.APPROVED) {
            moderationService.recordCase(
                    TargetType.VIDEO,
                    video.getId(),
                    video.getAuthorId(),
                    video.getTitle(),
                    result
            );
        }

        return withReason(video, reason);
    }

    @Transactional
    public void deleteVideo(Long userId, boolean admin, Long videoId) {
        Video video = findOwnedVideo(userId, admin, videoId);

        if (!video.getAuthorId().equals(userId)) {
            video.setStatus(ContentStatus.BANNED);
            videoRepository.save(video);
            return;
        }

        videoRepository.delete(video);
    }

    public PageResponse<VideoSummaryResponse> getPublishedVideos(
            Long categoryId, String keyword, String sort, int page, int size
    ) {
        Sort sortOrder = "popular".equalsIgnoreCase(sort)
                ? Sort.by(Sort.Order.desc("viewCount"), Sort.Order.desc("id"))
                : RECENTLY_PUBLISHED_FIRST;

        PageRequest pageRequest = pageRequest(page, size, sortOrder);

        Page<Video> videos = videoRepository.searchVideos(
                ContentStatus.PUBLISHED, categoryId, keyword, pageRequest
        );

        return toPageResponse(videos);
    }

    @Transactional
    public VideoResponse getPublishedVideo(Long id) {
        Video video = videoRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.VIDEO_NOT_EXISTED));

        if (video.getStatus() != ContentStatus.PUBLISHED) {
            throw new AppException(ErrorCode.VIDEO_NOT_EXISTED);
        }

        video.setViewCount(video.getViewCount() + 1);
        videoRepository.save(video);

        return videoMapper.toVideoResponse(video);
    }

    public Video requirePublishedVideo(Long id) {
        Video video = videoRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.VIDEO_NOT_EXISTED));

        if (video.getStatus() != ContentStatus.PUBLISHED) {
            throw new AppException(ErrorCode.VIDEO_NOT_EXISTED);
        }
        return video;
    }

    public PageResponse<VideoSummaryResponse> getOwnVideos(
            Long userId, ContentStatus status, int page, int size
    ) {
        PageRequest pageRequest = pageRequest(page, size, Sort.by(Sort.Order.desc("id")));
        Page<Video> videos = status != null
                ? videoRepository.findByAuthorIdAndStatus(userId, status, pageRequest)
                : videoRepository.findByAuthorId(userId, pageRequest);

        return toPageResponse(videos);
    }

    @Transactional
    public VideoResponse summarizeVideo(Long videoId) {
        Video video = videoRepository.findById(videoId)
                .orElseThrow(() -> new AppException(ErrorCode.VIDEO_NOT_EXISTED));

        String summary = videoSummarizationService.generateSummary(video);
        video.setSummary(summary);
        videoRepository.save(video);

        return videoMapper.toVideoResponse(video);
    }

    private Video findOwnedVideo(Long userId, boolean admin, Long videoId) {
        Video video = videoRepository.findById(videoId)
                .orElseThrow(() -> new AppException(ErrorCode.VIDEO_NOT_EXISTED));

        if (!admin && !video.getAuthorId().equals(userId)) {
            throw new AppException(ErrorCode.UNAUTHORIZED);
        }

        return video;
    }

    private String applyModerationResult(Video video, ModerationResult result) {
        switch (result.decision()) {
            case APPROVED -> {
                video.setStatus(ContentStatus.PUBLISHED);
                if (video.getPublishedAt() == null) {
                    video.setPublishedAt(LocalDateTime.now());
                }
                return null;
            }
            case REJECTED -> video.setStatus(ContentStatus.REJECTED);
            case PENDING -> video.setStatus(ContentStatus.PENDING);
        }
        return result.reason();
    }

    private VideoResponse withReason(Video video, String reason) {
        VideoResponse response = videoMapper.toVideoResponse(video);
        response.setModerationReason(reason);
        return response;
    }

    static PageRequest pageRequest(int page, int size, Sort sort) {
        int safeSize = Math.min(Math.max(size, 1), MAX_PAGE_SIZE);
        int safePage = Math.min(Math.max(page, 0), Integer.MAX_VALUE / safeSize);
        return PageRequest.of(safePage, safeSize, sort);
    }

    PageResponse<VideoSummaryResponse> toPageResponse(Page<Video> videos) {
        return PageResponse.<VideoSummaryResponse>builder()
                .items(videos.getContent().stream().map(videoMapper::toVideoSummaryResponse).toList())
                .page(videos.getNumber())
                .size(videos.getSize())
                .totalElements(videos.getTotalElements())
                .totalPages(videos.getTotalPages())
                .build();
    }
}
