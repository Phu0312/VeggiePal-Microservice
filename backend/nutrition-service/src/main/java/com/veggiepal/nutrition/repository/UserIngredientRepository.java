package com.veggiepal.nutrition.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.veggiepal.nutrition.entity.UserIngredient;

@Repository
public interface UserIngredientRepository extends JpaRepository<UserIngredient, Long> {

    List<UserIngredient> findByUserId(Long userId);

    java.util.Optional<UserIngredient> findByIdAndUserId(Long id, Long userId);

    void deleteByIdAndUserId(Long id, Long userId);
}
