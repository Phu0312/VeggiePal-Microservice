package com.veggiepal.service;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import com.veggiepal.dto.response.PageResponse;
import com.veggiepal.dto.response.UserProfileResponse;
import com.veggiepal.entity.User;
import com.veggiepal.enums.Role;
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

    UserRepository userRepository;
    UserMapper userMapper;
    RefreshTokenService refreshTokenService;

    @Transactional(readOnly = true)
    public PageResponse<UserProfileResponse> listUsers(
            String keyword,
            Role role,
            UserStatus status,
            int page,
            int size
    ) {
        int safePage = Math.max(0, page);
        int safeSize = Math.min(Math.max(1, size), 100);
        Pageable pageable = PageRequest.of(safePage, safeSize, Sort.by(Sort.Direction.DESC, "createdAt"));

        String normalizedKeyword = StringUtils.hasText(keyword) ? keyword.trim() : null;
        Page<User> result = userRepository.searchUsers(normalizedKeyword, role, status, pageable);

        return PageResponse.<UserProfileResponse>builder()
                .content(result.getContent().stream().map(userMapper::toUserProfileResponse).toList())
                .page(result.getNumber())
                .size(result.getSize())
                .totalElements(result.getTotalElements())
                .totalPages(result.getTotalPages())
                .first(result.isFirst())
                .last(result.isLast())
                .build();
    }

    @Transactional(readOnly = true)
    public UserProfileResponse getUser(Long id) {
        return userMapper.toUserProfileResponse(findUser(id));
    }

    @Transactional
    public UserProfileResponse updateStatus(Long adminId, Long targetUserId, UserStatus newStatus) {
        User user = findUser(targetUserId);

        if (adminId != null && adminId.equals(targetUserId) && newStatus != UserStatus.ACTIVE) {
            throw new AppException(ErrorCode.CANNOT_MODIFY_SELF);
        }
        if (user.getStatus() == newStatus) {
            throw new AppException(ErrorCode.USER_STATUS_UNCHANGED);
        }

        user.setStatus(newStatus);
        userRepository.save(user);

        if (newStatus != UserStatus.ACTIVE) {
            refreshTokenService.revokeAllForUser(targetUserId);
        }

        return userMapper.toUserProfileResponse(user);
    }

    @Transactional
    public UserProfileResponse updateRole(Long adminId, Long targetUserId, Role newRole) {
        User user = findUser(targetUserId);

        if (adminId != null && adminId.equals(targetUserId) && newRole != Role.ADMIN) {
            throw new AppException(ErrorCode.CANNOT_MODIFY_SELF);
        }
        if (user.getRole() == newRole) {
            throw new AppException(ErrorCode.USER_ROLE_UNCHANGED);
        }

        user.setRole(newRole);
        userRepository.save(user);
        return userMapper.toUserProfileResponse(user);
    }

    private User findUser(Long id) {
        return userRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_EXISTED));
    }
}

