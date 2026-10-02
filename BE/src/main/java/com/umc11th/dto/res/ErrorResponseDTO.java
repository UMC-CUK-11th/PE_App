package com.umc11th.dto.res;

import java.time.LocalDateTime;

// [04_필수 미션 1] 검증 실패와 예외 응답 형식을 통일하는 DTO
public record ErrorResponseDTO(
        LocalDateTime timestamp,
        int status,
        String error,
        String message,
        String path
) {
}
