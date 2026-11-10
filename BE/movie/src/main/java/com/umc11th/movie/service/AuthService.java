package com.umc11th.movie.service;

import com.umc11th.movie.auth.JwtTokenProvider;
import com.umc11th.movie.dto.LoginRequest;
import com.umc11th.movie.dto.LoginResponse;
import com.umc11th.movie.entity.Member;
import com.umc11th.movie.exception.AuthException;
import com.umc11th.movie.repository.MemberRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final MemberRepository memberRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;

    @Transactional(readOnly = true)
    public LoginResponse login(LoginRequest request) {
        Member member = memberRepository.findByEmail(request.email())
                .orElseThrow(AuthException::invalidCredentials);
        if (!passwordEncoder.matches(request.password(), member.getPassword())) {
            throw AuthException.invalidCredentials();
        }
        return new LoginResponse(jwtTokenProvider.createAccessToken(member.getMemberId()));
    }
}
