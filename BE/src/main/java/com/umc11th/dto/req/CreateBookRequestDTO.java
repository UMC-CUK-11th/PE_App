package com.umc11th.dto.req;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

// [04_실습 2] 도서 등록 요청 형식과 입력값 검증을 담당하는 DTO
public record CreateBookRequestDTO(
        @NotNull(message = "카테고리 ID는 필수입니다.")
        Long categoryId,

        @NotBlank(message = "도서 제목은 필수입니다.")
        @Size(max = 100, message = "도서 제목은 100자 이하여야 합니다.")
        String title,

        String description
) {
}
