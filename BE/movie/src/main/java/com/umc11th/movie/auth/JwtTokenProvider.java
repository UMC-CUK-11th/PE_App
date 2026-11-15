package com.umc11th.movie.auth;

import com.umc11th.movie.exception.AuthException;
import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.time.Clock;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Date;

@Component
public class JwtTokenProvider {

    private final SecretKey secretKey;
    private final long accessExpirationSeconds;
    private final Clock clock;

    @Autowired
    public JwtTokenProvider(
            @Value("${app.jwt.secret}") String secret,
            @Value("${app.jwt.access-expiration-seconds}") long accessExpirationSeconds
    ) {
        this(secret, accessExpirationSeconds, Clock.systemUTC());
    }

    JwtTokenProvider(String secret, long accessExpirationSeconds, Clock clock) {
        if (secret.getBytes(StandardCharsets.UTF_8).length < 32) {
            throw new IllegalArgumentException("JWT secret은 32바이트 이상이어야 합니다.");
        }
        if (accessExpirationSeconds <= 0) {
            throw new IllegalArgumentException("JWT 만료 시간은 1초 이상이어야 합니다.");
        }
        this.secretKey = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        this.accessExpirationSeconds = accessExpirationSeconds;
        this.clock = clock;
    }

    public String createAccessToken(Long memberId) {
        Instant issuedAt = clock.instant();
        Instant expiresAt = issuedAt.plus(accessExpirationSeconds, ChronoUnit.SECONDS);
        return Jwts.builder()
                .subject(memberId.toString())
                .issuedAt(Date.from(issuedAt))
                .expiration(Date.from(expiresAt))
                .signWith(secretKey)
                .compact();
    }

    public Long getMemberId(String token) {
        try {
            String subject = Jwts.parser()
                    .verifyWith(secretKey)
                    .clock(() -> Date.from(clock.instant()))
                    .build()
                    .parseSignedClaims(token)
                    .getPayload()
                    .getSubject();
            return Long.valueOf(subject);
        } catch (ExpiredJwtException exception) {
            throw AuthException.expiredToken();
        } catch (JwtException | IllegalArgumentException exception) {
            throw AuthException.invalidToken();
        }
    }
}
