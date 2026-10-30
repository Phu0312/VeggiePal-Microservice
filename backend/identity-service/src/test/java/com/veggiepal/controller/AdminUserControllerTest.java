package com.veggiepal.controller;

import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.List;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.RequestPostProcessor;

import com.veggiepal.configuration.JwtConfig;
import com.veggiepal.configuration.SecurityConfig;
import com.veggiepal.configuration.SecurityExceptionHandler;
import com.veggiepal.dto.response.PageResponse;
import com.veggiepal.dto.response.UserProfileResponse;
import com.veggiepal.entity.User;
import com.veggiepal.enums.Role;
import com.veggiepal.enums.UserStatus;
import com.veggiepal.exception.GlobalExceptionHandler;
import com.veggiepal.service.AdminUserService;
import com.veggiepal.service.JwtService;

@WebMvcTest(AdminUserController.class)
@Import({
        SecurityConfig.class,
        JwtConfig.class,
        JwtService.class,
        SecurityExceptionHandler.class,
        GlobalExceptionHandler.class
})
class AdminUserControllerTest {

    @Autowired
    MockMvc mockMvc;

    @Autowired
    JwtService jwtService;

    @MockitoBean
    AdminUserService adminUserService;

    static RequestPostProcessor adminJwt() {
        return jwt()
                .jwt(token -> token.claim("userId", 1L).claim("role", "ADMIN"))
                .authorities(new SimpleGrantedAuthority("ROLE_ADMIN"));
    }

    static RequestPostProcessor userJwt() {
        return jwt()
                .jwt(token -> token.claim("userId", 2L).claim("role", "USER"))
                .authorities(new SimpleGrantedAuthority("ROLE_USER"));
    }

    @Test
    void nonAdminIsRejectedWith403Code1009() throws Exception {
        mockMvc.perform(get("/admin/users").with(userJwt()))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value(1009));
    }

    @Test
    void unauthenticatedIsRejectedWith401Code1008() throws Exception {
        mockMvc.perform(get("/admin/users"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value(1008));
    }

    @Test
    void signedBearerTokenMapsRoleClaimThroughJwtAuthenticationConverter() throws Exception {
        User admin = new User();
        admin.setId(1L);
        admin.setEmail("admin@veggiepal.com");
        admin.setRole(Role.ADMIN);

        User regularUser = new User();
        regularUser.setId(2L);
        regularUser.setEmail("user@veggiepal.com");
        regularUser.setRole(Role.USER);

        UserProfileResponse userDto = UserProfileResponse.builder()
                .id(2L)
                .email("user@veggiepal.com")
                .role(Role.USER)
                .status(UserStatus.ACTIVE)
                .build();
        when(adminUserService.getUser(2L)).thenReturn(userDto);

        mockMvc.perform(get("/admin/users/2")
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + jwtService.generateToken(admin)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.id").value(2));

        mockMvc.perform(get("/admin/users/2")
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + jwtService.generateToken(regularUser)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value(1009));
    }

    @Test
    void adminCanListViewAndUpdateUserStatusAndRole() throws Exception {
        UserProfileResponse userDto = UserProfileResponse.builder()
                .id(2L)
                .email("user@veggiepal.com")
                .fullName("VeggiePal User")
                .role(Role.USER)
                .status(UserStatus.ACTIVE)
                .build();
        PageResponse<UserProfileResponse> page = PageResponse.<UserProfileResponse>builder()
                .content(List.of(userDto))
                .page(0)
                .size(20)
                .totalElements(1)
                .totalPages(1)
                .first(true)
                .last(true)
                .build();

        when(adminUserService.listUsers("veggie", null, null, 0, 20)).thenReturn(page);
        when(adminUserService.getUser(2L)).thenReturn(userDto);
        when(adminUserService.updateStatus(1L, 2L, UserStatus.BLOCKED))
                .thenReturn(UserProfileResponse.builder().id(2L).status(UserStatus.BLOCKED).build());
        when(adminUserService.updateRole(1L, 2L, Role.ADMIN))
                .thenReturn(UserProfileResponse.builder().id(2L).role(Role.ADMIN).build());

        mockMvc.perform(get("/admin/users").param("keyword", "veggie").with(adminJwt()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.items[0].id").value(2))
                .andExpect(jsonPath("$.result.content[0].email").value("user@veggiepal.com"));

        mockMvc.perform(get("/admin/users/2").with(adminJwt()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.id").value(2));

        mockMvc.perform(patch("/admin/users/2/status")
                        .with(adminJwt())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"status\":\"BLOCKED\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.status").value("BLOCKED"));

        mockMvc.perform(patch("/admin/users/2/role")
                        .with(adminJwt())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"role\":\"ADMIN\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.role").value("ADMIN"));
    }
}
