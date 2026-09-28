package com.veggiepal.nutrition.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.veggiepal.nutrition.entity.GuestAiUsage;

@Repository
public interface GuestAiUsageRepository extends JpaRepository<GuestAiUsage, Long> {

    Optional<GuestAiUsage> findByGuestId(String guestId);
}
