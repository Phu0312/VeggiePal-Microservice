package com.veggiepal.ai.chat;

import java.util.Arrays;
import java.net.InetAddress;
import java.net.UnknownHostException;
import java.util.Set;
import java.util.stream.Collectors;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class ClientIpResolver {

    public static final String DEFAULT_TRUSTED_PROXIES = "127.0.0.1,0:0:0:0:0:0:0:1,::1";

    private final Set<String> trustedProxies;

    public ClientIpResolver() {
        this(DEFAULT_TRUSTED_PROXIES);
    }

    public ClientIpResolver(
            @Value("${ai.trusted-proxies:" + DEFAULT_TRUSTED_PROXIES + "}") String trustedProxiesConfig
    ) {
        this.trustedProxies = Arrays.stream(trustedProxiesConfig.split(","))
                .map(String::trim)
                .filter(s -> !s.isBlank())
                .collect(Collectors.toSet());
    }

    public String resolve(HttpServletRequest request) {
        String remoteAddr = request.getRemoteAddr();

        // If the immediate caller is not a trusted proxy, ignore all forwarded headers to prevent spoofing
        if (!isTrusted(remoteAddr)) {
            return remoteAddr != null ? remoteAddr : "unknown";
        }

        String forwarded = request.getHeader("X-Forwarded-For");
        if (forwarded != null && !forwarded.isBlank()) {
            String first = forwarded.split(",", 2)[0].trim();
            if (!first.isBlank()) return first;
        }

        String realIp = request.getHeader("X-Real-IP");
        if (realIp != null && !realIp.isBlank()) return realIp.trim();

        return remoteAddr != null ? remoteAddr : "unknown";
    }

    private boolean isTrusted(String ip) {
        if (ip == null || ip.isBlank()) return false;
        if (trustedProxies.contains("*") || trustedProxies.stream().anyMatch(rule -> matches(rule, ip))) return true;
        return "127.0.0.1".equals(ip) || "0:0:0:0:0:0:0:1".equals(ip) || "::1".equals(ip);
    }

    private static boolean matches(String rule, String ip) {
        if (!rule.contains("/")) return rule.equals(ip);
        try {
            String[] parts = rule.split("/", 2);
            byte[] network = InetAddress.getByName(parts[0]).getAddress();
            byte[] address = InetAddress.getByName(ip).getAddress();
            int bits = Integer.parseInt(parts[1]);
            if (network.length != address.length || bits < 0 || bits > network.length * 8) return false;
            for (int i = 0; i < network.length; i++) {
                int mask = bits >= 8 ? 255 : bits <= 0 ? 0 : (255 << (8 - bits)) & 255;
                if ((network[i] & mask) != (address[i] & mask)) return false;
                bits -= 8;
            }
            return true;
        } catch (UnknownHostException | NumberFormatException exception) {
            return false;
        }
    }
}
