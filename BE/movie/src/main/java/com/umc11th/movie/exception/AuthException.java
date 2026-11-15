package com.umc11th.movie.exception;

import lombok.Getter;
import org.springframework.http.HttpStatus;

@Getter
public class AuthException extends RuntimeException {

    private final HttpStatus status;
    private final String code;

    private AuthException(HttpStatus status, String code, String message) {
        super(message);
        this.status = status;
        this.code = code;
    }

    public static AuthException invalidCredentials() {
        return new AuthException(
                HttpStatus.UNAUTHORIZED,
                "AUTH401_1",
                "이메일 또는 비밀번호가 올바르지 않습니다."
        );
    }

    public static AuthException missingToken() {
        return new AuthException(
                HttpStatus.UNAUTHORIZED,
                "AUTH401_2",
                "인증 토큰이 필요합니다."
        );
    }

    public static AuthException invalidToken() {
        return new AuthException(
                HttpStatus.UNAUTHORIZED,
                "AUTH401_3",
                "유효하지 않은 인증 토큰입니다."
        );
    }

    public static AuthException expiredToken() {
        return new AuthException(
                HttpStatus.UNAUTHORIZED,
                "AUTH401_4",
                "만료된 인증 토큰입니다."
        );
    }

    public static AuthException forbiddenRating() {
        return new AuthException(
                HttpStatus.FORBIDDEN,
                "AUTH403_1",
                "본인이 작성한 평점만 수정하거나 삭제할 수 있습니다."
        );
    }
}
