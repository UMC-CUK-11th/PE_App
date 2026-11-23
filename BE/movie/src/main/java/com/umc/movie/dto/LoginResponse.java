package com.umc.movie.dto;

/** memberId는 토큰 안에만 담고 응답 본문에는 넣지 않습니다. */
public record LoginResponse(String nickname, String accessToken) {}
