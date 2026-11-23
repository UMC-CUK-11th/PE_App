package com.umc11th.movie.dto;

public record MovieRecordResponse(
        RatingResponse rating,
        FavoriteResponse favorite
) {
}
