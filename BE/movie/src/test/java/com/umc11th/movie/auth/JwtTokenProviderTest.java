package com.umc11th.movie.auth;

import com.umc11th.movie.exception.AuthException;
import org.junit.jupiter.api.Test;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class JwtTokenProviderTest {

    private static final String SECRET = "test-secret-key-for-umc11th-movie-api";
    private static final Instant ISSUED_AT = Instant.parse("2026-11-10T00:00:00Z");

    @Test
    void extractsMemberIdFromValidToken() {
        JwtTokenProvider provider = providerAt(ISSUED_AT, 60);

        String token = provider.createAccessToken(7L);

        assertThat(provider.getMemberId(token)).isEqualTo(7L);
    }

    @Test
    void rejectsTokenWhosePayloadWasTamperedWith() {
        JwtTokenProvider provider = providerAt(ISSUED_AT, 60);
        String token = provider.createAccessToken(7L);
        String[] parts = token.split("\\.");
        char replacement = parts[1].charAt(0) == 'a' ? 'b' : 'a';
        parts[1] = replacement + parts[1].substring(1);
        String tamperedToken = String.join(".", parts);

        assertThatThrownBy(() -> provider.getMemberId(tamperedToken))
                .isInstanceOf(AuthException.class)
                .satisfies(exception -> assertThat(((AuthException) exception).getCode())
                        .isEqualTo("AUTH401_3"));
    }

    @Test
    void distinguishesExpiredTokenFromMissingToken() {
        JwtTokenProvider issuer = providerAt(ISSUED_AT, 60);
        String token = issuer.createAccessToken(7L);
        JwtTokenProvider verifier = providerAt(ISSUED_AT.plusSeconds(61), 60);

        assertThatThrownBy(() -> verifier.getMemberId(token))
                .isInstanceOf(AuthException.class)
                .satisfies(exception -> assertThat(((AuthException) exception).getCode())
                        .isEqualTo("AUTH401_4"));
        assertThat(AuthException.missingToken().getCode()).isEqualTo("AUTH401_2");
    }

    private JwtTokenProvider providerAt(Instant instant, long expirationSeconds) {
        return new JwtTokenProvider(
                SECRET,
                expirationSeconds,
                Clock.fixed(instant, ZoneOffset.UTC)
        );
    }
}
