package com.veggiepal.configuration;

import java.util.Arrays;
import java.util.List;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtException;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationConverter;
import org.springframework.security.oauth2.server.resource.authentication.JwtGrantedAuthoritiesConverter;
import org.springframework.security.oauth2.server.resource.web.BearerTokenResolver;
import org.springframework.security.oauth2.server.resource.web.DefaultBearerTokenResolver;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.servlet.util.matcher.PathPatternRequestMatcher;
import org.springframework.security.web.util.matcher.RequestMatcher;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class SecurityConfig {

    static final String[] PUBLIC_ENDPOINTS = {
            "/auth/register",
            "/auth/login",
            "/auth/google",
            "/auth/forgot-password",
            "/auth/verify-otp",
            "/auth/reset-password",
            "/auth/send-verification",
            "/auth/verify-email",
            "/auth/refresh",
            "/auth/logout",
            "/auth/test",
            "/users/batch",
            "/swagger-ui/**",
            "/swagger-ui.html",
            "/v3/api-docs/**"
    };

    SecurityExceptionHandler securityExceptionHandler;

    @Bean
    public SecurityFilterChain filterChain(
            HttpSecurity httpSecurity,
            JwtDecoder jwtDecoder
    ) throws Exception {

        httpSecurity
                .authorizeHttpRequests(
                        request -> request
                                .requestMatchers(PUBLIC_ENDPOINTS)
                                .permitAll()

                                .requestMatchers("/admin/**")
                                .hasRole("ADMIN")

                                .anyRequest()
                                .authenticated()
                )
                .oauth2ResourceServer(
                        oauth2 -> oauth2
                                .jwt(jwt -> jwt.jwtAuthenticationConverter(jwtAuthenticationConverter()))
                                .bearerTokenResolver(publicEndpointAwareBearerTokenResolver(jwtDecoder))
                                .authenticationEntryPoint(securityExceptionHandler)
                                .accessDeniedHandler(securityExceptionHandler)
                )
                .exceptionHandling(
                        exceptions -> exceptions
                                .authenticationEntryPoint(securityExceptionHandler)
                                .accessDeniedHandler(securityExceptionHandler)
                )
                .sessionManagement(
                        session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS)
                );

        httpSecurity.csrf(
                AbstractHttpConfigurer::disable
        );

        return httpSecurity.build();
    }

    @Bean
    PasswordEncoder passwordEncoder() {

        return new BCryptPasswordEncoder(10);
    }

    private JwtAuthenticationConverter jwtAuthenticationConverter() {

        JwtGrantedAuthoritiesConverter authoritiesConverter = new JwtGrantedAuthoritiesConverter();
        authoritiesConverter.setAuthoritiesClaimName("role");
        authoritiesConverter.setAuthorityPrefix("ROLE_");

        JwtAuthenticationConverter converter = new JwtAuthenticationConverter();
        converter.setJwtGrantedAuthoritiesConverter(authoritiesConverter);
        return converter;
    }

    // Public endpoints accept a valid token when present (e.g. /auth/send-verification),
    // while ignoring stale/malformed tokens so login/register/refresh never fail with 401.
    private BearerTokenResolver publicEndpointAwareBearerTokenResolver(JwtDecoder jwtDecoder) {

        DefaultBearerTokenResolver defaultResolver = new DefaultBearerTokenResolver();
        List<RequestMatcher> publicMatchers = Arrays.stream(PUBLIC_ENDPOINTS)
                .map(pattern -> (RequestMatcher) PathPatternRequestMatcher.withDefaults().matcher(pattern))
                .toList();

        return request -> {
            String token = defaultResolver.resolve(request);
            if (token == null || publicMatchers.stream().noneMatch(matcher -> matcher.matches(request))) {
                return token;
            }
            try {
                jwtDecoder.decode(token);
                return token;
            } catch (JwtException | IllegalArgumentException ignored) {
                return null;
            }
        };
    }
}
