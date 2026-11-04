package com.umc11th.movie.exception;

import lombok.Getter;

@Getter
public class MemberConflictException extends RuntimeException {

    private final String code;

    private MemberConflictException(String code, String message) {
        super(message);
        this.code = code;
    }

    public static MemberConflictException duplicateEmail() {
        return new MemberConflictException(
                "MEMBER4091",
                "이미 사용 중인 이메일입니다."
        );
    }

    public static MemberConflictException duplicateNickname() {
        return new MemberConflictException(
                "MEMBER4092",
                "이미 사용 중인 닉네임입니다."
        );
    }
}
