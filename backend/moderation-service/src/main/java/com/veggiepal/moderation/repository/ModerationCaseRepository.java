package com.veggiepal.moderation.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.veggiepal.moderation.entity.ModerationCase;
import com.veggiepal.moderation.enums.ModerationDecision;
import com.veggiepal.moderation.enums.TargetType;

@Repository
public interface ModerationCaseRepository extends JpaRepository<ModerationCase, Long> {

    List<ModerationCase> findByDecisionOrderByCreatedAtDesc(ModerationDecision decision);

    List<ModerationCase> findAllByOrderByCreatedAtDesc();

    Optional<ModerationCase> findTopByTargetTypeAndTargetIdOrderByCreatedAtDesc(TargetType targetType, Long targetId);

    long countByDecision(ModerationDecision decision);
}
