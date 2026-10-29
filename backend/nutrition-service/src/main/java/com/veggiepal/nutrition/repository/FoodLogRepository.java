package com.veggiepal.nutrition.repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.veggiepal.nutrition.entity.FoodLog;

@Repository
public interface FoodLogRepository extends JpaRepository<FoodLog, Long> {

    List<FoodLog> findByUserIdAndLogDateOrderByCreatedAtAsc(Long userId, LocalDate logDate);

    Optional<FoodLog> findByIdAndUserId(Long id, Long userId);
}

