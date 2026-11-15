package com.umc.movie.dto;
import com.umc.movie.entity.Member;
public record SignupResponse(Long memberId, String email, String nickname) {
    public static SignupResponse from(Member member) {
        return new SignupResponse(member.getMemberId(), member.getEmail(), member.getNickname());
    }
}
