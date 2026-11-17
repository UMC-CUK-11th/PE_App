package com.umc.movie;

import com.umc.movie.controller.FavoriteController;
import com.umc.movie.controller.MovieRecordController;
import com.umc.movie.dto.FavoriteResponse;
import com.umc.movie.dto.FavoriteStatusResponse;
import com.umc.movie.dto.MovieRecordResponse;
import com.umc.movie.dto.RatingResponse;
import com.umc.movie.exception.ApiException;
import com.umc.movie.jwt.JwtProvider;
import com.umc.movie.service.FavoriteService;
import com.umc.movie.service.MovieRecordService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDateTime;
import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.BDDMockito.given;
import static org.mockito.BDDMockito.then;
import static org.mockito.BDDMockito.willThrow;
import static org.mockito.Mockito.never;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/** 8주차 즐겨찾기·영화 기록 API (워크북 Postman 시나리오와 실패 표) */
@WebMvcTest({FavoriteController.class, MovieRecordController.class})
@Import(JwtProvider.class)
class FavoriteApiTest {

    private static final long MEMBER_ID = 1L;

    @Autowired
    MockMvc mockMvc;

    @Autowired
    JwtProvider jwtProvider;

    @MockitoBean
    FavoriteService favoriteService;

    @MockitoBean
    MovieRecordService movieRecordService;

    private String token;

    @BeforeEach
    void setUp() {
        token = "Bearer " + jwtProvider.createAccessToken(MEMBER_ID);
    }

    private static final String FAVORITE_550 = "{\"movieId\":550}";

    @Test
    void 즐겨찾기_등록은_201과_favorite_결과() throws Exception {
        given(favoriteService.create(eq(MEMBER_ID), any()))
                .willReturn(new FavoriteResponse(1L, 550L, LocalDateTime.of(2026, 9, 6, 21, 0)));

        mockMvc.perform(post("/favorites").header(HttpHeaders.AUTHORIZATION, token)
                        .contentType(MediaType.APPLICATION_JSON).content(FAVORITE_550))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.isSuccess").value(true))
                .andExpect(jsonPath("$.code").value("COMMON201"))
                .andExpect(jsonPath("$.message").value("즐겨찾기를 등록했습니다."))
                .andExpect(jsonPath("$.result.favoriteId").value(1))
                .andExpect(jsonPath("$.result.movieId").value(550))
                .andExpect(jsonPath("$.result.createdAt").value("2026-09-06T21:00:00"));
    }

    @Test
    void 같은_영화_중복_등록은_409_FAVORITE409_1_DB_제약_위반도_409() throws Exception {
        given(favoriteService.create(eq(MEMBER_ID), any()))
                .willThrow(ApiException.conflict("FAVORITE409_1", "이미 이 영화를 즐겨찾기하셨습니다."));
        mockMvc.perform(post("/favorites").header(HttpHeaders.AUTHORIZATION, token)
                        .contentType(MediaType.APPLICATION_JSON).content(FAVORITE_550))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.isSuccess").value(false))
                .andExpect(jsonPath("$.code").value("FAVORITE409_1"))
                .andExpect(jsonPath("$.result").isEmpty());

        // 사전 검사를 동시에 통과한 요청은 UNIQUE 제약에서 막히고 같은 형식의 409로 바뀝니다.
        willThrow(new DataIntegrityViolationException("Duplicate entry")).given(favoriteService).create(eq(MEMBER_ID), any());
        mockMvc.perform(post("/favorites").header(HttpHeaders.AUTHORIZATION, token)
                        .contentType(MediaType.APPLICATION_JSON).content(FAVORITE_550))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("COMMON4091"));
    }

    @Test
    void 토큰_없이_등록하면_401_AUTH401_2_서비스는_호출되지_않음() throws Exception {
        mockMvc.perform(post("/favorites").contentType(MediaType.APPLICATION_JSON).content(FAVORITE_550))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.isSuccess").value(false))
                .andExpect(jsonPath("$.code").value("AUTH401_2"));

        mockMvc.perform(post("/movie-records").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"movieId\":238,\"score\":5,\"addToFavorites\":true}"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("AUTH401_2"));

        then(favoriteService).should(never()).create(any(), any());
        then(movieRecordService).should(never()).create(any(), any());
    }

    @Test
    void movieId가_0이면_400() throws Exception {
        mockMvc.perform(post("/favorites").header(HttpHeaders.AUTHORIZATION, token)
                        .contentType(MediaType.APPLICATION_JSON).content("{\"movieId\":0}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("COMMON4001"))
                .andExpect(jsonPath("$.message").value("영화 ID는 양수여야 합니다."));
    }

    @Test
    void 내_목록은_200_최신순_없으면_빈_배열() throws Exception {
        given(favoriteService.getMyFavorites(MEMBER_ID)).willReturn(List.of(
                new FavoriteResponse(2L, 238L, LocalDateTime.of(2026, 9, 6, 21, 10)),
                new FavoriteResponse(1L, 550L, LocalDateTime.of(2026, 9, 6, 21, 0))));
        mockMvc.perform(get("/favorites").header(HttpHeaders.AUTHORIZATION, token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value("COMMON200"))
                .andExpect(jsonPath("$.result.length()").value(2))
                .andExpect(jsonPath("$.result[0].movieId").value(238));

        given(favoriteService.getMyFavorites(MEMBER_ID)).willReturn(List.of());
        mockMvc.perform(get("/favorites").header(HttpHeaders.AUTHORIZATION, token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result").isArray())
                .andExpect(jsonPath("$.result").isEmpty());
    }

    @Test
    void 여부_조회는_true_false_모두_200() throws Exception {
        given(favoriteService.getStatus(MEMBER_ID, 550L)).willReturn(new FavoriteStatusResponse(true));
        mockMvc.perform(get("/favorites/550").header(HttpHeaders.AUTHORIZATION, token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("즐겨찾기 여부를 조회했습니다."))
                .andExpect(jsonPath("$.result.isFavorite").value(true))
                .andExpect(jsonPath("$.result.favorite").doesNotExist());

        given(favoriteService.getStatus(MEMBER_ID, 551L)).willReturn(new FavoriteStatusResponse(false));
        mockMvc.perform(get("/favorites/551").header(HttpHeaders.AUTHORIZATION, token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.isFavorite").value(false));
    }

    @Test
    void 해제는_200_result_null_없는_즐겨찾기는_404_FAVORITE404_1() throws Exception {
        mockMvc.perform(delete("/favorites/550").header(HttpHeaders.AUTHORIZATION, token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value("COMMON200"))
                .andExpect(jsonPath("$.message").value("즐겨찾기를 해제했습니다."))
                .andExpect(jsonPath("$.result").isEmpty());
        then(favoriteService).should().delete(MEMBER_ID, 550L);

        willThrow(ApiException.notFound("FAVORITE404_1", "즐겨찾기한 영화를 찾을 수 없습니다."))
                .given(favoriteService).delete(MEMBER_ID, 999L);
        mockMvc.perform(delete("/favorites/999").header(HttpHeaders.AUTHORIZATION, token))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("FAVORITE404_1"));
    }

    @Test
    void 영화_기록_저장은_201_rating과_favorite_재요청은_RATING409_1() throws Exception {
        String body = """
                {"movieId":238,"score":5,"comment":"다시 보고 싶은 영화입니다.","addToFavorites":true}""";
        LocalDateTime now = LocalDateTime.of(2026, 9, 6, 21, 10);
        given(movieRecordService.create(eq(MEMBER_ID), any())).willReturn(new MovieRecordResponse(
                new RatingResponse(3L, 238L, 5, "다시 보고 싶은 영화입니다.", now, now),
                new FavoriteResponse(2L, 238L, now)));

        mockMvc.perform(post("/movie-records").header(HttpHeaders.AUTHORIZATION, token)
                        .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.code").value("COMMON201"))
                .andExpect(jsonPath("$.message").value("영화 기록을 저장했습니다."))
                .andExpect(jsonPath("$.result.rating.ratingId").value(3))
                .andExpect(jsonPath("$.result.favorite.favoriteId").value(2));

        given(movieRecordService.create(eq(MEMBER_ID), any()))
                .willThrow(ApiException.conflict("RATING409_1", "이미 이 영화에 평점을 남기셨습니다."));
        mockMvc.perform(post("/movie-records").header(HttpHeaders.AUTHORIZATION, token)
                        .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("RATING409_1"));
    }

    @Test
    void 영화_기록은_addToFavorites가_없으면_400() throws Exception {
        mockMvc.perform(post("/movie-records").header(HttpHeaders.AUTHORIZATION, token)
                        .contentType(MediaType.APPLICATION_JSON).content("{\"movieId\":238,\"score\":5}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("즐겨찾기 추가 여부는 필수입니다."));
    }
}
