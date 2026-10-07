package com.umc11th.exception;

// [04_필수 미션 1] 요청한 categoryId가 DB에 없을 때 사용하는 예외
public class CategoryNotFoundException extends RuntimeException {

    public CategoryNotFoundException(Long categoryId) {
        super("존재하지 않는 카테고리입니다. categoryId=" + categoryId);
    }
}
