package com.umc11th.movie.auth;

import com.umc11th.movie.exception.AuthException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

@Component
@RequiredArgsConstructor
public class JwtAuthenticationInterceptor implements HandlerInterceptor {

    public static final String LOGIN_MEMBER_ATTRIBUTE =
            JwtAuthenticationInterceptor.class.getName() + ".loginMemberId";
    private static final String BEARER_PREFIX = "Bearer ";

    private final JwtTokenProvider jwtTokenProvider;

    @Override
    public boolean preHandle(
            HttpServletRequest request,
            HttpServletResponse response,
            Object handler
    ) {
        if ("OPTIONS".equalsIgnoreCase(request.getMethod())) {
            return true;
        }

        String authorization = request.getHeader("Authorization");
        if (authorization == null || authorization.isBlank()) {
            throw AuthException.missingToken();
        }
        if (!authorization.startsWith(BEARER_PREFIX)
                || authorization.length() == BEARER_PREFIX.length()) {
            throw AuthException.invalidToken();
        }

        String token = authorization.substring(BEARER_PREFIX.length()).trim();
        Long memberId = jwtTokenProvider.getMemberId(token);
        request.setAttribute(LOGIN_MEMBER_ATTRIBUTE, memberId);
        return true;
    }
}
