package com.veggiepal.recipe.repository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.veggiepal.recipe.entity.RecipeLike;

@Repository
public interface RecipeLikeRepository extends JpaRepository<RecipeLike, Long> {

    Optional<RecipeLike> findByUserIdAndRecipeId(Long userId, Long recipeId);

    List<RecipeLike> findByUserIdAndRecipeIdIn(Long userId, Collection<Long> recipeIds);

    int deleteByUserIdAndRecipeId(Long userId, Long recipeId);
}

