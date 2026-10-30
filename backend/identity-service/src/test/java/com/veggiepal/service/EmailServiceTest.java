package com.veggiepal.service;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.veggiepal.enums.OtpPurpose;
import com.veggiepal.exception.AppException;
import com.veggiepal.exception.ErrorCode;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.core.env.Environment;
import org.springframework.mail.javamail.JavaMailSender;

class EmailServiceTest {
    @Test
    void absentSmtpOutsideDevProfileFailsWithoutLoggingOtp() {
        @SuppressWarnings("unchecked")
        ObjectProvider<JavaMailSender> provider = mock(ObjectProvider.class);
        Environment environment = mock(Environment.class);
        when(environment.getActiveProfiles()).thenReturn(new String[] {"prod"});
        EmailService email = new EmailService(provider, environment, "", "no-reply@example.com");

        assertThatThrownBy(() -> email.sendOtpEmail("user@example.com", OtpPurpose.EMAIL_VERIFICATION, "123456", 300))
                .isInstanceOfSatisfying(AppException.class,
                        error -> org.assertj.core.api.Assertions.assertThat(error.getErrorCode()).isEqualTo(ErrorCode.MAIL_UNAVAILABLE));
    }
}
