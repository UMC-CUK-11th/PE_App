package com.umc.movie.dto;

import io.swagger.v3.oas.annotations.media.Schema;

/** 6주차부터 저장 API의 성공·실패를 같은 틀로 응답합니다. */
public record ApiResponse<T>(
        @Schema(example = "true") boolean isSuccess,
        @Schema(description = "성공 COMMON200/COMMON201, 실패는 도메인별 code", example = "COMMON200") String code,
        @Schema(example = "요청에 성공했습니다.") String message,
        T result
) {

    public static <T> ApiResponse<T> created(String message, T result) {
        return new ApiResponse<>(true, "COMMON201", message, result);
    }

    public static <T> ApiResponse<T> ok(String message, T result) {
        return new ApiResponse<>(true, "COMMON200", message, result);
    }

    public static ApiResponse<Void> failure(String code, String message) {
        return new ApiResponse<>(false, code, message, null);
    }
}
