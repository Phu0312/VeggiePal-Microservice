package com.veggiepal.ai.configuration;

import org.springframework.security.oauth2.jwt.Jwt;

import com.veggiepal.ai.exception.AppException;
import com.veggiepal.ai.exception.ErrorCode;

public final class CurrentUser {

    private CurrentUser() {}

    public static Long id(Jwt jwt) {
        if (jwt == null) {
            throw new AppException(ErrorCode.UNAUTHENTICATED);
        }
        Object claim = jwt.getClaim("userId");
        if (claim instanceof Number number) {
            return number.longValue();
        }
        throw new AppException(ErrorCode.UNAUTHENTICATED);
    }
}
