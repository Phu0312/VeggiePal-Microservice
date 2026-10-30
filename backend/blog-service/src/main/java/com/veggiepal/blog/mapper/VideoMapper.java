package com.veggiepal.blog.mapper;

import org.mapstruct.AfterMapping;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingTarget;

import com.veggiepal.blog.dto.response.VideoNutritionResponse;
import com.veggiepal.blog.dto.response.VideoResponse;
import com.veggiepal.blog.entity.Video;

@Mapper(componentModel = "spring")
public interface VideoMapper {

    @Mapping(target = "categoryId", source = "category.id")
    @Mapping(target = "categoryName", source = "category.name")
    @Mapping(target = "moderationReason", ignore = true)
    @Mapping(target = "nutrition", ignore = true)
    VideoResponse toVideoResponse(Video video);

    @AfterMapping
    default void attachNutrition(Video video, @MappingTarget VideoResponse response) {
        response.setNutrition(VideoNutritionResponse.fromVideo(video));
    }
}
