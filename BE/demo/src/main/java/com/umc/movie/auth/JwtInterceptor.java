package com.umc.movie.auth;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.stereotype.Component;
import org.springframework.web.cors.CorsUtils;
import org.springframework.web.servlet.HandlerInterceptor;

@Component
@RequiredArgsConstructor
public class JwtInterceptor implements HandlerInterceptor {
    static final String MEMBER_ID = JwtInterceptor.class.getName() + ".memberId";
    private final JwtService tokens;

    /** 보호 경로의 Bearer 토큰을 확인하고 검증된 주체를 요청 범위에 보관합니다. */
    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
        if (CorsUtils.isPreFlightRequest(request)) return true;
        String authorization = request.getHeader(HttpHeaders.AUTHORIZATION);
        if (authorization == null || authorization.isBlank()) {
            throw AuthError.MISSING_TOKEN.exception();
        }
        if (!authorization.regionMatches(true, 0, "Bearer ", 0, 7)
            || authorization.substring(7).isBlank()) {
            throw AuthError.INVALID_TOKEN.exception();
        }
        request.setAttribute(MEMBER_ID, tokens.verify(authorization.substring(7)));
        return true;
    }
}
