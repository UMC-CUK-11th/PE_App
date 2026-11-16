package com.umc11th.movie.dto;

import io.swagger.v3.oas.annotations.media.Schema;

public record FavoriteStatusResponse(
        @Schema(description = "로그인 회원의 즐겨찾기 여부", example = "true")
        boolean isFavorite
) {
}
