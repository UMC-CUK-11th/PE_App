package com.umc.movie.jwt;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;

/** 7주차: HS256 accessToken 발급·검증. subject에 memberId를 담습니다. */
@Component
public class JwtProvider {

    private final SecretKey key;
    private final long accessExpirationMillis;

    public JwtProvider(
            @Value("${jwt.secret}") String secret,
            @Value("${jwt.access-expiration-seconds}") long accessExpirationSeconds
    ) {
        // HS256은 256비트(32바이트) 이상의 키가 필요합니다. 짧으면 여기서 기동이 실패합니다.
        this.key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        this.accessExpirationMillis = accessExpirationSeconds * 1000;
    }

    public String createAccessToken(Long memberId) {
        Date now = new Date();
        return Jwts.builder()
                .subject(String.valueOf(memberId))
                .issuedAt(now)
                .expiration(new Date(now.getTime() + accessExpirationMillis))
                .signWith(key, Jwts.SIG.HS256)
                .compact();
    }

    /**
     * 토큰에서 memberId를 꺼냅니다.
     * 만료는 {@link ExpiredJwtException}, 서명·형식 오류는 {@link JwtException}으로 던져 호출 쪽이 구분합니다.
     */
    public Long getMemberId(String token) {
        Claims claims = Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(token)
                .getPayload();
        try {
            return Long.valueOf(claims.getSubject());
        } catch (NumberFormatException e) {
            throw new JwtException("subject가 memberId 형식이 아닙니다.", e);
        }
    }
}
