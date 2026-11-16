package com.umc11th.movie.controller;

import com.umc11th.movie.auth.LoginMember;
import com.umc11th.movie.dto.ApiResponse;
import com.umc11th.movie.dto.CreateFavoriteRequest;
import com.umc11th.movie.dto.FavoriteResponse;
import com.umc11th.movie.dto.FavoriteStatusResponse;
import com.umc11th.movie.service.FavoriteService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Positive;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@Validated
@RestController
@RequiredArgsConstructor
@Tag(name = "즐겨찾기", description = "인증 회원의 영화 즐겨찾기 API")
@SecurityRequirement(name = "bearerAuth")
public class FavoriteController {

    private final FavoriteService favoriteService;

    @PostMapping("/favorites")
    @Operation(summary = "즐겨찾기 등록", description = "Bearer 토큰의 회원에게 TMDB 영화를 저장합니다.")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "201",
                    description = "등록 성공",
                    content = @Content(examples = @ExampleObject(value = """
                            {"isSuccess":true,"code":"COMMON201","message":"즐겨찾기를 등록했습니다.","result":{"favoriteId":1,"movieId":550,"createdAt":"2026-11-16T15:00:00"}}
                            """))
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "409",
                    description = "중복 등록",
                    content = @Content(examples = @ExampleObject(value = """
                            {"isSuccess":false,"code":"FAVORITE409_1","message":"이미 이 영화를 즐겨찾기하셨습니다.","result":null}
                            """))
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "401",
                    description = "인증 실패"
            )
    })
    public ResponseEntity<ApiResponse<FavoriteResponse>> create(
            @Parameter(hidden = true) @LoginMember Long memberId,
            @Valid @RequestBody CreateFavoriteRequest request
    ) {
        FavoriteResponse response = favoriteService.create(memberId, request);
        return ResponseEntity.status(201)
                .body(ApiResponse.created("즐겨찾기를 등록했습니다.", response));
    }

    @GetMapping("/favorites")
    @Operation(summary = "내 즐겨찾기 목록 조회", description = "빈 목록도 200과 빈 배열로 응답합니다.")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "200",
                    description = "조회 성공",
                    content = @Content(examples = @ExampleObject(value = """
                            {"isSuccess":true,"code":"COMMON200","message":"내 즐겨찾기 목록을 조회했습니다.","result":[{"favoriteId":1,"movieId":550,"createdAt":"2026-11-16T15:00:00"}]}
                            """))
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "401",
                    description = "인증 실패"
            )
    })
    public ResponseEntity<ApiResponse<List<FavoriteResponse>>> getMyFavorites(
            @Parameter(hidden = true) @LoginMember Long memberId
    ) {
        List<FavoriteResponse> response = favoriteService.getMyFavorites(memberId);
        return ResponseEntity.ok(ApiResponse.ok("내 즐겨찾기 목록을 조회했습니다.", response));
    }

    @GetMapping("/favorites/{movieId}")
    @Operation(summary = "즐겨찾기 여부 조회")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "200",
                    description = "조회 성공",
                    content = @Content(examples = @ExampleObject(value = """
                            {"isSuccess":true,"code":"COMMON200","message":"즐겨찾기 여부를 조회했습니다.","result":{"isFavorite":true}}
                            """))
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "401",
                    description = "인증 실패"
            )
    })
    public ResponseEntity<ApiResponse<FavoriteStatusResponse>> getStatus(
            @Parameter(hidden = true) @LoginMember Long memberId,
            @PathVariable @Positive Long movieId
    ) {
        FavoriteStatusResponse response = favoriteService.getStatus(memberId, movieId);
        return ResponseEntity.ok(ApiResponse.ok("즐겨찾기 여부를 조회했습니다.", response));
    }

    @DeleteMapping("/favorites/{movieId}")
    @Operation(summary = "즐겨찾기 해제")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "200",
                    description = "해제 성공",
                    content = @Content(examples = @ExampleObject(value = """
                            {"isSuccess":true,"code":"COMMON200","message":"즐겨찾기를 해제했습니다.","result":null}
                            """))
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "404",
                    description = "즐겨찾기 없음"
            )
    })
    public ResponseEntity<ApiResponse<Void>> delete(
            @Parameter(hidden = true) @LoginMember Long memberId,
            @PathVariable @Positive Long movieId
    ) {
        favoriteService.delete(memberId, movieId);
        return ResponseEntity.ok(ApiResponse.ok("즐겨찾기를 해제했습니다.", null));
    }
}
