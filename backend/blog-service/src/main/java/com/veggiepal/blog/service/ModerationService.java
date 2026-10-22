package com.veggiepal.blog.service;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.veggiepal.blog.entity.Blog;
import com.veggiepal.blog.entity.ModerationCase;
import com.veggiepal.blog.enums.ContentStatus;
import com.veggiepal.blog.enums.TargetType;
import com.veggiepal.blog.exception.AppException;
import com.veggiepal.blog.exception.ErrorCode;
import com.veggiepal.blog.moderation.ModerationDecision;
import com.veggiepal.blog.moderation.ModerationResult;
import com.veggiepal.blog.repository.BlogRepository;
import com.veggiepal.blog.repository.ModerationCaseRepository;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import lombok.extern.slf4j.Slf4j;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
@Slf4j
public class ModerationService {

    ModerationCaseRepository moderationCaseRepository;
    BlogRepository blogRepository;

    @Transactional
    public ModerationCase recordCase(
            TargetType targetType,
            Long targetId,
            Long authorId,
            String contentSnippet,
            ModerationResult result
    ) {
        String snippet = contentSnippet != null && contentSnippet.length() > 450
                ? contentSnippet.substring(0, 450) + "..."
                : contentSnippet;

        ModerationCase moderationCase = ModerationCase.builder()
                .targetType(targetType)
                .targetId(targetId)
                .authorId(authorId)
                .contentSnippet(snippet)
                .matchedKeywords(result.matchedKeywords())
                .decision(result.decision())
                .reason(result.reason())
                .build();

        return moderationCaseRepository.save(moderationCase);
    }

    public List<ModerationCase> getQueue(ModerationDecision status) {
        if (status != null) {
            return moderationCaseRepository.findByDecisionOrderByCreatedAtDesc(status);
        }
        return moderationCaseRepository.findAllByOrderByCreatedAtDesc();
    }

    public ModerationCase getCaseById(Long caseId) {
        return moderationCaseRepository.findById(caseId)
                .orElseThrow(() -> new AppException(ErrorCode.MODERATION_CASE_NOT_FOUND));
    }

    @Transactional
    public ModerationCase reviewCase(Long adminId, Long caseId, ModerationDecision newDecision, String reviewNote) {
        ModerationCase moderationCase = getCaseById(caseId);

        moderationCase.setDecision(newDecision);
        moderationCase.setReviewedBy(adminId);
        moderationCase.setReviewedAt(LocalDateTime.now());
        if (reviewNote != null && !reviewNote.isBlank()) {
            moderationCase.setReason(reviewNote);
        }

        // Propagate decision to the underlying entity
        if (moderationCase.getTargetType() == TargetType.BLOG) {
            blogRepository.findById(moderationCase.getTargetId()).ifPresent(blog -> {
                if (newDecision == ModerationDecision.APPROVED) {
                    blog.setStatus(ContentStatus.PUBLISHED);
                    if (blog.getPublishedAt() == null) {
                        blog.setPublishedAt(LocalDateTime.now());
                    }
                } else if (newDecision == ModerationDecision.REJECTED) {
                    blog.setStatus(ContentStatus.REJECTED);
                }
                blogRepository.save(blog);
                log.info("Blog {} status updated to {} by admin {}", blog.getId(), blog.getStatus(), adminId);
            });
        }

        return moderationCaseRepository.save(moderationCase);
    }
}
