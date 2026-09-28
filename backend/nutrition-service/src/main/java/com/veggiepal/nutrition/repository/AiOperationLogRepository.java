package com.veggiepal.nutrition.repository;

import java.util.List;

import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.veggiepal.nutrition.entity.AiOperationLog;

@Repository
public interface AiOperationLogRepository extends JpaRepository<AiOperationLog, Long> {

    List<AiOperationLog> findAllByOrderByCreatedAtDesc(Pageable pageable);

    long countByOperationType(String operationType);

    long countByStatus(String status);

    long countByOperationTypeAndStatus(String operationType, String status);
}
