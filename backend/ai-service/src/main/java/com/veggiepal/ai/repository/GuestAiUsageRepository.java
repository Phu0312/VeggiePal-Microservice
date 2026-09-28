package com.veggiepal.ai.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.veggiepal.ai.entity.GuestAiUsage;

@Repository
public interface GuestAiUsageRepository extends JpaRepository<GuestAiUsage, Long> {

    Optional<GuestAiUsage> findByGuestId(String guestId);
}
