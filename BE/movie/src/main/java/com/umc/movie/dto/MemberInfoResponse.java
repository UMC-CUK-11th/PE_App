package com.umc.movie.dto;

import com.umc.movie.entity.Member;
import io.swagger.v3.oas.annotations.media.Schema;

import java.time.LocalDateTime;

/** 내 정보 조회·수정 응답. memberId와 password는 담지 않습니다. */
public record MemberInfoResponse(
        @Schema(example = "challenger@umc.com") String email,
        @Schema(example = "영화조아") String nickname,
        @Schema(example = "2026-09-06T12:14:03") LocalDateTime createdAt
) {
    public static MemberInfoResponse from(Member member) {
        return new MemberInfoResponse(member.getEmail(), member.getNickname(), member.getCreatedAt());
    }
}
