package com.umc11th.dto.res;

import com.umc11th.entity.Book;

// [04_필수 미션 1] Entity를 직접 노출하지 않고 필요한 값만 반환하는 응답 DTO
public record BookResponseDTO(
        Long bookId,
        String title,
        String description,
        String categoryName,
        Boolean isAvailable
) {
    // [04_선택 미션 1] 연관된 카테고리 이름을 API 응답에 포함
    public static BookResponseDTO from(Book book) {
        return new BookResponseDTO(
                book.getBookId(),
                book.getTitle(),
                book.getDescription(),
                book.getCategory().getName(),
                book.getIsAvailable()
        );
    }
}
