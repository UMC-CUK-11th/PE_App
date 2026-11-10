package com.umc11th.movie.controller;

import com.umc11th.movie.auth.LoginMember;
import com.umc11th.movie.dto.ApiResponse;
import com.umc11th.movie.dto.CreateRatingRequest;
import com.umc11th.movie.dto.RatingResponse;
import com.umc11th.movie.dto.UpdateRatingRequest;
import com.umc11th.movie.service.RatingService;
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
public class RatingController {

    private final RatingService ratingService;

    @GetMapping("/members/{memberId}/ratings")
    public List<RatingResponse> getRatings(
            @PathVariable @Min(1) Long memberId,
            @RequestParam(defaultValue = "0") @Min(0) int page,
            @RequestParam(defaultValue = "10") @Min(1) @Max(100) int size
    ) {
        return ratingService.getRatings(memberId, page, size);
    }

    @GetMapping("/members/me/ratings")
    public List<RatingResponse> getMyRatings(
            @LoginMember Long memberId,
            @RequestParam(defaultValue = "0") @Min(0) int page,
            @RequestParam(defaultValue = "10") @Min(1) @Max(100) int size
    ) {
        return ratingService.getRatings(memberId, page, size);
    }

    @PostMapping("/ratings")
    public ResponseEntity<ApiResponse<Long>> create(
            @LoginMember Long memberId,
            @Valid @RequestBody CreateRatingRequest request
    ) {
        Long ratingId = ratingService.create(memberId, request);
        return ResponseEntity.status(201)
                .body(ApiResponse.created("평점 등록에 성공했습니다.", ratingId));
    }

    @PatchMapping("/ratings/{ratingId}")
    public ResponseEntity<ApiResponse<Void>> update(
            @LoginMember Long memberId,
            @PathVariable @Min(1) Long ratingId,
            @Valid @RequestBody UpdateRatingRequest request
    ) {
        ratingService.update(ratingId, memberId, request);
        return ResponseEntity.ok(ApiResponse.ok("평점 수정에 성공했습니다.", null));
    }

    @DeleteMapping("/ratings/{ratingId}")
    public ResponseEntity<Void> delete(
            @LoginMember Long memberId,
            @PathVariable @Min(1) Long ratingId
    ) {
        ratingService.delete(ratingId, memberId);
        return ResponseEntity.noContent().build();
    }
}
