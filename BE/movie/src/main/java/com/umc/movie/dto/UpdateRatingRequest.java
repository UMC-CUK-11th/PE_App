package com.umc.movie.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/** PATCH지만 전체 교체입니다. score는 필수이고, comment를 빼면 기존 후기가 null로 덮입니다. */
public record UpdateRatingRequest(
        @Schema(description = "PATCH지만 필수. 1 이상 5 이하", example = "4")
        @NotNull(message = "별점을 입력해주세요.")
        @Min(value = 1, message = "별점은 1점 이상이어야 합니다.")
        @Max(value = 5, message = "별점은 5점 이하여야 합니다.")
        Integer score,

        @Schema(description = "선택. 500자 이하. 빼고 보내면 기존 후기가 null로 덮입니다.", example = "다시 보니 조금 아쉬웠어요")
        @Size(max = 500, message = "후기는 500자 이하로 입력해주세요.")
        String comment
) {}
