package com.veggiepal.dto.request;

import com.veggiepal.enums.UserStatus;

import jakarta.validation.constraints.NotNull;

import lombok.*;
import lombok.experimental.FieldDefaults;

@Data
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class UpdateUserStatusRequest {

    @NotNull(message = "INVALID_REQUEST")
    UserStatus status;
}
