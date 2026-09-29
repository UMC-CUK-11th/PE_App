package com.umc.study.dto;

public class RentalRequest {
    private Long userId;
    private Long bookId;

    // 스프링이 JSON 데이터를 이 객체로 변환할 때 꼭 필요한 Getter입니다.
    public Long getUserId() {
        return userId;
    }

    public Long getBookId() {
        return bookId;
    }
}