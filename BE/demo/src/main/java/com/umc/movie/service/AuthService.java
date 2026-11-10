package com.umc.movie.service;

import com.umc.movie.auth.AuthError;
import com.umc.movie.auth.JwtService;
import com.umc.movie.dto.LoginRequest;
import com.umc.movie.dto.LoginResponse;
import com.umc.movie.entity.Member;
import com.umc.movie.repository.MemberRepository;
import java.nio.charset.StandardCharsets;
import java.util.UUID;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
public class AuthService {
    private final MemberRepository members;
    private final PasswordEncoder passwords;
    private final JwtService tokens;
    private final String dummyHash;

    public AuthService(MemberRepository members, PasswordEncoder passwords, JwtService tokens) {
        this.members = members;
        this.passwords = passwords;
        this.tokens = tokens;
        this.dummyHash = passwords.encode(UUID.randomUUID().toString());
    }

    /** 가입 여부에 상관없이 bcrypt 비교를 수행하고 실패 응답을 통일합니다. */
    public LoginResponse login(LoginRequest request) {
        if (request.password().getBytes(StandardCharsets.UTF_8).length > 72) {
            throw AuthError.BAD_CREDENTIALS.exception();
        }
        var member = members.findByEmail(request.email());
        boolean matches = passwords.matches(request.password(),
            member.map(Member::getPassword).orElse(dummyHash));
        if (!matches || member.isEmpty()) {
            throw AuthError.BAD_CREDENTIALS.exception();
        }
        Member account = member.get();
        return new LoginResponse(account.getNickname(), tokens.issue(account.getMemberId()));
    }
}
