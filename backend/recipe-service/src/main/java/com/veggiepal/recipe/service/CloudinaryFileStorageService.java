package com.veggiepal.recipe.service;

import java.io.IOException;
import java.util.Map;
import java.util.Objects;

import org.springframework.stereotype.Service;

import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import com.veggiepal.recipe.configuration.StorageProperties;
import com.veggiepal.recipe.exception.AppException;
import com.veggiepal.recipe.exception.ErrorCode;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import lombok.extern.slf4j.Slf4j;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
@Slf4j
public class CloudinaryFileStorageService implements FileStorageService {

    private static final String IMAGE = "image";

    Cloudinary cloudinary;
    StorageProperties storageProperties;

    @Override
    public String upload(String key, byte[] content, String contentType) {
        Map<?, ?> options = ObjectUtils.asMap(
                "public_id", stripExtension(key),
                "resource_type", IMAGE,
                "overwrite", false
        );

        try {
            Map<?, ?> result = cloudinary.uploader().upload(content, options);
            return Objects.requireNonNull((String) result.get("secure_url"), "Cloudinary response has no secure_url");
        } catch (IOException | RuntimeException exception) {
            log.error("Could not upload recipe image to Cloudinary", exception);
            throw new AppException(ErrorCode.FILE_UPLOAD_FAILED);
        }
    }

    @Override
    public void delete(String url) {
        if (url == null || storageProperties.cloudName() == null || storageProperties.cloudName().isBlank()) {
            return;
        }

        String prefix = uploadUrlPrefix();
        if (!url.startsWith(prefix)) {
            return;
        }

        String publicId = stripExtension(url.substring(prefix.length()).replaceFirst("^v\\d+/", ""));
        try {
            cloudinary.uploader().destroy(publicId, ObjectUtils.asMap(
                    "resource_type", IMAGE,
                    "invalidate", true
            ));
        } catch (IOException | RuntimeException exception) {
            log.error("Could not delete recipe image from Cloudinary", exception);
            throw new AppException(ErrorCode.FILE_UPLOAD_FAILED);
        }
    }

    private String uploadUrlPrefix() {
        return "https://res.cloudinary.com/" + storageProperties.cloudName() + "/image/upload/";
    }

    private static String stripExtension(String path) {
        int dot = path.lastIndexOf('.');
        return dot > path.lastIndexOf('/') ? path.substring(0, dot) : path;
    }
}

