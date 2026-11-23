package com.umc.movie.dto;

import com.umc.movie.entity.Member;
import io.swagger.v3.oas.annotations.media.Schema;

/** 회원가입 응답. memberId가 담기는 유일한 응답이고, password는 절대 넣지 않습니다. */
public record MemberResponse(
        @Schema(example = "1") Long memberId,
        @Schema(example = "challenger@umc.com") String email,
        @Schema(example = "영화조아") String nickname
) {
    public static MemberResponse from(Member member) {
        return new MemberResponse(member.getMemberId(), member.getEmail(), member.getNickname());
    }
}
