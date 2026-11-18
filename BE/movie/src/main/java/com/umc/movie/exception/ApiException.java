package com.umc.movie.exception;

import lombok.Getter;
import org.springframework.http.HttpStatus;

/** 상태 코드·code·message를 {@link ErrorCode} 하나로 들고 다니는 업무 예외입니다. */
@Getter
public class ApiException extends RuntimeException {

    private final ErrorCode errorCode;

    public ApiException(ErrorCode errorCode) {
        super(errorCode.getMessage());
        this.errorCode = errorCode;
    }

    public HttpStatus getStatus() {
        return errorCode.getStatus();
    }

    public String getCode() {
        return errorCode.getCode();
    }
}
