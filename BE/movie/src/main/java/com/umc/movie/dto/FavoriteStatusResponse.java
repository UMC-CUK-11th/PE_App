package com.umc.movie.dto;

import com.fasterxml.jackson.annotation.JsonProperty;

// boolean 필드 is* 이름은 Jackson이 "favorite"로 줄일 수 있어 이름을 고정합니다.
public record FavoriteStatusResponse(
        @JsonProperty("isFavorite") boolean isFavorite
) {}
