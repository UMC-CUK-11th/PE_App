package com.umc.study.exception;

public class DuplicateBookTitleException extends RuntimeException {

    public DuplicateBookTitleException(String title) {
        super("이미 등록된 도서 제목입니다. (title: " + title + ")");
    }
}
