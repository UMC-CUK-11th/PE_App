package com.umc11th.movie.service;

import com.umc11th.movie.dto.EmailCheckResponse;
import com.umc11th.movie.dto.MemberResponse;
import com.umc11th.movie.dto.NicknameCheckResponse;
import com.umc11th.movie.dto.SignUpRequest;
import com.umc11th.movie.entity.Member;
import com.umc11th.movie.exception.MemberConflictException;
import com.umc11th.movie.repository.MemberRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class MemberService {

    private final MemberRepository memberRepository;
    private final PasswordEncoder passwordEncoder;

    @Transactional(readOnly = true)
    public NicknameCheckResponse checkNickname(String nickname) {
        return new NicknameCheckResponse(!memberRepository.existsByNickname(nickname));
    }

    @Transactional(readOnly = true)
    public EmailCheckResponse checkEmail(String email) {
        return new EmailCheckResponse(!memberRepository.existsByEmail(email));
    }

    @Transactional
    public MemberResponse signUp(SignUpRequest request) {
        if (memberRepository.existsByEmail(request.email())) {
            throw MemberConflictException.duplicateEmail();
        }
        if (memberRepository.existsByNickname(request.nickname())) {
            throw MemberConflictException.duplicateNickname();
        }

        String encodedPassword = passwordEncoder.encode(request.password());
        Member member = new Member(request.email(), encodedPassword, request.nickname());
        return MemberResponse.from(memberRepository.saveAndFlush(member));
    }
}
