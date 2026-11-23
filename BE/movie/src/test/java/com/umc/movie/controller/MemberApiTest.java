package com.umc.movie.controller;

import com.umc.movie.entity.Member;
import com.umc.movie.jwt.JwtProvider;
import com.umc.movie.repository.MemberRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** 내 정보 조회·수정(GET·PATCH /members/me) 통합 테스트 */
@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class MemberApiTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private MemberRepository memberRepository;

    @Autowired
    private JwtProvider jwtProvider;

    private Member me;
    private String token;

    @BeforeEach
    void setUp() {
        me = memberRepository.save(Member.builder()
                .email("me@umc.com").password("$2a$10$abcdefghijklmnopqrstuv").nickname("영화조아").build());
        memberRepository.save(Member.builder()
                .email("other@umc.com").password("$2a$10$abcdefghijklmnopqrstuv").nickname("다른사람").build());
        token = "Bearer " + jwtProvider.createAccessToken(me.getMemberId());
    }

    @Test
    @DisplayName("토큰을 담아 내 정보를 조회하면 200과 email·nickname을 응답하고 memberId·password는 없다")
    void getMyInfo() throws Exception {
        mockMvc.perform(get("/members/me").header(HttpHeaders.AUTHORIZATION, token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("회원 정보를 조회했습니다."))
                .andExpect(jsonPath("$.result.email").value("me@umc.com"))
                .andExpect(jsonPath("$.result.nickname").value("영화조아"))
                .andExpect(jsonPath("$.result.createdAt").exists())
                .andExpect(jsonPath("$.result.memberId").doesNotExist())
                .andExpect(jsonPath("$.result.password").doesNotExist());
    }

    @Test
    @DisplayName("토큰 없이 내 정보를 조회하면 401과 AUTH401_2를 응답한다")
    void getMyInfoWithoutToken() throws Exception {
        mockMvc.perform(get("/members/me"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("AUTH401_2"));
    }

    @Test
    @DisplayName("지금 쓰는 닉네임을 그대로 보내도 409가 아니라 200이고, 새 닉네임은 DB에 반영된다")
    void updateNickname() throws Exception {
        mockMvc.perform(patch("/members/me").header(HttpHeaders.AUTHORIZATION, token)
                        .contentType(MediaType.APPLICATION_JSON).content("{\"nickname\":\"영화조아\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.nickname").value("영화조아"));

        mockMvc.perform(patch("/members/me").header(HttpHeaders.AUTHORIZATION, token)
                        .contentType(MediaType.APPLICATION_JSON).content("{\"nickname\":\"새로운닉네임\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("회원 정보를 수정했습니다."))
                .andExpect(jsonPath("$.result.nickname").value("새로운닉네임"));

        assertThat(memberRepository.findById(me.getMemberId())).get()
                .extracting(Member::getNickname).isEqualTo("새로운닉네임");
    }

    @Test
    @DisplayName("다른 회원이 쓰는 닉네임으로 바꾸면 409와 MEMBER409_1, 길이 규칙 위반은 400과 COMMON400을 응답한다")
    void updateNicknameFails() throws Exception {
        mockMvc.perform(patch("/members/me").header(HttpHeaders.AUTHORIZATION, token)
                        .contentType(MediaType.APPLICATION_JSON).content("{\"nickname\":\"다른사람\"}"))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("MEMBER409_1"))
                .andExpect(jsonPath("$.message").value("이미 사용 중인 닉네임입니다."));

        mockMvc.perform(patch("/members/me").header(HttpHeaders.AUTHORIZATION, token)
                        .contentType(MediaType.APPLICATION_JSON).content("{\"nickname\":\"a\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("COMMON400"))
                .andExpect(jsonPath("$.message").value("닉네임은 2자 이상 12자 이하여야 합니다."));
    }
}
