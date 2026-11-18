package com.umc.movie.interceptor;

import com.umc.movie.exception.ApiException;
import com.umc.movie.exception.ErrorCode;
import com.umc.movie.jwt.JwtProvider;
import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.JwtException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.stereotype.Component;
import org.springframework.util.AntPathMatcher;
import org.springframework.web.servlet.HandlerInterceptor;

import java.util.List;

/**
 * 7주차: 기본은 "모든 경로 보호"입니다. 공개 API만 PUBLIC 목록에 메서드와 함께 적습니다.
 * 통과하면 토큰의 memberId를 request attribute로 넘기고, 컨트롤러는 @RequestAttribute로 받습니다.
 * 실패는 ApiException을 던져 GlobalExceptionHandler가 공통 응답 형식(401)으로 바꿉니다.
 */
@Component
@RequiredArgsConstructor
public class AuthInterceptor implements HandlerInterceptor {

    public static final String MEMBER_ID = "memberId";
    private static final String BEARER = "Bearer ";

    private record PublicApi(HttpMethod method, String pattern) {}

    // 새 보호 API(/favorites, /ratings, /members/me 등)는 여기에 넣지 않습니다.
    // Swagger 문서 경로는 로그인 전에도 열려야 하므로 공개합니다(9주차 실습 1).
    private static final List<PublicApi> PUBLIC = List.of(
            new PublicApi(HttpMethod.POST, "/auth/login"),
            new PublicApi(HttpMethod.POST, "/members"),
            new PublicApi(HttpMethod.GET, "/members/nickname/*"),
            new PublicApi(HttpMethod.GET, "/members/email/*"),
            new PublicApi(HttpMethod.GET, "/members/*/ratings"),
            new PublicApi(HttpMethod.GET, "/swagger-ui.html"),
            new PublicApi(HttpMethod.GET, "/swagger-ui/**"),
            new PublicApi(HttpMethod.GET, "/v3/api-docs/**"),
            new PublicApi(HttpMethod.GET, "/v3/api-docs")
    );

    private final AntPathMatcher pathMatcher = new AntPathMatcher();
    private final JwtProvider jwtProvider;

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
        // CORS preflight는 토큰 없이 옵니다.
        if (HttpMethod.OPTIONS.matches(request.getMethod()) || isPublic(request)) {
            return true;
        }

        String header = request.getHeader(HttpHeaders.AUTHORIZATION);
        if (header == null || !header.startsWith(BEARER) || header.substring(BEARER.length()).isBlank()) {
            throw new ApiException(ErrorCode.TOKEN_MISSING);
        }

        try {
            Long memberId = jwtProvider.getMemberId(header.substring(BEARER.length()).trim());
            request.setAttribute(MEMBER_ID, memberId);
            return true;
        } catch (ExpiredJwtException e) {
            throw new ApiException(ErrorCode.TOKEN_EXPIRED);
        } catch (JwtException | IllegalArgumentException e) {
            throw new ApiException(ErrorCode.TOKEN_INVALID);
        }
    }

    private boolean isPublic(HttpServletRequest request) {
        String path = request.getRequestURI().substring(request.getContextPath().length());
        return PUBLIC.stream().anyMatch(api ->
                api.method().matches(request.getMethod()) && pathMatcher.match(api.pattern(), path));
    }
}
