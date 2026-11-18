package com.umc.movie.dto;

import io.swagger.v3.oas.annotations.media.Schema;

public record NicknameCheckResponse(@Schema(description = "사용 가능하면 true", example = "true") boolean available) {}
