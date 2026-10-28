package com.umc11th.movie.controller;

import com.umc11th.movie.dto.EmailCheckResponse;
import com.umc11th.movie.dto.NicknameCheckResponse;
import com.umc11th.movie.dto.RatingResponse;
import com.umc11th.movie.service.MemberService;
import com.umc11th.movie.service.RatingService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDateTime;
import java.util.List;

import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(MemberController.class)
class MemberControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private MemberService memberService;

    @MockitoBean
    private RatingService ratingService;

    @Test
    void checksNicknameAvailability() throws Exception {
        when(memberService.checkNickname("수현"))
                .thenReturn(new NicknameCheckResponse(false));

        mockMvc.perform(get("/members/nickname/{nickname}", "수현"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.available").value(false));
    }

    @Test
    void rejectsInvalidEmail() throws Exception {
        mockMvc.perform(get("/members/email/{email}", "not-an-email"))
                .andExpect(status().isBadRequest());
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
                .andExpect(jsonPath("$[0].score").value(5))
                .andExpect(jsonPath("$[0].comment").value("최고의 영화!"));

        verify(ratingService).getRatings(1L, 1, 5);
    }

    @Test
    void checksEmailAvailability() throws Exception {
        when(memberService.checkEmail("new@umc.com"))
                .thenReturn(new EmailCheckResponse(true));

        mockMvc.perform(get("/members/email/{email}", "new@umc.com"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.available").value(true));
    }
}
