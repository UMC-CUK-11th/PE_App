package com.umc11th.movie.controller;

import com.umc11th.movie.dto.EmailCheckResponse;
import com.umc11th.movie.dto.MemberResponse;
import com.umc11th.movie.dto.NicknameCheckResponse;
import com.umc11th.movie.exception.MemberConflictException;
import com.umc11th.movie.service.MemberService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(MemberController.class)
class MemberControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private MemberService memberService;

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
    void checksEmailAvailability() throws Exception {
        when(memberService.checkEmail("new@umc.com"))
                .thenReturn(new EmailCheckResponse(true));

        mockMvc.perform(get("/members/email/{email}", "new@umc.com"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.available").value(true));
    }

    @Test
    void signsUpMember() throws Exception {
        when(memberService.signUp(org.mockito.ArgumentMatchers.any()))
                .thenReturn(new MemberResponse(1L, "umc@example.com", "moviefan"));

        mockMvc.perform(post("/members")
                        .contentType("application/json")
                        .content("""
                                {
                                  "email": "umc@example.com",
                                  "password": "Umc!1234",
                                  "nickname": "moviefan"
                                }
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.isSuccess").value(true))
                .andExpect(jsonPath("$.code").value("COMMON201"))
                .andExpect(jsonPath("$.message").value("회원가입에 성공했습니다."))
                .andExpect(jsonPath("$.result.memberId").value(1))
                .andExpect(jsonPath("$.result.email").value("umc@example.com"))
                .andExpect(jsonPath("$.result.nickname").value("moviefan"))
                .andExpect(jsonPath("$.result.password").doesNotExist());
    }

    @Test
    void rejectsInvalidSignUpRequestWithCommonErrorResponse() throws Exception {
        mockMvc.perform(post("/members")
                        .contentType("application/json")
                        .content("""
                                {
                                  "email": "not-an-email",
                                  "password": "weak",
                                  "nickname": "a"
                                }
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(content().contentTypeCompatibleWith("application/json"))
                .andExpect(jsonPath("$.isSuccess").value(false))
                .andExpect(jsonPath("$.code").value("COMMON4001"))
                .andExpect(jsonPath("$.message").isNotEmpty())
                .andExpect(jsonPath("$.result").doesNotExist());
    }

    @Test
    void rejectsTooLongEmailDuringSignUpValidation() throws Exception {
        String email = "a".repeat(250) + "@x.com";

        mockMvc.perform(post("/members")
                        .contentType("application/json")
                        .content("""
                                {
                                  "email": "%s",
                                  "password": "Umc!1234",
                                  "nickname": "moviefan"
                                }
                                """.formatted(email)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.isSuccess").value(false))
                .andExpect(jsonPath("$.code").value("COMMON4001"))
                .andExpect(jsonPath("$.message").isNotEmpty());
    }

    @Test
    void rejectsMalformedJsonWithCommonErrorResponse() throws Exception {
        mockMvc.perform(post("/members")
                        .contentType("application/json")
                        .content("{\"email\": \"umc@example.com\","))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.isSuccess").value(false))
                .andExpect(jsonPath("$.code").value("COMMON4001"))
                .andExpect(jsonPath("$.message").value("요청 본문이 올바르지 않습니다."))
                .andExpect(jsonPath("$.result").doesNotExist());
    }

    @Test
    void convertsDatabaseUniqueViolationToConflictResponse() throws Exception {
        when(memberService.signUp(org.mockito.ArgumentMatchers.any()))
                .thenThrow(new DataIntegrityViolationException(
                        "Duplicate entry for key 'uk_member_email'"
                ));

        mockMvc.perform(post("/members")
                        .contentType("application/json")
                        .content("""
                                {
                                  "email": "umc@example.com",
                                  "password": "Umc!1234",
                                  "nickname": "moviefan"
                                }
                                """))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.isSuccess").value(false))
                .andExpect(jsonPath("$.code").value("MEMBER4091"))
                .andExpect(jsonPath("$.message").value("이미 사용 중인 이메일입니다."))
                .andExpect(jsonPath("$.result").doesNotExist());
    }

    @Test
    void distinguishesEmailDuplicateResponse() throws Exception {
        when(memberService.signUp(org.mockito.ArgumentMatchers.any()))
                .thenThrow(MemberConflictException.duplicateEmail());

        performValidSignUp()
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("MEMBER4091"))
                .andExpect(jsonPath("$.message").value("이미 사용 중인 이메일입니다."));
    }

    @Test
    void distinguishesNicknameDuplicateResponse() throws Exception {
        when(memberService.signUp(org.mockito.ArgumentMatchers.any()))
                .thenThrow(MemberConflictException.duplicateNickname());

        performValidSignUp()
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("MEMBER4092"))
                .andExpect(jsonPath("$.message").value("이미 사용 중인 닉네임입니다."));
    }

    @Test
    void convertsNicknameDatabaseUniqueViolationToSameConflictResponse() throws Exception {
        when(memberService.signUp(org.mockito.ArgumentMatchers.any()))
                .thenThrow(new DataIntegrityViolationException(
                        "Duplicate entry for key 'uk_member_nickname'"
                ));

        performValidSignUp()
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("MEMBER4092"))
                .andExpect(jsonPath("$.message").value("이미 사용 중인 닉네임입니다."));
    }

    @Test
    void supportsLegacyGeneratedMemberUniqueConstraintName() throws Exception {
        when(memberService.signUp(org.mockito.ArgumentMatchers.any()))
                .thenThrow(new DataIntegrityViolationException(
                        "Duplicate entry 'legacy@example.com' for key 'member.UK_generated'"
                ));

        performValidSignUp()
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("MEMBER4091"))
                .andExpect(jsonPath("$.message").value("이미 사용 중인 이메일입니다."));
    }

    private org.springframework.test.web.servlet.ResultActions performValidSignUp()
            throws Exception {
        return mockMvc.perform(post("/members")
                .contentType("application/json")
                .content("""
                        {
                          "email": "umc@example.com",
                          "password": "Umc!1234",
                          "nickname": "moviefan"
                        }
                        """));
    }
}
