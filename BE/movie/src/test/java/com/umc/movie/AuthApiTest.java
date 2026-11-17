package com.umc.movie;

import com.umc.movie.controller.AuthController;
import com.umc.movie.controller.FavoriteController;
import com.umc.movie.dto.LoginResponse;
import com.umc.movie.exception.ApiException;
import com.umc.movie.jwt.JwtProvider;
import com.umc.movie.service.AuthService;
import com.umc.movie.service.FavoriteService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/** 7주차 선행: 로그인과 AuthInterceptor의 401 코드 구분 */
@WebMvcTest({AuthController.class, FavoriteController.class})
@Import(JwtProvider.class)
class AuthApiTest {

    @Autowired
    MockMvc mockMvc;

    @Autowired
    JwtProvider jwtProvider;

    @Value("${jwt.secret}")
    String secret;

    @MockitoBean
    AuthService authService;

    @MockitoBean
    FavoriteService favoriteService;

    private static final String LOGIN = """
            {"email":"umc@example.com","password":"Umc!1234"}""";

    @Test
    void 로그인_성공은_200과_nickname_accessToken_memberId는_없음() throws Exception {
        String token = jwtProvider.createAccessToken(7L);
        given(authService.login(any())).willReturn(new LoginResponse("moviefan", token));

        mockMvc.perform(post("/auth/login").contentType(MediaType.APPLICATION_JSON).content(LOGIN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value("COMMON200"))
                .andExpect(jsonPath("$.result.nickname").value("moviefan"))
                .andExpect(jsonPath("$.result.accessToken").value(token))
                .andExpect(jsonPath("$.result.memberId").doesNotExist());

        assertThat(jwtProvider.getMemberId(token)).isEqualTo(7L);
    }

    @Test
    void 로그인_실패는_401_AUTH401_1() throws Exception {
        given(authService.login(any())).willThrow(new ApiException(HttpStatus.UNAUTHORIZED, "AUTH401_1",
                "이메일 또는 비밀번호가 올바르지 않습니다."));

        mockMvc.perform(post("/auth/login").contentType(MediaType.APPLICATION_JSON).content(LOGIN))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.isSuccess").value(false))
                .andExpect(jsonPath("$.code").value("AUTH401_1"))
                .andExpect(jsonPath("$.message").value("이메일 또는 비밀번호가 올바르지 않습니다."));
    }

    @Test
    void 보호_API는_토큰_없음_무효_만료를_각각_AUTH401_2_3_4로_구분() throws Exception {
        mockMvc.perform(get("/favorites"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("AUTH401_2"))
                .andExpect(jsonPath("$.result").isEmpty());

        mockMvc.perform(get("/favorites").header(HttpHeaders.AUTHORIZATION, "Bearer not.a.jwt"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("AUTH401_3"));

        String otherKeyToken = new JwtProvider("another-secret-another-secret-another-secret", 3600)
                .createAccessToken(1L);
        mockMvc.perform(get("/favorites").header(HttpHeaders.AUTHORIZATION, "Bearer " + otherKeyToken))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("AUTH401_3"));

        String expired = new JwtProvider(secret, -60).createAccessToken(1L);
        mockMvc.perform(get("/favorites").header(HttpHeaders.AUTHORIZATION, "Bearer " + expired))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("AUTH401_4"));
    }

    @Test
    void 유효한_토큰이면_토큰의_memberId로_조회한다() throws Exception {
        given(favoriteService.getMyFavorites(5L)).willReturn(List.of());

        mockMvc.perform(get("/favorites").header(HttpHeaders.AUTHORIZATION, "Bearer " + jwtProvider.createAccessToken(5L)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result").isArray());
    }
}
