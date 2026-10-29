package com.veggiepal.controller;

import static org.mockito.Mockito.verifyNoInteractions;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import com.veggiepal.configuration.JwtConfig;
import com.veggiepal.configuration.SecurityConfig;
import com.veggiepal.configuration.SecurityExceptionHandler;
import com.veggiepal.service.UserService;

@WebMvcTest(UserController.class)
@Import({SecurityConfig.class, JwtConfig.class, SecurityExceptionHandler.class})
class UserControllerTest {

    @Autowired
    MockMvc mockMvc;

    @MockitoBean
    UserService userService;

    @Test
    void register_nullPassword_returns400PasswordRequired() throws Exception {
        mockMvc.perform(post("/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"an@example.com\",\"fullName\":\"An Nguyen\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(1010));
        verifyNoInteractions(userService);
    }

    @Test
    void register_blankPassword_returns400() throws Exception {
        mockMvc.perform(post("/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"an@example.com\",\"password\":\"      \",\"fullName\":\"An Nguyen\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(1010));
        verifyNoInteractions(userService);
    }
}

