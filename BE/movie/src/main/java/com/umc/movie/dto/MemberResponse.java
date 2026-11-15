package com.umc.movie.dto;

import com.umc.movie.entity.Member;

/** password는 절대 응답에 넣지 않습니다. */
public record MemberResponse(Long memberId, String email, String nickname) {

    public static MemberResponse from(Member member) {
        return new MemberResponse(member.getMemberId(), member.getEmail(), member.getNickname());
    }
}
