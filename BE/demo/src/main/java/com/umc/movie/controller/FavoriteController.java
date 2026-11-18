package com.umc.movie.controller;

import com.umc.movie.auth.LoginMember;
import com.umc.movie.dto.ApiResponse;
import com.umc.movie.dto.CreateFavoriteRequest;
import com.umc.movie.dto.FavoriteResponse;
import com.umc.movie.dto.FavoriteStatusResponse;
import com.umc.movie.service.FavoriteService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Positive;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/favorites")
@RequiredArgsConstructor
public class FavoriteController {
    private final FavoriteService favorites;

    @PostMapping
    public ResponseEntity<ApiResponse<FavoriteResponse>> create(
        @LoginMember Long memberId, @Valid @RequestBody CreateFavoriteRequest request
    ) {
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(ApiResponse.created("즐겨찾기를 등록했습니다.", favorites.create(memberId, request.movieId())));
    }

    @GetMapping
    public ApiResponse<List<FavoriteResponse>> list(@LoginMember Long memberId) {
        return ApiResponse.ok("즐겨찾기 목록을 조회했습니다.", favorites.list(memberId));
    }

    @GetMapping("/{movieId}")
    public ApiResponse<FavoriteStatusResponse> status(
        @LoginMember Long memberId, @PathVariable @Positive Long movieId
    ) {
        return ApiResponse.ok("즐겨찾기 여부를 조회했습니다.",
            new FavoriteStatusResponse(favorites.isFavorite(memberId, movieId)));
    }

    @DeleteMapping("/{movieId}")
    public ApiResponse<Void> delete(@LoginMember Long memberId, @PathVariable @Positive Long movieId) {
        favorites.delete(memberId, movieId);
        return ApiResponse.ok("즐겨찾기를 해제했습니다.", null);
    }
}
