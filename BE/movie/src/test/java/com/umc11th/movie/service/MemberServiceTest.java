package com.umc11th.movie.service;

import com.umc11th.movie.repository.MemberRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class MemberServiceTest {

    @Mock
    private MemberRepository memberRepository;

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
}
