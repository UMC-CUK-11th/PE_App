package com.umc.movie.auth;

import com.umc.movie.exception.ApiException;
import org.springframework.http.HttpStatus;

public enum AuthError {
    BAD_CREDENTIALS("AUTH401_1", "이메일 또는 비밀번호가 올바르지 않습니다."),
    MISSING_TOKEN("AUTH401_2", "로그인이 필요한 요청입니다."),
    INVALID_TOKEN("AUTH401_3", "유효하지 않은 토큰입니다."),
    EXPIRED_TOKEN("AUTH401_4", "토큰이 만료되었습니다. 다시 로그인해주세요.");

    private final String code;
    private final String message;

    AuthError(String code, String message) {
        this.code = code;
        this.message = message;
    }

    public ApiException exception() {
        return new ApiException(HttpStatus.UNAUTHORIZED, code, message);
    }
}
