package com.umc11th.exception;

// [04_선택 미션 3] 같은 제목의 도서가 이미 존재할 때 사용하는 예외
public class DuplicateBookTitleException extends RuntimeException {

    public DuplicateBookTitleException(String title) {
        super("이미 등록된 도서 제목입니다. title=" + title);
    }
}
