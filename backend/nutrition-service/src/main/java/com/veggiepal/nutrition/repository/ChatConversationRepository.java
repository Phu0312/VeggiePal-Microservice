package com.veggiepal.nutrition.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.veggiepal.nutrition.entity.ChatConversation;

@Repository
public interface ChatConversationRepository extends JpaRepository<ChatConversation, Long> {

    List<ChatConversation> findByUserIdOrderByUpdatedAtDesc(Long userId);

    java.util.Optional<ChatConversation> findByIdAndUserId(Long id, Long userId);
}
