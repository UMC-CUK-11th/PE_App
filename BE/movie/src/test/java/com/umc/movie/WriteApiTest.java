package com.umc.movie;

import com.umc.movie.controller.MemberController;
import com.umc.movie.controller.RatingController;
import com.umc.movie.dto.MemberResponse;
import com.umc.movie.exception.ApiException;
import com.umc.movie.jwt.JwtProvider;
import com.umc.movie.service.MemberService;
import com.umc.movie.service.RatingService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.BDDMockito.given;
import static org.mockito.BDDMockito.willThrow;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest({MemberController.class, RatingController.class})
@Import(JwtProvider.class)
class WriteApiTest {

    @Autowired
    MockMvc mockMvc;

    @Autowired
    JwtProvider jwtProvider;

    @MockitoBean
    MemberService memberService;

    @MockitoBean
    RatingService ratingService;

    private static final String SIGN_UP = """
            {"email":"umc@example.com","password":"Umc!1234","nickname":"moviefan"}""";

    private String bearer(long memberId) {
        return "Bearer " + jwtProvider.createAccessToken(memberId);
    }

    @Test
    void 회원가입_성공은_201과_password_없는_결과를_돌려준다() throws Exception {
        given(memberService.signUp(any())).willReturn(new MemberResponse(3L, "umc@example.com", "moviefan"));

        mockMvc.perform(post("/members").contentType(MediaType.APPLICATION_JSON).content(SIGN_UP))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.isSuccess").value(true))
                .andExpect(jsonPath("$.code").value("COMMON201"))
                .andExpect(jsonPath("$.result.memberId").value(3))
                .andExpect(jsonPath("$.result.password").doesNotExist());
    }

    @Test
    void 비밀번호_규칙을_어기면_400과_이유를_돌려준다() throws Exception {
        mockMvc.perform(post("/members").contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"umc@example.com","password":"password","nickname":"moviefan"}"""))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.isSuccess").value(false))
                .andExpect(jsonPath("$.code").value("COMMON4001"))
                .andExpect(jsonPath("$.message").value("비밀번호는 대문자/소문자/숫자/특수문자를 포함한 8자 이상이어야 합니다."))
                .andExpect(jsonPath("$.result").isEmpty());
    }

    @Test
    void 이메일_중복과_DB_제약_위반은_409_같은_형식으로_응답한다() throws Exception {
        given(memberService.signUp(any())).willThrow(ApiException.conflict("MEMBER4091", "이미 사용 중인 이메일입니다."));
        mockMvc.perform(post("/members").contentType(MediaType.APPLICATION_JSON).content(SIGN_UP))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("MEMBER4091"));

        willThrow(new DataIntegrityViolationException("Duplicate entry")).given(memberService).signUp(any());
        mockMvc.perform(post("/members").contentType(MediaType.APPLICATION_JSON).content(SIGN_UP))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.isSuccess").value(false))
                .andExpect(jsonPath("$.code").value("COMMON4091"));
    }

    @Test
    void 평점_등록은_201과_ratingId_별점_범위_밖이면_400() throws Exception {
        given(ratingService.create(eq(1L), any())).willReturn(10L);
        mockMvc.perform(post("/members/1/ratings").header(HttpHeaders.AUTHORIZATION, bearer(1))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"movieId\":550,\"score\":5,\"comment\":\"최고\"}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.result").value(10));

        mockMvc.perform(post("/members/1/ratings").header(HttpHeaders.AUTHORIZATION, bearer(1))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"movieId\":550,\"score\":6}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("별점은 5점 이하여야 합니다."));
    }

    @Test
    void 평점_삭제는_204_다른_회원은_403_없는_평점은_404() throws Exception {
        mockMvc.perform(delete("/members/1/ratings/10").header(HttpHeaders.AUTHORIZATION, bearer(1)))
                .andExpect(status().isNoContent());

        willThrow(ApiException.forbidden("RATING4031", "본인이 작성한 평점만 수정하거나 삭제할 수 있습니다."))
                .given(ratingService).delete(10L, 2L);
        mockMvc.perform(delete("/members/2/ratings/10").header(HttpHeaders.AUTHORIZATION, bearer(2)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value("RATING4031"));

        willThrow(ApiException.notFound("RATING4041", "존재하지 않는 평점입니다."))
                .given(ratingService).update(eq(999L), eq(1L), any());
        mockMvc.perform(patch("/members/1/ratings/999").header(HttpHeaders.AUTHORIZATION, bearer(1))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"score\":3}"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("RATING4041"));
    }

    @Test
    void 평점_쓰기는_토큰이_없으면_401_다른_회원_경로면_403_조회는_공개() throws Exception {
        mockMvc.perform(post("/members/1/ratings").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"movieId\":550,\"score\":5}"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("AUTH401_2"));

        mockMvc.perform(delete("/members/1/ratings/10").header(HttpHeaders.AUTHORIZATION, bearer(2)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value("AUTH403_1"));

        mockMvc.perform(get("/members/1/ratings")).andExpect(status().isOk());
    }
}
