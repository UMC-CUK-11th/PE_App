package com.umc11th.movie.controller;

import com.umc11th.movie.auth.LoginMember;
import com.umc11th.movie.dto.ApiResponse;
import com.umc11th.movie.dto.CreateMovieRecordRequest;
import com.umc11th.movie.dto.MovieRecordResponse;
import com.umc11th.movie.service.MovieRecordService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
@Tag(name = "영화 기록", description = "평점과 즐겨찾기를 하나의 트랜잭션으로 저장하는 API")
@SecurityRequirement(name = "bearerAuth")
public class MovieRecordController {

    private final MovieRecordService movieRecordService;

    @PostMapping("/movie-records")
    @Operation(
            summary = "영화 기록 저장",
            description = "addToFavorites가 true이면 평점과 즐겨찾기를 같은 트랜잭션에서 저장합니다."
    )
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "201",
                    description = "저장 성공",
                    content = @Content(examples = @ExampleObject(value = """
                            {"isSuccess":true,"code":"COMMON201","message":"영화 기록을 저장했습니다.","result":{"rating":{"ratingId":1,"movieId":550,"score":5,"comment":"오랜 시간이 지나도 좋네요."},"favorite":{"favoriteId":1,"movieId":550}}}
                            """))
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "409",
                    description = "평점 또는 즐겨찾기 중복",
                    content = @Content(examples = @ExampleObject(value = """
                            {"isSuccess":false,"code":"FAVORITE409_1","message":"이미 이 영화를 즐겨찾기하셨습니다.","result":null}
                            """))
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "401",
                    description = "인증 실패"
            )
    })
    public ResponseEntity<ApiResponse<MovieRecordResponse>> create(
            @Parameter(hidden = true) @LoginMember Long memberId,
            @Valid @RequestBody CreateMovieRecordRequest request
    ) {
        MovieRecordResponse response = movieRecordService.create(memberId, request);
        return ResponseEntity.status(201)
                .body(ApiResponse.created("영화 기록을 저장했습니다.", response));
    }
}
