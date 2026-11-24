package com.umc11th.movie.controller;

import com.umc11th.movie.auth.LoginMember;
import com.umc11th.movie.dto.ApiResponse;
import com.umc11th.movie.dto.CreateRatingRequest;
import com.umc11th.movie.dto.RatingResponse;
import com.umc11th.movie.dto.UpdateRatingRequest;
import com.umc11th.movie.service.RatingService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@Validated
@RestController
@RequiredArgsConstructor
@Tag(name = "평점", description = "영화 평점 조회 및 인증 회원의 평점 관리 API")
public class RatingController {

    private final RatingService ratingService;

    @GetMapping({
            "/members/{memberId}/ratings",
            "/v7/members/{memberId}/ratings",
            "/v8/members/{memberId}/ratings"
    })
    @Operation(summary = "유저별 평점 조회", description = "토큰이 필요하지 않은 공개 조회 API입니다.")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "조회 성공"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "400", description = "COMMON4001 - 잘못된 페이지 조건")
    })
    public List<RatingResponse> getRatings(
            @PathVariable @Min(1) Long memberId,
            @RequestParam(defaultValue = "0") @Min(0) int page,
            @RequestParam(defaultValue = "10") @Min(1) @Max(100) int size
    ) {
        return ratingService.getRatings(memberId, page, size);
    }

    @GetMapping({
            "/members/me/ratings",
            "/v7/members/me/ratings",
            "/v8/members/me/ratings"
    })
    @Operation(summary = "내 평점 조회", description = "Bearer 토큰이 필요합니다.")
    @SecurityRequirement(name = "bearerAuth")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "조회 성공"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", description = "AUTH401_2/AUTH401_3/AUTH401_4 - 인증 실패")
    })
    public List<RatingResponse> getMyRatings(
            @Parameter(hidden = true) @LoginMember Long memberId,
            @RequestParam(defaultValue = "0") @Min(0) int page,
            @RequestParam(defaultValue = "10") @Min(1) @Max(100) int size
    ) {
        return ratingService.getRatings(memberId, page, size);
    }

    @PostMapping({"/ratings", "/v7/ratings", "/v8/ratings"})
    @Operation(summary = "평점 등록", description = "Bearer 토큰이 필요하며, 한 회원은 같은 영화에 평점을 한 번만 등록할 수 있습니다.")
    @SecurityRequirement(name = "bearerAuth")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "201", description = "등록 성공"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "400", description = "COMMON4001 - 입력값 오류"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", description = "인증 실패"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "409",
                    description = "RATING409_1 - 이미 평점을 등록함",
                    content = @Content(examples = @ExampleObject(value = """
                            {"isSuccess":false,"code":"RATING409_1","message":"이미 이 영화에 평점을 남기셨습니다.","result":null}
                            """))
            )
    })
    public ResponseEntity<ApiResponse<Long>> create(
            @Parameter(hidden = true) @LoginMember Long memberId,
            @Valid @RequestBody CreateRatingRequest request
    ) {
        Long ratingId = ratingService.create(memberId, request);
        return ResponseEntity.status(201)
                .body(ApiResponse.created("평점 등록에 성공했습니다.", ratingId));
    }

    @PatchMapping({
            "/ratings/{ratingId}",
            "/v7/ratings/{ratingId}",
            "/v8/ratings/{ratingId}"
    })
    @Operation(summary = "평점 수정", description = "Bearer 토큰이 필요하며, 본인이 작성한 평점만 수정할 수 있습니다.")
    @SecurityRequirement(name = "bearerAuth")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "수정 성공"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "400", description = "COMMON4001 - 입력값 오류"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", description = "인증 실패"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "403", description = "RATING403_1 - 다른 회원의 평점"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "COMMON404 - 평점 없음")
    })
    public ResponseEntity<ApiResponse<Void>> update(
            @Parameter(hidden = true) @LoginMember Long memberId,
            @PathVariable @Min(1) Long ratingId,
            @Valid @RequestBody UpdateRatingRequest request
    ) {
        ratingService.update(ratingId, memberId, request);
        return ResponseEntity.ok(ApiResponse.ok("평점 수정에 성공했습니다.", null));
    }

    @DeleteMapping({
            "/ratings/{ratingId}",
            "/v7/ratings/{ratingId}",
            "/v8/ratings/{ratingId}"
    })
    @Operation(summary = "평점 삭제", description = "Bearer 토큰이 필요하며, 본인이 작성한 평점만 삭제할 수 있습니다.")
    @SecurityRequirement(name = "bearerAuth")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "204", description = "삭제 성공"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", description = "인증 실패"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "403", description = "RATING403_1 - 다른 회원의 평점"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "COMMON404 - 평점 없음")
    })
    public ResponseEntity<Void> delete(
            @Parameter(hidden = true) @LoginMember Long memberId,
            @PathVariable @Min(1) Long ratingId
    ) {
        ratingService.delete(ratingId, memberId);
        return ResponseEntity.noContent().build();
    }
}
