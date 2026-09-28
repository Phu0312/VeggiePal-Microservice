package com.veggiepal.moderation.service;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.veggiepal.moderation.dto.request.ReviewModerationRequest;
import com.veggiepal.moderation.dto.response.ModerationResult;
import com.veggiepal.moderation.entity.ModerationCase;
import com.veggiepal.moderation.enums.ModerationDecision;
import com.veggiepal.moderation.enums.TargetType;
import com.veggiepal.moderation.exception.AppException;
import com.veggiepal.moderation.exception.ErrorCode;
import com.veggiepal.moderation.repository.ModerationCaseRepository;

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
    ContentModerationService contentModerationService;

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

    public ModerationResult checkContent(String text, TargetType targetType, Long targetId, Long authorId) {
        ModerationResult result = contentModerationService.moderate(text);
        if (result.decision() != ModerationDecision.APPROVED && targetId != null) {
            recordCase(targetType != null ? targetType : TargetType.BLOG, targetId, authorId != null ? authorId : 0L, text, result);
        }
        return result;
    }

    public List<ModerationCase> getQueue(ModerationDecision status) {
        return status != null
                ? moderationCaseRepository.findByDecisionOrderByCreatedAtDesc(status)
                : moderationCaseRepository.findAllByOrderByCreatedAtDesc();
    }

    public ModerationCase getCaseById(Long id) {
        return moderationCaseRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.MODERATION_CASE_NOT_FOUND));
    }

    @Transactional
    public ModerationCase reviewCase(Long adminId, Long id, ReviewModerationRequest request) {
        ModerationCase moderationCase = moderationCaseRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.MODERATION_CASE_NOT_FOUND));

        moderationCase.setDecision(request.getDecision());
        if (request.getReason() != null && !request.getReason().isBlank()) {
            moderationCase.setReason(request.getReason());
        }
        moderationCase.setReviewedBy(adminId);
        moderationCase.setReviewedAt(LocalDateTime.now());

        log.info("Admin {} reviewed case {}: decision={}", adminId, id, request.getDecision());
        return moderationCaseRepository.save(moderationCase);
    }
}
