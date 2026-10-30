package com.veggiepal.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;

import com.veggiepal.dto.response.PageResponse;
import com.veggiepal.dto.response.UserProfileResponse;
import com.veggiepal.entity.User;
import com.veggiepal.enums.Role;
import com.veggiepal.enums.UserStatus;
import com.veggiepal.exception.AppException;
import com.veggiepal.exception.ErrorCode;
import com.veggiepal.mapper.UserMapper;
import com.veggiepal.repository.UserRepository;

class AdminUserServiceTest {

    private UserRepository userRepository;
    private UserMapper userMapper;
    private RefreshTokenService refreshTokenService;
    private AdminUserService service;

    @BeforeEach
    void setUp() {
        userRepository = mock(UserRepository.class);
        userMapper = mock(UserMapper.class);
        refreshTokenService = mock(RefreshTokenService.class);
        service = new AdminUserService(userRepository, userMapper, refreshTokenService);
    }

    @Test
    void listUsers_returnsPageWithBothContentAndItems() {
        User u = User.builder().id(2L).email("user@veggiepal.com").role(Role.USER).status(UserStatus.ACTIVE).build();
        UserProfileResponse dto = UserProfileResponse.builder().id(2L).email("user@veggiepal.com").build();
        when(userRepository.searchUsers(eq("user"), eq(null), eq(null), any(Pageable.class)))
                .thenReturn(new PageImpl<>(List.of(u)));
        when(userMapper.toUserProfileResponse(u)).thenReturn(dto);

        PageResponse<UserProfileResponse> page = service.listUsers(" user ", null, null, 0, 20);

        assertThat(page.getContent()).hasSize(1);
        assertThat(page.getItems()).hasSize(1);
    }

    @Test
    void updateStatus_blocksUserAndRevokesRefreshTokens() {
        User target = User.builder().id(2L).role(Role.USER).status(UserStatus.ACTIVE).build();
        when(userRepository.findById(2L)).thenReturn(Optional.of(target));
        when(userMapper.toUserProfileResponse(target))
                .thenReturn(UserProfileResponse.builder().id(2L).status(UserStatus.BLOCKED).build());

        UserProfileResponse updated = service.updateStatus(1L, 2L, UserStatus.BLOCKED);

        assertThat(updated.getStatus()).isEqualTo(UserStatus.BLOCKED);
        assertThat(target.getStatus()).isEqualTo(UserStatus.BLOCKED);
        verify(refreshTokenService).revokeAllForUser(2L);
    }

    @Test
    void updateStatus_rejectsSelfBlockAndUnchangedStatus() {
        User admin = User.builder().id(1L).role(Role.ADMIN).status(UserStatus.ACTIVE).build();
        when(userRepository.findById(1L)).thenReturn(Optional.of(admin));

        assertThatThrownBy(() -> service.updateStatus(1L, 1L, UserStatus.BLOCKED))
                .isInstanceOfSatisfying(AppException.class,
                        e -> assertThat(e.getErrorCode()).isEqualTo(ErrorCode.CANNOT_MODIFY_SELF));

        assertThatThrownBy(() -> service.updateStatus(1L, 1L, UserStatus.ACTIVE))
                .isInstanceOfSatisfying(AppException.class,
                        e -> assertThat(e.getErrorCode()).isEqualTo(ErrorCode.USER_STATUS_UNCHANGED));
        verify(userRepository, never()).save(any());
    }

    @Test
    void updateRole_promotesUserAndRejectsSelfDemote() {
        User admin = User.builder().id(1L).role(Role.ADMIN).status(UserStatus.ACTIVE).build();
        User member = User.builder().id(2L).role(Role.USER).status(UserStatus.ACTIVE).build();
        when(userRepository.findById(1L)).thenReturn(Optional.of(admin));
        when(userRepository.findById(2L)).thenReturn(Optional.of(member));
        when(userMapper.toUserProfileResponse(member))
                .thenReturn(UserProfileResponse.builder().id(2L).role(Role.ADMIN).build());

        assertThatThrownBy(() -> service.updateRole(1L, 1L, Role.USER))
                .isInstanceOfSatisfying(AppException.class,
                        e -> assertThat(e.getErrorCode()).isEqualTo(ErrorCode.CANNOT_MODIFY_SELF));

        UserProfileResponse promoted = service.updateRole(1L, 2L, Role.ADMIN);
        assertThat(promoted.getRole()).isEqualTo(Role.ADMIN);
        assertThat(member.getRole()).isEqualTo(Role.ADMIN);
    }
}

