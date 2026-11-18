package com.umc.movie.controller;

import com.umc.movie.config.SwaggerConfig;
import com.umc.movie.docs.ApiErrorCodes;
import com.umc.movie.dto.ApiResponse;
import com.umc.movie.dto.CreateMovieRecordRequest;
import com.umc.movie.dto.MovieRecordResponse;
import com.umc.movie.exception.ErrorCode;
import com.umc.movie.interceptor.AuthInterceptor;
import com.umc.movie.service.MovieRecordService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestAttribute;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
@Tag(name = "영화 기록", description = "평점과 즐겨찾기를 한 트랜잭션으로 저장하는 API")
@SecurityRequirement(name = SwaggerConfig.BEARER_AUTH)
public class MovieRecordController {

    private final MovieRecordService movieRecordService;

    @Operation(summary = "영화 기록 저장",
            description = """
                    평점과 즐겨찾기를 한 트랜잭션으로 저장합니다. 둘 중 하나라도 실패하면 전체가 롤백됩니다.
                    이미 즐겨찾기한 영화에 addToFavorites=true로 보내면 FAVORITE409_1이고 평점도 남지 않습니다.
                    addToFavorites가 false면 result.favorite은 null입니다.""")
    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "201", description = "COMMON201 영화 기록을 저장했습니다.")
    @ApiErrorCodes({ErrorCode.INVALID_INPUT, ErrorCode.MEMBER_NOT_FOUND,
            ErrorCode.RATING_DUPLICATED, ErrorCode.FAVORITE_DUPLICATED})
    @PostMapping("/movie-records")
    public ResponseEntity<ApiResponse<MovieRecordResponse>> create(
            @Parameter(hidden = true) @RequestAttribute(AuthInterceptor.MEMBER_ID) Long memberId,
            @RequestBody @Valid CreateMovieRecordRequest request
    ) {
        MovieRecordResponse response = movieRecordService.create(memberId, request);
        return ResponseEntity.status(201)
                .body(ApiResponse.created("영화 기록을 저장했습니다.", response));
    }
}
