package com.umc11th.movie.controller;

import com.umc11th.movie.auth.JwtTokenProvider;
import com.umc11th.movie.dto.FavoriteResponse;
import com.umc11th.movie.dto.MovieRecordResponse;
import com.umc11th.movie.dto.RatingResponse;
import com.umc11th.movie.service.MovieRecordService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDateTime;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(MovieRecordController.class)
class MovieRecordControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private MovieRecordService movieRecordService;

    @MockitoBean
    private JwtTokenProvider jwtTokenProvider;

    @BeforeEach
    void setUpAuthentication() {
        when(jwtTokenProvider.getMemberId("valid-token")).thenReturn(1L);
    }

    @Test
    void createsRatingAndFavoriteFromAuthenticatedMember() throws Exception {
        LocalDateTime now = LocalDateTime.of(2026, 11, 16, 15, 0);
        MovieRecordResponse response = new MovieRecordResponse(
                new RatingResponse(7L, 550L, 5, "좋은 영화", now, now),
                new FavoriteResponse(9L, 550L, now)
        );
        when(movieRecordService.create(eq(1L), any())).thenReturn(response);

        mockMvc.perform(post("/movie-records")
                        .header("Authorization", "Bearer valid-token")
                        .contentType("application/json")
                        .content("""
                                {
                                  "movieId": 550,
                                  "score": 5,
                                  "comment": "좋은 영화",
                                  "addToFavorites": true
                                }
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.code").value("COMMON201"))
                .andExpect(jsonPath("$.result.rating.ratingId").value(7))
                .andExpect(jsonPath("$.result.favorite.favoriteId").value(9));
    }

    @Test
    void rejectsRequestWithoutToken() throws Exception {
        mockMvc.perform(post("/movie-records")
                        .contentType("application/json")
                        .content("""
                                {
                                  "movieId": 550,
                                  "score": 5,
                                  "addToFavorites": false
                                }
                                """))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("AUTH401_2"));
    }
}
