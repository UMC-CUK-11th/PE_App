package com.umc.movie.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import io.swagger.v3.oas.annotations.media.Schema;

// boolean 필드 is* 이름은 Jackson이 "favorite"로 줄일 수 있어 이름을 고정합니다.
public record FavoriteStatusResponse(
        @Schema(name = "isFavorite", example = "false") @JsonProperty("isFavorite") boolean isFavorite
) {}
