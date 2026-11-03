package com.umc11th.movie.service;

import com.umc11th.movie.dto.MemberResponse;
import com.umc11th.movie.dto.SignUpRequest;
import com.umc11th.movie.entity.Member;
import com.umc11th.movie.exception.MemberConflictException;
import com.umc11th.movie.repository.MemberRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class MemberServiceTest {

    @Mock
    private MemberRepository memberRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @InjectMocks
    private MemberService memberService;

    @Test
    void existingNicknameIsNotAvailable() {
        when(memberRepository.existsByNickname("수현")).thenReturn(true);

        assertThat(memberService.checkNickname("수현").available()).isFalse();
    }

    @Test
    void newEmailIsAvailable() {
        when(memberRepository.existsByEmail("new@umc.com")).thenReturn(false);

        assertThat(memberService.checkEmail("new@umc.com").available()).isTrue();
    }

    @Test
    void signsUpWithEncodedPassword() {
        SignUpRequest request = new SignUpRequest(
                "umc@example.com",
                "Umc!1234",
                "moviefan"
        );
        when(passwordEncoder.encode("Umc!1234")).thenReturn("encoded-password");
        when(memberRepository.saveAndFlush(any(Member.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        MemberResponse response = memberService.signUp(request);

        assertThat(response.email()).isEqualTo("umc@example.com");
        assertThat(response.nickname()).isEqualTo("moviefan");
        verify(passwordEncoder).encode("Umc!1234");
        verify(memberRepository).saveAndFlush(org.mockito.ArgumentMatchers.argThat(member ->
                member.getPassword().equals("encoded-password")
        ));
    }

    @Test
    void rejectsDuplicateEmail() {
        SignUpRequest request = new SignUpRequest(
                "used@example.com",
                "Umc!1234",
                "moviefan"
        );
        when(memberRepository.existsByEmail("used@example.com")).thenReturn(true);

        assertThatThrownBy(() -> memberService.signUp(request))
                .isInstanceOf(MemberConflictException.class)
                .hasMessage("이미 사용 중인 이메일입니다.")
                .satisfies(exception -> assertThat(
                        ((MemberConflictException) exception).getCode()
                ).isEqualTo("MEMBER4091"));
    }

    @Test
    void rejectsDuplicateNicknameWithDifferentCode() {
        SignUpRequest request = new SignUpRequest(
                "new@example.com",
                "Umc!1234",
                "usedNickname"
        );
        when(memberRepository.existsByNickname("usedNickname")).thenReturn(true);

        assertThatThrownBy(() -> memberService.signUp(request))
                .isInstanceOf(MemberConflictException.class)
                .hasMessage("이미 사용 중인 닉네임입니다.")
                .satisfies(exception -> assertThat(
                        ((MemberConflictException) exception).getCode()
                ).isEqualTo("MEMBER4092"));
    }
}
