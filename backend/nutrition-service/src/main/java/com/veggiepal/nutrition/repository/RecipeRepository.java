package com.veggiepal.nutrition.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.veggiepal.nutrition.entity.Recipe;

@Repository
public interface RecipeRepository extends JpaRepository<Recipe, Long> {

    List<Recipe> findByVeganTrue();

    @Query("SELECT r FROM Recipe r WHERE r.vegan = true AND r.allergenCodes NOT LIKE CONCAT('%', :code, '%')")
    List<Recipe> findVeganExcludingAllergen(@Param("code") String code);

    @Query("SELECT r FROM Recipe r WHERE r.vegan = true AND "
            + "(:keyword IS NULL OR LOWER(r.name) LIKE LOWER(CONCAT('%', :keyword, '%')) "
            + "OR LOWER(r.ingredients) LIKE LOWER(CONCAT('%', :keyword, '%')))")
    List<Recipe> searchRecipes(@Param("keyword") String keyword);
}
