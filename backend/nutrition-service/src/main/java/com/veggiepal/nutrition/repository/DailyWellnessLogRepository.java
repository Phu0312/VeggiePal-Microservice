package com.veggiepal.nutrition.repository;

import java.time.LocalDate;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.veggiepal.nutrition.entity.DailyWellnessLog;

@Repository
public interface DailyWellnessLogRepository extends JpaRepository<DailyWellnessLog, Long> {

    Optional<DailyWellnessLog> findByUserIdAndLogDate(Long userId, LocalDate logDate);
}

