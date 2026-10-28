package com.umc11th.movie.dto;

import java.time.LocalDateTime;

public record ApiErrorResponse(
        int status,
        String message,
        LocalDateTime timestamp
) {
    public static ApiErrorResponse badRequest(String message) {
        return new ApiErrorResponse(400, message, LocalDateTime.now());
    }
}
