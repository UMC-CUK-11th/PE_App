package com.umc.movie.service;

import com.umc.movie.dto.EmailCheckResponse;
import com.umc.movie.dto.MemberInfoResponse;
import com.umc.movie.dto.MemberResponse;
import com.umc.movie.dto.NicknameCheckResponse;
import com.umc.movie.dto.SignUpRequest;
import com.umc.movie.dto.UpdateMemberRequest;
import com.umc.movie.entity.Member;
import com.umc.movie.exception.ApiException;
import com.umc.movie.exception.ErrorCode;
import com.umc.movie.repository.MemberRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class MemberService {

    private final MemberRepository memberRepository;
    private final PasswordEncoder passwordEncoder;

    public NicknameCheckResponse checkNickname(String nickname) {
        return new NicknameCheckResponse(!memberRepository.existsByNickname(nickname));
    }

    public EmailCheckResponse checkEmail(String email) {
        return new EmailCheckResponse(!memberRepository.existsByEmail(email));
    }

    /**
     * 이메일·닉네임 중복을 먼저 확인해 메시지로 구분해 알려 줍니다(code는 둘 다 COMMON409).
     * 동시에 들어온 요청이 이 확인을 함께 통과해도 DB UNIQUE 제약이 막고,
     * GlobalExceptionHandler가 같은 실패 형식(409 COMMON409)으로 바꿉니다.
     */
    @Transactional
    public MemberResponse signUp(SignUpRequest request) {
        if (memberRepository.existsByEmail(request.email())) {
            throw new ApiException(ErrorCode.EMAIL_DUPLICATED);
        }
        if (memberRepository.existsByNickname(request.nickname())) {
            throw new ApiException(ErrorCode.NICKNAME_DUPLICATED);
        }

        Member member = Member.builder()
                .email(request.email())
                .password(passwordEncoder.encode(request.password()))
                .nickname(request.nickname())
                .build();

        // saveAndFlush로 INSERT를 바로 실행해 제약 위반을 이 트랜잭션 안에서 드러냅니다.
        return MemberResponse.from(memberRepository.saveAndFlush(member));
    }

    public MemberInfoResponse getMyInfo(Long memberId) {
        return MemberInfoResponse.from(findMember(memberId));
    }

    /** 수정 가능한 항목은 닉네임뿐입니다. 중복 검사에서 자기 자신은 제외합니다. */
    @Transactional
    public MemberInfoResponse updateMyInfo(Long memberId, UpdateMemberRequest request) {
        Member member = findMember(memberId);
        if (memberRepository.existsByNicknameAndMemberIdNot(request.nickname(), memberId)) {
            throw new ApiException(ErrorCode.MY_NICKNAME_DUPLICATED);
        }
        member.changeNickname(request.nickname());
        return MemberInfoResponse.from(memberRepository.saveAndFlush(member));
    }

    private Member findMember(Long memberId) {
        return memberRepository.findById(memberId)
                .orElseThrow(() -> new ApiException(ErrorCode.MEMBER_NOT_FOUND));
    }
}
