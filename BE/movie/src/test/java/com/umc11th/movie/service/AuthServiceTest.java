package com.umc11th.movie.service;

import com.umc11th.movie.auth.JwtTokenProvider;
import com.umc11th.movie.dto.LoginRequest;
import com.umc11th.movie.dto.LoginResponse;
import com.umc11th.movie.entity.Member;
import com.umc11th.movie.exception.AuthException;
import com.umc11th.movie.repository.MemberRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private MemberRepository memberRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private JwtTokenProvider jwtTokenProvider;

    @InjectMocks
    private AuthService authService;

    @Test
    void logsInWithEncodedPassword() {
        Member member = mock(Member.class);
        when(member.getMemberId()).thenReturn(1L);
        when(member.getPassword()).thenReturn("encoded-password");
        when(memberRepository.findByEmail("umc@example.com"))
                .thenReturn(Optional.of(member));
        when(passwordEncoder.matches("Umc!1234", "encoded-password")).thenReturn(true);
        when(jwtTokenProvider.createAccessToken(1L)).thenReturn("access-token");

        LoginResponse response = authService.login(
                new LoginRequest("umc@example.com", "Umc!1234")
        );

        assertThat(response.accessToken()).isEqualTo("access-token");
    }

    @Test
    void doesNotRevealWhetherEmailOrPasswordWasWrong() {
        when(memberRepository.findByEmail("missing@example.com"))
                .thenReturn(Optional.empty());

        assertThatThrownBy(() -> authService.login(
                new LoginRequest("missing@example.com", "wrong-password")
        ))
                .isInstanceOf(AuthException.class)
                .hasMessage("이메일 또는 비밀번호가 올바르지 않습니다.");
    }
}
