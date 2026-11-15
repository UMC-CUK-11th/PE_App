package com.umc.movie;

import com.umc.movie.controller.MemberController;
import com.umc.movie.dto.EmailCheckResponse;
import com.umc.movie.dto.NicknameCheckResponse;
import com.umc.movie.service.MemberService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.BDDMockito.given;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(MemberController.class)
class MemberControllerTest {

    @Autowired
    MockMvc mockMvc;

    @MockitoBean
    MemberService memberService;

    @Test
    void 사용_중인_닉네임이면_available_false() throws Exception {
        given(memberService.checkNickname("수현")).willReturn(new NicknameCheckResponse(false));

        mockMvc.perform(get("/members/nickname/{nickname}", "수현"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.available").value(false));
    }

    @Test
    void 닉네임이_2자_미만이거나_12자_초과면_400() throws Exception {
        mockMvc.perform(get("/members/nickname/{nickname}", "a")).andExpect(status().isBadRequest());
        mockMvc.perform(get("/members/nickname/{nickname}", "a".repeat(13))).andExpect(status().isBadRequest());
    }

    @Test
    void 이메일_형식이_아니면_400() throws Exception {
        mockMvc.perform(get("/members/email/{email}", "not-an-email")).andExpect(status().isBadRequest());
    }

    @Test
    void 허용한_출처에는_CORS_헤더를_내려준다() throws Exception {
        given(memberService.checkEmail("noco@umc.com")).willReturn(new EmailCheckResponse(false));

        mockMvc.perform(get("/members/email/{email}", "noco@umc.com").header("Origin", "http://localhost:5173"))
                .andExpect(status().isOk())
                .andExpect(header().string("Access-Control-Allow-Origin", "http://localhost:5173"));

        mockMvc.perform(get("/members/email/{email}", "noco@umc.com").header("Origin", "http://evil.example"))
                .andExpect(status().isForbidden());
    }
}
