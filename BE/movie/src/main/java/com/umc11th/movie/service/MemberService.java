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
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.nio.charset.StandardCharsets;

@Service
@RequiredArgsConstructor
public class MemberService {

    private static final int BCRYPT_MAX_PASSWORD_BYTES = 72;

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

    @Transactional(readOnly = true)
    public MemberResponse getMe(Long memberId) {
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "존재하지 않는 유저입니다."
                ));
        return MemberResponse.from(member);
    }

    @Transactional
    public MemberResponse signUp(SignUpRequest request) {
        if (request.password().getBytes(StandardCharsets.UTF_8).length
                > BCRYPT_MAX_PASSWORD_BYTES) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "비밀번호는 UTF-8 기준 72바이트 이하로 입력해주세요."
            );
        }
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
