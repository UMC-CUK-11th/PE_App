package com.umc.movie.service;
import com.umc.movie.dto.*;
import com.umc.movie.entity.Member;
import com.umc.movie.exception.ApiException;
import com.umc.movie.repository.MemberRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
@Service
@RequiredArgsConstructor
public class MemberService {
    private final MemberRepository memberRepository;
    private final PasswordEncoder passwordEncoder;
    @Transactional(readOnly=true)
    public NicknameCheckResponse checkNickname(String nickname) {
        return new NicknameCheckResponse(!memberRepository.existsByNickname(nickname.strip()));
    }
    @Transactional(readOnly=true)
    public EmailCheckResponse checkEmail(String email) {
        return new EmailCheckResponse(!memberRepository.existsByEmail(email.strip()));
    }
    /**
     * 이메일과 닉네임 중복을 검사하고 비밀번호를 bcrypt로 해싱해 회원을 저장합니다.
     * 동시 요청으로 사전 검사를 통과해도 DB UNIQUE가 중복 저장을 차단하며,
     * 해당 저장 예외는 트랜잭션 롤백 후 전역 처리기에서 변환합니다.
     *
     * @param request 입력 검증과 공백 정규화를 마친 가입 요청
     * @return 비밀번호와 해시를 제외한 생성 회원 정보
     * @throws ApiException 이메일 또는 닉네임이 이미 사용 중인 경우
     */
    @Transactional
    public SignupResponse signup(SignupRequest request) {
        if (memberRepository.existsByEmail(request.email()))
            throw new ApiException(HttpStatus.CONFLICT,"MEMBER4091","이미 사용 중인 이메일입니다.");
        if (memberRepository.existsByNickname(request.nickname()))
            throw new ApiException(HttpStatus.CONFLICT,"MEMBER4092","이미 사용 중인 닉네임입니다.");
        Member member = new Member(request.email(), passwordEncoder.encode(request.password()), request.nickname());
        return SignupResponse.from(memberRepository.saveAndFlush(member));
    }
}
