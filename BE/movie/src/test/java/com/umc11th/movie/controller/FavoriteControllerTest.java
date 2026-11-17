package com.umc11th.movie.controller;

import com.umc11th.movie.auth.JwtTokenProvider;
import com.umc11th.movie.dto.FavoriteResponse;
import com.umc11th.movie.dto.FavoriteStatusResponse;
import com.umc11th.movie.exception.ApiException;
import com.umc11th.movie.service.FavoriteService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.http.HttpStatus;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDateTime;
import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(FavoriteController.class)
class FavoriteControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private FavoriteService favoriteService;

    @MockitoBean
    private JwtTokenProvider jwtTokenProvider;

    @BeforeEach
    void setUpAuthentication() {
        when(jwtTokenProvider.getMemberId("valid-token")).thenReturn(1L);
    }

    @Test
    void completesFavoriteCrudWithoutMemberIdInRequest() throws Exception {
        LocalDateTime createdAt = LocalDateTime.of(2026, 11, 16, 15, 0);
        FavoriteResponse favorite = new FavoriteResponse(3L, 550L, createdAt);
        when(favoriteService.create(eq(1L), any())).thenReturn(favorite);
        when(favoriteService.getMyFavorites(1L)).thenReturn(List.of(favorite));
        when(favoriteService.getStatus(1L, 550L))
                .thenReturn(new FavoriteStatusResponse(true));

        mockMvc.perform(post("/favorites")
                        .header("Authorization", "Bearer valid-token")
                        .contentType("application/json")
                        .content("""
                                {"movieId":550}
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.code").value("COMMON201"))
                .andExpect(jsonPath("$.result.movieId").value(550));

        mockMvc.perform(get("/favorites")
                        .header("Authorization", "Bearer valid-token"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result[0].favoriteId").value(3));

        mockMvc.perform(get("/favorites/{movieId}", 550)
                        .header("Authorization", "Bearer valid-token"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.isFavorite").value(true));

        mockMvc.perform(delete("/favorites/{movieId}", 550)
                        .header("Authorization", "Bearer valid-token"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value("COMMON200"))
                .andExpect(jsonPath("$.result").doesNotExist());

        verify(favoriteService).delete(1L, 550L);
    }

    @Test
    void returnsFavoriteConflictCodeForDuplicate() throws Exception {
        when(favoriteService.create(eq(1L), any())).thenThrow(new ApiException(
                HttpStatus.CONFLICT,
                "FAVORITE409_1",
                "이미 이 영화를 즐겨찾기하셨습니다."
        ));

        mockMvc.perform(post("/favorites")
                        .header("Authorization", "Bearer valid-token")
                        .contentType("application/json")
                        .content("""
                                {"movieId":550}
                                """))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.isSuccess").value(false))
                .andExpect(jsonPath("$.code").value("FAVORITE409_1"));
    }

    @Test
    void convertsDatabaseUniqueViolationToFavoriteConflictCode() throws Exception {
        when(favoriteService.create(eq(1L), any())).thenThrow(
                new DataIntegrityViolationException(
                        "Duplicate entry for key 'uk_favorite_member_movie'"
                )
        );

        mockMvc.perform(post("/favorites")
                        .header("Authorization", "Bearer valid-token")
                        .contentType("application/json")
                        .content("""
                                {"movieId":550}
                                """))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("FAVORITE409_1"))
                .andExpect(jsonPath("$.message")
                        .value("이미 이 영화를 즐겨찾기하셨습니다."));
    }

    @Test
    void requiresBearerToken() throws Exception {
        mockMvc.perform(get("/favorites"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("AUTH401_2"));
    }
}
