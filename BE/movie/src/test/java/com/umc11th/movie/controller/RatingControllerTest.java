package com.umc11th.movie.controller;

import com.umc11th.movie.auth.JwtTokenProvider;
import com.umc11th.movie.dto.RatingResponse;
import com.umc11th.movie.exception.AuthException;
import com.umc11th.movie.service.RatingService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.BeforeEach;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.http.HttpStatus;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;
import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(RatingController.class)
class RatingControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private RatingService ratingService;

    @MockitoBean
    private JwtTokenProvider jwtTokenProvider;

    @BeforeEach
    void setUpAuthentication() {
        when(jwtTokenProvider.getMemberId("valid-token")).thenReturn(1L);
    }

    @Test
    void forwardsPaginationParameters() throws Exception {
        LocalDateTime now = LocalDateTime.of(2026, 10, 28, 12, 0);
        when(ratingService.getRatings(1L, 1, 5)).thenReturn(List.of(
                new RatingResponse(3L, 550L, 5, "최고의 영화!", now, now)
        ));

        mockMvc.perform(get("/members/{memberId}/ratings", 1)
                        .param("page", "1")
                        .param("size", "5"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$[0].ratingId").value(3))
                .andExpect(jsonPath("$[0].movieId").value(550))
                .andExpect(jsonPath("$[0].score").value(5));

        verify(ratingService).getRatings(1L, 1, 5);
    }

    @Test
    void createsRating() throws Exception {
        when(ratingService.create(org.mockito.ArgumentMatchers.eq(1L), any()))
                .thenReturn(7L);

        mockMvc.perform(post("/ratings")
                        .header("Authorization", "Bearer valid-token")
                        .contentType("application/json")
                        .content("""
                                {
                                  "movieId": 550,
                                  "score": 5,
                                  "comment": "최고의 영화!"
                                }
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.isSuccess").value(true))
                .andExpect(jsonPath("$.code").value("COMMON201"))
                .andExpect(jsonPath("$.result").value(7));
    }

    @Test
    void rejectsOutOfRangeScore() throws Exception {
        mockMvc.perform(post("/ratings")
                        .header("Authorization", "Bearer valid-token")
                        .contentType("application/json")
                        .content("""
                                {
                                  "movieId": 550,
                                  "score": 6,
                                  "comment": "범위를 벗어난 별점"
                                }
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.isSuccess").value(false))
                .andExpect(jsonPath("$.code").value("COMMON4001"))
                .andExpect(jsonPath("$.message").value("별점은 5점 이하여야 합니다."));
    }

    @Test
    void updatesRating() throws Exception {
        doNothing().when(ratingService).update(
                org.mockito.ArgumentMatchers.eq(7L),
                org.mockito.ArgumentMatchers.eq(1L),
                any()
        );

        mockMvc.perform(patch("/ratings/{ratingId}", 7)
                        .header("Authorization", "Bearer valid-token")
                        .contentType("application/json")
                        .content("""
                                {
                                  "score": 4,
                                  "comment": "수정한 후기"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.isSuccess").value(true))
                .andExpect(jsonPath("$.code").value("COMMON200"))
                .andExpect(jsonPath("$.result").doesNotExist());
    }

    @Test
    void deletesRatingWithNoContent() throws Exception {
        mockMvc.perform(delete("/ratings/{ratingId}", 7)
                        .header("Authorization", "Bearer valid-token"))
                .andExpect(status().isNoContent())
                .andExpect(content().string(""));

        verify(ratingService).delete(7L, 1L);
    }

    @Test
    void rejectsDuplicateRatingWithConflictResponse() throws Exception {
        when(ratingService.create(org.mockito.ArgumentMatchers.eq(1L), any()))
                .thenThrow(new IllegalArgumentException("이미 이 영화에 평점을 남기셨습니다."));

        mockMvc.perform(post("/ratings")
                        .header("Authorization", "Bearer valid-token")
                        .contentType("application/json")
                        .content("""
                                {
                                  "movieId": 550,
                                  "score": 5
                                }
                                """))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.isSuccess").value(false))
                .andExpect(jsonPath("$.code").value("COMMON4092"))
                .andExpect(jsonPath("$.message")
                        .value("이미 이 영화에 평점을 남기셨습니다."));
    }

    @Test
    void convertsRatingDatabaseUniqueViolationToSameConflictResponse() throws Exception {
        when(ratingService.create(org.mockito.ArgumentMatchers.eq(1L), any()))
                .thenThrow(new DataIntegrityViolationException(
                        "Duplicate entry for key 'uk_rating_member_movie'"
                ));

        mockMvc.perform(post("/ratings")
                        .header("Authorization", "Bearer valid-token")
                        .contentType("application/json")
                        .content("""
                                {
                                  "movieId": 550,
                                  "score": 5
                                }
                                """))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.isSuccess").value(false))
                .andExpect(jsonPath("$.code").value("COMMON4092"))
                .andExpect(jsonPath("$.message")
                        .value("이미 이 영화에 평점을 남기셨습니다."));
    }

    @Test
    void rejectsUpdateByAnotherMemberWithForbiddenResponse() throws Exception {
        doThrow(AuthException.forbiddenRating()).when(ratingService).update(
                org.mockito.ArgumentMatchers.eq(7L),
                org.mockito.ArgumentMatchers.eq(1L),
                any()
        );

        mockMvc.perform(patch("/ratings/{ratingId}", 7)
                        .header("Authorization", "Bearer valid-token")
                        .contentType("application/json")
                        .content("""
                                {
                                  "score": 4,
                                  "comment": "수정 시도"
                                }
                                """))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.isSuccess").value(false))
                .andExpect(jsonPath("$.code").value("AUTH403_1"));
    }

    @Test
    void rejectsDeleteForMissingRatingWithNotFoundResponse() throws Exception {
        doThrow(new ResponseStatusException(
                HttpStatus.NOT_FOUND,
                "존재하지 않는 평점입니다."
        )).when(ratingService).delete(999L, 1L);

        mockMvc.perform(delete("/ratings/{ratingId}", 999)
                        .header("Authorization", "Bearer valid-token"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.isSuccess").value(false))
                .andExpect(jsonPath("$.code").value("COMMON404"))
                .andExpect(jsonPath("$.message").value("존재하지 않는 평점입니다."));
    }

    @Test
    void rejectsRatingCreationWithoutToken() throws Exception {
        mockMvc.perform(post("/ratings")
                        .contentType("application/json")
                        .content("""
                                {
                                  "movieId": 550,
                                  "score": 5
                                }
                                """))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("AUTH401_2"));
    }

    @Test
    void getsAuthenticatedMembersRatings() throws Exception {
        when(ratingService.getRatings(1L, 0, 10)).thenReturn(List.of());

        mockMvc.perform(get("/members/me/ratings")
                        .header("Authorization", "Bearer valid-token"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray());

        verify(ratingService).getRatings(1L, 0, 10);
    }
}
