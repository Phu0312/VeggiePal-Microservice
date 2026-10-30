package com.veggiepal.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.veggiepal.entity.UserFavorite;
import com.veggiepal.enums.FavoriteTargetType;

@Repository
public interface UserFavoriteRepository extends JpaRepository<UserFavorite, Long> {

    List<UserFavorite> findByUserIdOrderByCreatedAtDesc(Long userId);

    List<UserFavorite> findByUserIdAndTargetTypeOrderByCreatedAtDesc(Long userId, FavoriteTargetType targetType);

    Optional<UserFavorite> findByUserIdAndTargetTypeAndTargetId(
            Long userId,
            FavoriteTargetType targetType,
            Long targetId
    );
}

