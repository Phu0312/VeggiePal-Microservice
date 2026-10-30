package com.veggiepal.blog.repository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.veggiepal.blog.entity.UserFollow;

@Repository
public interface UserFollowRepository extends JpaRepository<UserFollow, Long> {

    Optional<UserFollow> findByFollowerIdAndFolloweeId(Long followerId, Long followeeId);

    List<UserFollow> findByFollowerIdOrderByCreatedAtDesc(Long followerId);

    long countByFolloweeId(Long followeeId);

    @Query("""
            select f.followeeId as followeeId, count(f) as total
            from UserFollow f
            where f.followeeId in :followeeIds
            group by f.followeeId
            """)
    List<FollowerCount> countByFolloweeIds(@Param("followeeIds") Collection<Long> followeeIds);

    interface FollowerCount {
        Long getFolloweeId();

        Long getTotal();
    }
}

