package com.veggiepal.service;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;

import com.veggiepal.dto.response.UserProfileResponse;
import com.veggiepal.entity.User;
import com.veggiepal.enums.UserStatus;
import com.veggiepal.exception.AppException;
import com.veggiepal.exception.ErrorCode;
import com.veggiepal.mapper.UserMapper;
import com.veggiepal.repository.UserRepository;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class AdminUserService {

    private static final int MAX_PAGE_SIZE = 100;

    UserRepository userRepository;
    UserMapper userMapper;

    public Page<UserProfileResponse> getUsers(String keyword, int page, int size) {

        int safeSize = Math.min(Math.max(size, 1), MAX_PAGE_SIZE);
        int safePage = Math.max(page, 0);

        String normalizedKeyword = keyword == null || keyword.isBlank() ? null : keyword.trim();

        Page<User> users = userRepository.searchUsers(
                normalizedKeyword,
                PageRequest.of(safePage, safeSize, Sort.by(Sort.Order.desc("createdAt")))
        );

        return users.map(userMapper::toUserProfileResponse);
    }

    public UserProfileResponse getUser(Long userId) {

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_EXISTED));

        return userMapper.toUserProfileResponse(user);
    }

    public UserProfileResponse updateUserStatus(Long userId, UserStatus status) {

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_EXISTED));

        if (user.getStatus() == status) {
            throw new AppException(ErrorCode.USER_ALREADY_HAS_STATUS);
        }

        user.setStatus(status);
        userRepository.save(user);

        return userMapper.toUserProfileResponse(user);
    }
}
