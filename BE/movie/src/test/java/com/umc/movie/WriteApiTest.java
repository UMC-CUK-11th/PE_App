package com.umc.movie;

import com.umc.movie.controller.MemberController;
import com.umc.movie.controller.RatingController;
import com.umc.movie.dto.MemberResponse;
import com.umc.movie.dto.RatingResponse;
import com.umc.movie.exception.ApiException;
import com.umc.movie.exception.ErrorCode;
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

import java.time.LocalDateTime;
import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.BDDMockito.given;
import static org.mockito.BDDMockito.then;
import static org.mockito.BDDMockito.willThrow;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/** 회원가입·평점 컨트롤러 슬라이스 테스트(서비스는 Mock). 응답 형식과 검증 규칙만 봅니다. */
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

    private static final LocalDateTime NOW = LocalDateTime.of(2026, 9, 6, 12, 14, 3);

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
    void 비밀번호_규칙을_어기면_400_COMMON400과_이유를_돌려준다() throws Exception {
        mockMvc.perform(post("/members").contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"umc@example.com","password":"password","nickname":"moviefan"}"""))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.isSuccess").value(false))
                .andExpect(jsonPath("$.code").value("COMMON400"))
                .andExpect(jsonPath("$.message").value("비밀번호는 대문자/소문자/숫자/특수문자를 포함한 8자 이상이어야 합니다."))
                .andExpect(jsonPath("$.result").isEmpty());
    }

    @Test
    void 이메일_중복과_DB_제약_위반은_409_COMMON409_같은_형식으로_응답한다() throws Exception {
        given(memberService.signUp(any())).willThrow(new ApiException(ErrorCode.EMAIL_DUPLICATED));
        mockMvc.perform(post("/members").contentType(MediaType.APPLICATION_JSON).content(SIGN_UP))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("COMMON409"))
                .andExpect(jsonPath("$.message").value("이미 사용 중인 이메일입니다."));

        willThrow(new DataIntegrityViolationException("Duplicate entry")).given(memberService).signUp(any());
        mockMvc.perform(post("/members").contentType(MediaType.APPLICATION_JSON).content(SIGN_UP))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.isSuccess").value(false))
                .andExpect(jsonPath("$.code").value("COMMON409"));
    }

    @Test
    void 평점_등록은_토큰의_회원으로_201과_평점_객체_별점_범위_밖이면_400() throws Exception {
        given(ratingService.create(eq(1L), any()))
                .willReturn(new RatingResponse(10L, 550L, 5, "최고", NOW, NOW));
        mockMvc.perform(post("/ratings").header(HttpHeaders.AUTHORIZATION, bearer(1))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"movieId\":550,\"score\":5,\"comment\":\"최고\"}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.message").value("평점을 등록했습니다."))
                .andExpect(jsonPath("$.result.ratingId").value(10))
                .andExpect(jsonPath("$.result.movieId").value(550));

        mockMvc.perform(post("/ratings").header(HttpHeaders.AUTHORIZATION, bearer(1))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"movieId\":550,\"score\":6}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("COMMON400"))
                .andExpect(jsonPath("$.message").value("별점은 5점 이하여야 합니다."));
    }

    @Test
    void 평점_삭제는_200_result_null_남의_평점은_403_없는_평점은_404() throws Exception {
        mockMvc.perform(delete("/ratings/10").header(HttpHeaders.AUTHORIZATION, bearer(1)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("평점을 삭제했습니다."))
                .andExpect(jsonPath("$.result").isEmpty());
        then(ratingService).should().delete(1L, 10L);

        willThrow(new ApiException(ErrorCode.RATING_FORBIDDEN)).given(ratingService).delete(2L, 10L);
        mockMvc.perform(delete("/ratings/10").header(HttpHeaders.AUTHORIZATION, bearer(2)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value("RATING403_1"));

        willThrow(new ApiException(ErrorCode.RATING_NOT_FOUND))
                .given(ratingService).update(eq(1L), eq(999L), any());
        mockMvc.perform(patch("/ratings/999").header(HttpHeaders.AUTHORIZATION, bearer(1))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"score\":3}"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("RATING404_1"))
                .andExpect(jsonPath("$.message").value("해당 평점을 찾을 수 없습니다."));
    }

    @Test
    void 유저별_평점_조회는_토큰_없이_200_직접_배열_없는_회원은_404_MEMBER404_1() throws Exception {
        given(ratingService.getRatingsByMember(1L)).willReturn(List.of(new RatingResponse(10L, 550L, 5, null, NOW, NOW)));
        mockMvc.perform(get("/members/1/ratings"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].ratingId").value(10));

        given(ratingService.getRatingsByMember(999L)).willThrow(new ApiException(ErrorCode.MEMBER_NOT_FOUND));
        mockMvc.perform(get("/members/999/ratings"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("MEMBER404_1"));
    }

    @Test
    void 예전_6주차_쓰기_경로는_토큰과_무관하게_405_COMMON405() throws Exception {
        // 7주차에 memberId가 경로에서 사라졌습니다. GET만 남은 경로라 핸들러 매핑 단계에서
        // 405가 정해지고, 인터셉터(401 판단)까지 가지 않습니다.
        mockMvc.perform(post("/members/1/ratings").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"movieId\":550,\"score\":5}"))
                .andExpect(status().isMethodNotAllowed())
                .andExpect(jsonPath("$.code").value("COMMON405"));

        mockMvc.perform(delete("/members/1/ratings/10").header(HttpHeaders.AUTHORIZATION, bearer(1)))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("COMMON404"));
    }
}
