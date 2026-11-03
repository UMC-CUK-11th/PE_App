package com.umc11th.movie.dto;

import com.umc11th.movie.entity.Member;

public record MemberResponse(
        Long memberId,
        String email,
        String nickname
) {
    public static MemberResponse from(Member member) {
        return new MemberResponse(
                member.getMemberId(),
                member.getEmail(),
                member.getNickname()
        );
    }
}
