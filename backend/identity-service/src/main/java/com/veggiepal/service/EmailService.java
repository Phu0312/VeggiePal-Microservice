package com.veggiepal.service;

import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.env.Environment;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import com.veggiepal.enums.OtpPurpose;
import com.veggiepal.exception.AppException;
import com.veggiepal.exception.ErrorCode;

import lombok.extern.slf4j.Slf4j;

@Service
@Slf4j
public class EmailService {

    private final ObjectProvider<JavaMailSender> mailSenderProvider;
    private final String mailHost;
    private final String fromAddress;
    private final Environment environment;

    public EmailService(
            ObjectProvider<JavaMailSender> mailSenderProvider,
            Environment environment,
            @Value("${spring.mail.host:}") String mailHost,
            @Value("${app.mail.from:no-reply@veggiepal.com}") String fromAddress
    ) {
        this.mailSenderProvider = mailSenderProvider;
        this.environment = environment;
        this.mailHost = mailHost;
        this.fromAddress = fromAddress;
    }

    public void sendOtpEmail(String toEmail, OtpPurpose purpose, String otpCode, long expiresInSeconds) {
        requireDeliveryAvailable();
        long expiresMinutes = Math.max(1L, expiresInSeconds / 60L);
        String subject = purpose == OtpPurpose.PASSWORD_RESET
                ? "[VeggiePal] Mã OTP đặt lại mật khẩu"
                : "[VeggiePal] Mã OTP xác thực email";
        String body = (purpose == OtpPurpose.PASSWORD_RESET
                ? "Mã OTP đặt lại mật khẩu của bạn là: "
                : "Mã OTP xác thực email VeggiePal của bạn là: ")
                + otpCode + "\nMã có hiệu lực trong " + expiresMinutes + " phút.";

        JavaMailSender mailSender = mailSenderProvider.getIfAvailable();
        if (!StringUtils.hasText(mailHost) || mailSender == null) {
            log.info("SMTP host not configured — [DEV OTP] to={}, purpose={}, otp={}, ttlSeconds={}",
                    toEmail, purpose, otpCode, expiresInSeconds);
            return;
        }

        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom(fromAddress);
        message.setTo(toEmail);
        message.setSubject(subject);
        message.setText(body);
        mailSender.send(message);
    }

    public void requireDeliveryAvailable() {
        if ((!StringUtils.hasText(mailHost) || mailSenderProvider.getIfAvailable() == null)
                && !java.util.Arrays.asList(environment.getActiveProfiles()).contains("dev")) {
            throw new AppException(ErrorCode.MAIL_UNAVAILABLE);
        }
    }
}

