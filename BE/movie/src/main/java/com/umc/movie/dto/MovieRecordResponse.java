package com.umc.movie.dto;

import io.swagger.v3.oas.annotations.media.Schema;

/** addToFavorites가 false면 favorite는 null입니다. */
public record MovieRecordResponse(
        RatingResponse rating,
        @Schema(description = "addToFavorites가 false면 null", nullable = true) FavoriteResponse favorite
) {}
