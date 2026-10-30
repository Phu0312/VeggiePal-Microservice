package com.veggiepal.repository;

import java.util.Optional;
import java.time.LocalDateTime;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.veggiepal.entity.UserOtp;
import com.veggiepal.enums.OtpPurpose;

@Repository
public interface UserOtpRepository extends JpaRepository<UserOtp, Long> {

    Optional<UserOtp> findFirstByEmailAndPurposeAndUsedFalseOrderByCreatedAtDesc(
            String email,
            OtpPurpose purpose
    );

    Optional<UserOtp> findFirstByResetTokenAndPurposeAndUsedFalse(
            String resetToken,
            OtpPurpose purpose
    );

    @Query("select coalesce(sum(o.attempts), 0) from UserOtp o where o.email = :email and o.createdAt >= :since")
    long countFailedAttemptsSince(@Param("email") String email, @Param("since") LocalDateTime since);

    @Modifying
    @Query("update UserOtp o set o.used = true where o.userId = :userId and o.purpose = :purpose and o.used = false")
    int invalidateActiveOtps(
            @Param("userId") Long userId,
            @Param("purpose") OtpPurpose purpose
    );
}

