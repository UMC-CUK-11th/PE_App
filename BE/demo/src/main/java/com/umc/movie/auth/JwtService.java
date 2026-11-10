package com.umc.movie.auth;

import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.JwtParser;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import java.time.Clock;
import java.time.Instant;
import java.util.Base64;
import java.util.Date;
import javax.crypto.SecretKey;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class JwtService {
    private static final String ISSUER = "movielog";
    private final Clock clock;
    private final long expirationSeconds;
    private final SecretKey key;
    private final JwtParser parser;

    /** Base64로 인코딩한 32바이트 서명키와 초 단위 유효기간을 설정합니다. */
    public JwtService(
        @Value("${movie.jwt.secret}") String secret,
        @Value("${movie.jwt.access-expiration}") long expirationSeconds,
        Clock clock
    ) {
        byte[] bytes;
        try {
            bytes = Base64.getDecoder().decode(secret);
        } catch (IllegalArgumentException ignored) {
            throw new IllegalArgumentException("JWT_SECRET must be Base64 encoded.");
        }
        if (bytes.length != 32 || expirationSeconds <= 0) {
            throw new IllegalArgumentException(
                "JWT_SECRET must decode to 32 bytes and JWT_ACCESS_EXPIRATION must be positive."
            );
        }
        this.clock = clock;
        this.expirationSeconds = expirationSeconds;
        this.key = Keys.hmacShaKeyFor(bytes);
        this.parser = Jwts.parser()
            .verifyWith(key)
            .requireIssuer(ISSUER)
            .clock(() -> Date.from(clock.instant()))
            .sig().clear().add(Jwts.SIG.HS256).and()
            .build();
    }

    public String issue(long memberId) {
        Instant now = clock.instant();
        return Jwts.builder()
            .issuer(ISSUER)
            .subject(Long.toString(memberId))
            .issuedAt(Date.from(now))
            .expiration(Date.from(now.plusSeconds(expirationSeconds)))
            .signWith(key, Jwts.SIG.HS256)
            .compact();
    }

    /** 서명과 만료를 검증한 토큰에서만 양의 회원 ID를 반환합니다. */
    public long verify(String token) {
        try {
            var claims = parser.parseSignedClaims(token).getPayload();
            long memberId = Long.parseLong(claims.getSubject());
            if (claims.getExpiration() == null || memberId <= 0) {
                throw AuthError.INVALID_TOKEN.exception();
            }
            if (!claims.getExpiration().toInstant().isAfter(clock.instant())) {
                throw AuthError.EXPIRED_TOKEN.exception();
            }
            return memberId;
        } catch (ExpiredJwtException error) {
            throw AuthError.EXPIRED_TOKEN.exception();
        } catch (JwtException | IllegalArgumentException error) {
            throw AuthError.INVALID_TOKEN.exception();
        }
    }
}
