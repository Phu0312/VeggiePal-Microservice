package com.veggiepal.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.veggiepal.entity.UserBadge;
import com.veggiepal.enums.BadgeCode;

@Repository
public interface UserBadgeRepository extends JpaRepository<UserBadge, Long> {

    List<UserBadge> findByUserId(Long userId);

    Optional<UserBadge> findByUserIdAndBadgeCode(Long userId, BadgeCode badgeCode);
}

