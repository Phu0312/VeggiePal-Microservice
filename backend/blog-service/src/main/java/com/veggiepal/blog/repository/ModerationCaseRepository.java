package com.veggiepal.blog.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.veggiepal.blog.entity.ModerationCase;
import com.veggiepal.blog.enums.TargetType;
import com.veggiepal.blog.moderation.ModerationDecision;

@Repository
public interface ModerationCaseRepository extends JpaRepository<ModerationCase, Long> {

    List<ModerationCase> findByDecisionOrderByCreatedAtDesc(ModerationDecision decision);

    List<ModerationCase> findAllByOrderByCreatedAtDesc();

    Optional<ModerationCase> findTopByTargetTypeAndTargetIdOrderByCreatedAtDesc(TargetType targetType, Long targetId);

    long countByDecision(ModerationDecision decision);
}
