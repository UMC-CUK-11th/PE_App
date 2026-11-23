package com.umc.movie.controller;

import com.umc.movie.config.SwaggerConfig;
import com.umc.movie.docs.ApiErrorCodes;
import com.umc.movie.dto.ApiResponse;
import com.umc.movie.dto.CreateRatingRequest;
import com.umc.movie.dto.RatingResponse;
import com.umc.movie.dto.UpdateRatingRequest;
import com.umc.movie.exception.ErrorCode;
import com.umc.movie.interceptor.AuthInterceptor;
import com.umc.movie.service.RatingService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestAttribute;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 조회는 공개, 등록·수정·삭제는 토큰이 필요합니다.
 * 7주차 계약대로 쓰기 요청에는 memberId가 없고, 토큰의 회원(AuthInterceptor가 넣은 memberId)을 씁니다.
 */
@RestController
@RequiredArgsConstructor
@Tag(name = "평점", description = "유저별 평점 조회(공개)와 평점 등록·수정·삭제(토큰 필요) API")
public class RatingController {

    private final RatingService ratingService;

    @Operation(summary = "유저별 평점 조회",
            description = "공개 API. ratingId 내림차순이고 평점이 없으면 빈 배열입니다. 성공 응답은 공통 형식으로 감싸지 않습니다.")
    @ApiErrorCodes(ErrorCode.MEMBER_NOT_FOUND)
    @GetMapping("/members/{memberId}/ratings")
    public List<RatingResponse> getMemberRatings(@Parameter(example = "1") @PathVariable Long memberId) {
        return ratingService.getRatingsByMember(memberId);
    }

    @Operation(summary = "평점 등록", description = "토큰의 주인인 회원이 TMDB 영화 하나에 별점(1~5)과 후기를 남깁니다. 한 영화에 한 번만 남길 수 있습니다.")
    @SecurityRequirement(name = SwaggerConfig.BEARER_AUTH)
    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "201", description = "COMMON201 평점을 등록했습니다.")
    @ApiErrorCodes({ErrorCode.INVALID_INPUT, ErrorCode.MEMBER_NOT_FOUND, ErrorCode.RATING_DUPLICATED})
    @PostMapping("/ratings")
    public ResponseEntity<ApiResponse<RatingResponse>> create(
            @Parameter(hidden = true) @RequestAttribute(AuthInterceptor.MEMBER_ID) Long memberId,
            @Valid @RequestBody CreateRatingRequest request
    ) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.created("평점을 등록했습니다.", ratingService.create(memberId, request)));
    }

    @Operation(summary = "평점 수정",
            description = "본인이 작성한 평점만 수정합니다. PATCH지만 전체 교체라 score는 필수이고, comment를 빼면 기존 후기가 null로 덮입니다.")
    @SecurityRequirement(name = SwaggerConfig.BEARER_AUTH)
    @ApiErrorCodes({ErrorCode.INVALID_INPUT, ErrorCode.RATING_FORBIDDEN, ErrorCode.RATING_NOT_FOUND})
    @PatchMapping("/ratings/{ratingId}")
    public ResponseEntity<ApiResponse<RatingResponse>> update(
            @Parameter(hidden = true) @RequestAttribute(AuthInterceptor.MEMBER_ID) Long memberId,
            @Parameter(example = "12") @PathVariable Long ratingId,
            @Valid @RequestBody UpdateRatingRequest request
    ) {
        return ResponseEntity.ok(ApiResponse.ok("평점을 수정했습니다.", ratingService.update(memberId, ratingId, request)));
    }

    @Operation(summary = "평점 삭제", description = "본인이 작성한 평점만 삭제합니다. 6주차의 204와 달리 200이고 result는 null입니다.")
    @SecurityRequirement(name = SwaggerConfig.BEARER_AUTH)
    @ApiErrorCodes({ErrorCode.RATING_FORBIDDEN, ErrorCode.RATING_NOT_FOUND})
    @DeleteMapping("/ratings/{ratingId}")
    public ResponseEntity<ApiResponse<Void>> delete(
            @Parameter(hidden = true) @RequestAttribute(AuthInterceptor.MEMBER_ID) Long memberId,
            @Parameter(example = "12") @PathVariable Long ratingId
    ) {
        ratingService.delete(memberId, ratingId);
        return ResponseEntity.ok(ApiResponse.ok("평점을 삭제했습니다.", null));
    }
}
