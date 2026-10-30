package com.veggiepal.dto.request;

import jakarta.validation.constraints.NotNull;

import com.veggiepal.enums.UserStatus;

import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class UpdateUserStatusRequest {

    @NotNull(message = "INVALID_REQUEST")
    UserStatus status;
}

