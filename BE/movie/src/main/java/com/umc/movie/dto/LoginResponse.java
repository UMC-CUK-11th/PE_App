package com.umc.movie.dto;

import io.swagger.v3.oas.annotations.media.Schema;

/** memberId는 토큰 안에만 담고 응답 본문에는 넣지 않습니다. */
public record LoginResponse(
        @Schema(example = "영화조아") String nickname,
        @Schema(description = "Authorize 버튼에 넣을 Access Token(Bearer는 붙이지 않음)", example = "eyJhbGciOiJIUzI1NiJ9...")
        String accessToken
) {}
