package com.veggiepal.blog.repository;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.veggiepal.blog.entity.Video;
import com.veggiepal.blog.enums.ContentStatus;

@Repository
public interface VideoRepository extends JpaRepository<Video, Long> {

    Page<Video> findByStatus(ContentStatus status, Pageable pageable);

    Page<Video> findByAuthorId(Long authorId, Pageable pageable);

    Page<Video> findByAuthorIdAndStatus(Long authorId, ContentStatus status, Pageable pageable);

    @Query("SELECT v FROM Video v WHERE v.status = :status AND "
            + "(:categoryId IS NULL OR v.category.id = :categoryId) AND "
            + "(:keyword IS NULL OR LOWER(v.title) LIKE LOWER(CONCAT('%', :keyword, '%')) "
            + "OR LOWER(v.description) LIKE LOWER(CONCAT('%', :keyword, '%')))")
    Page<Video> searchVideos(
            @Param("status") ContentStatus status,
            @Param("categoryId") Long categoryId,
            @Param("keyword") String keyword,
            Pageable pageable
    );
}
