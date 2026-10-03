package com.umc.study.exception;

import java.util.List;

public record ErrorResponse(
        int status,
        String message,
        List<FieldError> errors
) {
    public record FieldError(String field, String reason) {
    }

    public static ErrorResponse of(int status, String message) {
        return new ErrorResponse(status, message, List.of());
    }
}
