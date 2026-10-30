package com.veggiepal.dto.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.veggiepal.enums.Role;
import lombok.*;
import lombok.experimental.FieldDefaults;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
@JsonInclude(JsonInclude.Include.NON_NULL)
public class LoginResponse {
    String accessToken;
    String refreshToken;
    Long refreshExpiresIn;
    Long userId;
    String email;
    String fullName;
    Role role;
}
