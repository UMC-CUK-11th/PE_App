package com.umc.movie.dto;

import com.umc.movie.entity.Favorite;
import io.swagger.v3.oas.annotations.media.Schema;

import java.time.LocalDateTime;

public record FavoriteResponse(
        @Schema(example = "1") Long favoriteId,
        @Schema(description = "TMDB 영화 ID", example = "550") Long movieId,
        @Schema(example = "2026-09-13T21:00:00") LocalDateTime createdAt
) {
    public static FavoriteResponse from(Favorite favorite) {
        return new FavoriteResponse(
                favorite.getFavoriteId(),
                favorite.getMovieId(),
                favorite.getCreatedAt()
        );
    }
}
