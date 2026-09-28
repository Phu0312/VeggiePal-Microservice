package com.veggiepal.video.service;

import java.time.LocalDateTime;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.veggiepal.video.dto.request.VideoRequest;
import com.veggiepal.video.dto.response.PageResponse;
import com.veggiepal.video.dto.response.VideoResponse;
import com.veggiepal.video.dto.response.VideoSummaryResponse;
import com.veggiepal.video.entity.Video;
import com.veggiepal.video.enums.ContentStatus;
import com.veggiepal.video.exception.AppException;
import com.veggiepal.video.exception.ErrorCode;
import com.veggiepal.video.repository.VideoRepository;

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
    VideoSummarizationService videoSummarizationService;

    @Transactional
    public VideoResponse createVideo(Long authorId, VideoRequest request) {
        Video video = Video.builder()
                .authorId(authorId)
                .categoryId(request.getCategoryId())
                .categoryName(request.getCategoryName() != null ? request.getCategoryName() : "Món Chay Dinh Dưỡng")
                .title(request.getTitle().trim())
                .description(request.getDescription())
                .videoUrl(request.getVideoUrl().trim())
                .thumbnailUrl(request.getThumbnailUrl())
                .durationSeconds(request.getDurationSeconds())
                .status(ContentStatus.DRAFT)
                .viewCount(0)
                .voteScore(0)
                .build();

        if (Boolean.TRUE.equals(request.getPublish())) {
            video.setStatus(ContentStatus.PUBLISHED);
            video.setPublishedAt(LocalDateTime.now());
        }

        video = videoRepository.save(video);
        return toVideoResponse(video);
    }

    public PageResponse<VideoSummaryResponse> getPublishedVideos(Long categoryId, String keyword, int page, int size) {
        int boundedSize = Math.clamp(size, 1, MAX_PAGE_SIZE);
        int zeroBasedPage = Math.max(page, 0);

        Page<Video> videoPage = videoRepository.searchVideos(
                ContentStatus.PUBLISHED,
                categoryId,
                keyword,
                PageRequest.of(zeroBasedPage, boundedSize, RECENTLY_PUBLISHED_FIRST)
        );

        return PageResponse.<VideoSummaryResponse>builder()
                .items(videoPage.getContent().stream().map(this::toSummaryResponse).toList())
                .page(zeroBasedPage)
                .size(boundedSize)
                .totalElements(videoPage.getTotalElements())
                .totalPages(videoPage.getTotalPages())
                .build();
    }

    public PageResponse<VideoSummaryResponse> getOwnVideos(Long authorId, ContentStatus status, int page, int size) {
        int boundedSize = Math.clamp(size, 1, MAX_PAGE_SIZE);
        int zeroBasedPage = Math.max(page, 0);

        Page<Video> videoPage = status == null
                ? videoRepository.findByAuthorId(authorId, PageRequest.of(zeroBasedPage, boundedSize, Sort.by(Sort.Order.desc("id"))))
                : videoRepository.findByAuthorIdAndStatus(authorId, status, PageRequest.of(zeroBasedPage, boundedSize, Sort.by(Sort.Order.desc("id"))));

        return PageResponse.<VideoSummaryResponse>builder()
                .items(videoPage.getContent().stream().map(this::toSummaryResponse).toList())
                .page(zeroBasedPage)
                .size(boundedSize)
                .totalElements(videoPage.getTotalElements())
                .totalPages(videoPage.getTotalPages())
                .build();
    }

    @Transactional
    public VideoResponse getVideoDetail(Long id) {
        Video video = videoRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.VIDEO_NOT_EXISTED));

        video.setViewCount(video.getViewCount() + 1);
        video = videoRepository.save(video);

        return toVideoResponse(video);
    }

    @Transactional
    public VideoResponse updateVideo(Long currentUserId, Long id, VideoRequest request) {
        Video video = videoRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.VIDEO_NOT_EXISTED));

        if (!video.getAuthorId().equals(currentUserId)) {
            throw new AppException(ErrorCode.UNAUTHORIZED);
        }

        if (video.getStatus() == ContentStatus.BANNED) {
            throw new AppException(ErrorCode.INVALID_VIDEO_STATUS_TRANSITION);
        }

        video.setTitle(request.getTitle().trim());
        video.setDescription(request.getDescription());
        video.setVideoUrl(request.getVideoUrl().trim());
        video.setThumbnailUrl(request.getThumbnailUrl());
        video.setDurationSeconds(request.getDurationSeconds());
        video.setCategoryId(request.getCategoryId());
        if (request.getCategoryName() != null) {
            video.setCategoryName(request.getCategoryName());
        }

        if (Boolean.TRUE.equals(request.getPublish()) && video.getStatus() == ContentStatus.DRAFT) {
            video.setStatus(ContentStatus.PUBLISHED);
            video.setPublishedAt(LocalDateTime.now());
        }

        video = videoRepository.save(video);
        return toVideoResponse(video);
    }

    @Transactional
    public void deleteVideo(Long currentUserId, Long id) {
        Video video = videoRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.VIDEO_NOT_EXISTED));

        if (!video.getAuthorId().equals(currentUserId)) {
            throw new AppException(ErrorCode.UNAUTHORIZED);
        }

        videoRepository.delete(video);
    }

    @Transactional
    public VideoResponse summarizeVideo(Long currentUserId, Long id) {
        Video video = videoRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.VIDEO_NOT_EXISTED));

        String summary = videoSummarizationService.generateSummary(video);
        video.setSummary(summary);
        video = videoRepository.save(video);

        return toVideoResponse(video);
    }

    private VideoResponse toVideoResponse(Video video) {
        return VideoResponse.builder()
                .id(video.getId())
                .authorId(video.getAuthorId())
                .categoryId(video.getCategoryId())
                .categoryName(video.getCategoryName())
                .title(video.getTitle())
                .description(video.getDescription())
                .videoUrl(video.getVideoUrl())
                .thumbnailUrl(video.getThumbnailUrl())
                .durationSeconds(video.getDurationSeconds())
                .summary(video.getSummary())
                .status(video.getStatus())
                .viewCount(video.getViewCount())
                .voteScore(video.getVoteScore())
                .publishedAt(video.getPublishedAt())
                .createdAt(video.getCreatedAt())
                .updatedAt(video.getUpdatedAt())
                .moderationReason(video.getModerationReason())
                .build();
    }

    private VideoSummaryResponse toSummaryResponse(Video video) {
        return VideoSummaryResponse.builder()
                .id(video.getId())
                .authorId(video.getAuthorId())
                .categoryId(video.getCategoryId())
                .categoryName(video.getCategoryName())
                .title(video.getTitle())
                .videoUrl(video.getVideoUrl())
                .thumbnailUrl(video.getThumbnailUrl())
                .durationSeconds(video.getDurationSeconds())
                .status(video.getStatus())
                .viewCount(video.getViewCount())
                .voteScore(video.getVoteScore())
                .publishedAt(video.getPublishedAt())
                .build();
    }
}
