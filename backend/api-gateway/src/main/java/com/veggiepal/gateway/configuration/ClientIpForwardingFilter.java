package com.veggiepal.gateway.configuration;

import java.util.Arrays;
import java.net.InetAddress;
import java.net.UnknownHostException;
import java.util.Set;
import java.util.stream.Collectors;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.cloud.gateway.server.mvc.filter.HttpHeadersFilter;
import org.springframework.core.Ordered;
import org.springframework.http.HttpHeaders;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.function.ServerRequest;

@Component
public class ClientIpForwardingFilter implements HttpHeadersFilter.RequestHttpHeadersFilter, Ordered {

    private final Set<String> trustedProxies;

    public ClientIpForwardingFilter(
            @Value("${spring.cloud.gateway.server.webmvc.trusted-proxies:}") String trustedProxiesConfig
    ) {
        this.trustedProxies = Arrays.stream(trustedProxiesConfig.split(","))
                .map(String::trim)
                .filter(s -> !s.isBlank())
                .collect(Collectors.toSet());
    }

    @Override
    public HttpHeaders apply(HttpHeaders headers, ServerRequest serverRequest) {
        HttpHeaders mutable = new HttpHeaders();
        mutable.putAll(headers);

        String remoteAddr = serverRequest.servletRequest().getRemoteAddr();
        if (remoteAddr == null || remoteAddr.isBlank()) {
            return mutable;
        }

        boolean isTrusted = isTrustedProxy(remoteAddr);
        String existingForwarded = mutable.getFirst("X-Forwarded-For");

        if (isTrusted && existingForwarded != null && !existingForwarded.isBlank()) {
            // Trusted upstream reverse proxy: keep chain and append current remoteAddr if not present
            if (!existingForwarded.contains(remoteAddr)) {
                mutable.set("X-Forwarded-For", existingForwarded + ", " + remoteAddr);
            }
        } else {
            // Direct client or untrusted proxy: overwrite X-Forwarded-For and X-Real-IP to prevent spoofing
            mutable.set("X-Forwarded-For", remoteAddr);
            mutable.set("X-Real-IP", remoteAddr);
        }

        return mutable;
    }

    private boolean isTrustedProxy(String ip) {
        if (trustedProxies.isEmpty()) {
            return false;
        }
        return trustedProxies.contains("*") || trustedProxies.stream().anyMatch(rule -> matches(rule, ip));
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

    @Override
    public int getOrder() {
        return Ordered.LOWEST_PRECEDENCE;
    }
}
