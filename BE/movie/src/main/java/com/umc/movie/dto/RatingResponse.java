package com.umc.movie.dto;

import com.umc.movie.entity.Rating;
import io.swagger.v3.oas.annotations.media.Schema;

import java.time.LocalDateTime;

public record RatingResponse(
        @Schema(example = "12") Long ratingId,
        @Schema(description = "TMDB 영화 ID", example = "550") Long movieId,
        @Schema(example = "5") Integer score,
        @Schema(example = "최고의 영화!") String comment,
        @Schema(example = "2026-09-06T12:14:03") LocalDateTime createdAt,
        @Schema(example = "2026-09-06T12:14:03") LocalDateTime updatedAt
) {
    public static RatingResponse from(Rating rating) {
        return new RatingResponse(
                rating.getRatingId(),
                rating.getMovieId(),
                rating.getScore(),
                rating.getComment(),
                rating.getCreatedAt(),
                rating.getUpdatedAt()
        );
    }
}
