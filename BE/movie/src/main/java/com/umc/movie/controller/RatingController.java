package com.umc.movie.controller;

import com.umc.movie.dto.ApiResponse;
import com.umc.movie.dto.CreateRatingRequest;
import com.umc.movie.dto.RatingResponse;
import com.umc.movie.dto.UpdateRatingRequest;
import com.umc.movie.exception.ApiException;
import com.umc.movie.interceptor.AuthInterceptor;
import com.umc.movie.service.RatingService;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 조회는 공개, 등록·수정·삭제는 토큰이 필요합니다(AuthInterceptor).
 * 6주차 URL은 그대로 두고, 경로의 memberId가 토큰의 회원과 같을 때만 쓰기를 허용합니다.
 */
@Tag(name = "Rating", description = "평점 (조회 공개 · 쓰기는 Bearer 토큰)")
@RestController
@RequiredArgsConstructor
@RequestMapping("/members")
public class RatingController {

    private final RatingService ratingService;

    @GetMapping("/{memberId}/ratings")
    public List<RatingResponse> getMemberRatings(@PathVariable Long memberId) {
        return ratingService.getRatingsByMember(memberId);
    }

    @SecurityRequirement(name = "bearerAuth")
    @PostMapping("/{memberId}/ratings")
    public ResponseEntity<ApiResponse<Long>> create(
            @Parameter(hidden = true) @RequestAttribute(AuthInterceptor.MEMBER_ID) Long loginMemberId,
            @PathVariable Long memberId,
            @Valid @RequestBody CreateRatingRequest request
    ) {
        verifySelf(memberId, loginMemberId);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.created("평점 등록에 성공했습니다.", ratingService.create(memberId, request)));
    }

    @SecurityRequirement(name = "bearerAuth")
    @PatchMapping("/{memberId}/ratings/{ratingId}")
    public ApiResponse<Void> update(
            @Parameter(hidden = true) @RequestAttribute(AuthInterceptor.MEMBER_ID) Long loginMemberId,
            @PathVariable Long memberId,
            @PathVariable Long ratingId,
            @Valid @RequestBody UpdateRatingRequest request
    ) {
        verifySelf(memberId, loginMemberId);
        ratingService.update(ratingId, memberId, request);
        return ApiResponse.ok("평점 수정에 성공했습니다.", null);
    }

    @SecurityRequirement(name = "bearerAuth")
    @DeleteMapping("/{memberId}/ratings/{ratingId}")
    public ResponseEntity<Void> delete(
            @Parameter(hidden = true) @RequestAttribute(AuthInterceptor.MEMBER_ID) Long loginMemberId,
            @PathVariable Long memberId,
            @PathVariable Long ratingId
    ) {
        verifySelf(memberId, loginMemberId);
        ratingService.delete(ratingId, memberId);
        return ResponseEntity.noContent().build();
    }

    /** 다른 회원의 경로로 쓰기를 시도하면 403입니다. */
    private void verifySelf(Long pathMemberId, Long loginMemberId) {
        if (!pathMemberId.equals(loginMemberId)) {
            throw ApiException.forbidden("AUTH403_1", "본인 계정의 평점만 등록·수정·삭제할 수 있습니다.");
        }
    }
}
