package com.umc11th.movie.controller;

import com.umc11th.movie.auth.LoginMember;
import com.umc11th.movie.dto.ApiResponse;
import com.umc11th.movie.dto.EmailCheckResponse;
import com.umc11th.movie.dto.MemberResponse;
import com.umc11th.movie.dto.NicknameCheckResponse;
import com.umc11th.movie.dto.SignUpRequest;
import com.umc11th.movie.service.MemberService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Size;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Validated
@RestController
@RequiredArgsConstructor
@RequestMapping("/members")
public class MemberController {

    private final MemberService memberService;

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<MemberResponse>> getMe(
            @LoginMember Long memberId
    ) {
        return ResponseEntity.ok(ApiResponse.ok(
                "내 정보 조회에 성공했습니다.",
                memberService.getMe(memberId)
        ));
    }

    @GetMapping("/nickname/{nickname}")
    public NicknameCheckResponse checkNickname(
            @PathVariable @Size(min = 2, max = 12) String nickname
    ) {
        return memberService.checkNickname(nickname);
    }

    @GetMapping("/email/{email}")
    public EmailCheckResponse checkEmail(
            @PathVariable @Email @Size(max = 254) String email
    ) {
        return memberService.checkEmail(email);
    }

    @PostMapping
    public ResponseEntity<ApiResponse<MemberResponse>> signUp(
            @Valid @RequestBody SignUpRequest request
    ) {
        MemberResponse response = memberService.signUp(request);
        return ResponseEntity.status(201)
                .body(ApiResponse.created("회원가입에 성공했습니다.", response));
    }
}
