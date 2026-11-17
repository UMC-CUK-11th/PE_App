package com.umc.movie.controller;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * 9주차 실습 2·3에서 Swagger 화면으로 클릭하던 순서를 그대로 코드로 옮긴 시나리오 테스트입니다.
 * 회원가입 → 로그인(accessToken) → Authorize → 즐겨찾기 201 → 한 번 더 409 → Logout 후 401
 */
@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class AuthFlowScenarioTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    @DisplayName("가입하고 로그인한 토큰으로 즐겨찾기를 등록하면 201, 다시 하면 409, 토큰을 빼면 401이다")
    void signUpLoginAndFavorite() throws Exception {
        // 실습 2-1: POST /members (Swagger 예시 값 그대로)
        mockMvc.perform(post("/members").contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"challenger@umc.com","password":"Umc1234!","nickname":"영화조아"}"""))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.code").value("COMMON201"));

        // 실습 2-2: POST /auth/login 후 accessToken 복사
        String loginJson = mockMvc.perform(post("/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"challenger@umc.com","password":"Umc1234!"}"""))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.nickname").value("영화조아"))
                .andReturn().getResponse().getContentAsString();
        JsonNode login = objectMapper.readTree(loginJson);
        String authorization = "Bearer " + login.at("/result/accessToken").asText();

        // 실습 3-3: Authorize 후 POST /favorites → 201
        mockMvc.perform(post("/favorites").header(HttpHeaders.AUTHORIZATION, authorization)
                        .contentType(MediaType.APPLICATION_JSON).content("{\"movieId\":550}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.result.movieId").value(550));

        // 실습 3-4: 한 번 더 Execute → 409 FAVORITE409_1
        mockMvc.perform(post("/favorites").header(HttpHeaders.AUTHORIZATION, authorization)
                        .contentType(MediaType.APPLICATION_JSON).content("{\"movieId\":550}"))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("FAVORITE409_1"));

        mockMvc.perform(get("/favorites/550").header(HttpHeaders.AUTHORIZATION, authorization))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.isFavorite").value(true));

        // 실습 3-5: Logout(토큰 없음) → 401 AUTH401_2
        mockMvc.perform(post("/favorites").contentType(MediaType.APPLICATION_JSON).content("{\"movieId\":550}"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("AUTH401_2"));

        // 같은 비밀번호라도 틀리면 AUTH401_1
        mockMvc.perform(post("/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"challenger@umc.com","password":"Wrong1234!"}"""))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("AUTH401_1"));
    }
}
