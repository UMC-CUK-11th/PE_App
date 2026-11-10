package com.umc.movie.controller;
import com.umc.movie.dto.*;
import com.umc.movie.service.MemberService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
@RestController
@RequiredArgsConstructor
@RequestMapping("/members")
public class MemberController {
    private final MemberService memberService;
    @GetMapping("/nickname")
    public NicknameCheckResponse checkNickname(@RequestParam("nickname") String nickname) {
        return memberService.checkNickname(nickname);
    }
    // 이전 주차 경로 호환용. 특수문자가 있는 값은 쿼리 API를 사용합니다.
    @GetMapping("/nickname/{nickname}")
    public NicknameCheckResponse checkNicknameLegacy(@PathVariable String nickname) {
        return memberService.checkNickname(nickname);
    }
    @GetMapping("/email")
    public EmailCheckResponse checkEmail(@RequestParam("email") String email) {
        return memberService.checkEmail(email);
    }
    @GetMapping("/email/{email}")
    public EmailCheckResponse checkEmailLegacy(@PathVariable String email) {
        return memberService.checkEmail(email);
    }
    @PostMapping
    public ResponseEntity<ApiResponse<SignupResponse>> signup(@Valid @RequestBody SignupRequest request, HttpServletRequest http) {
        http.setAttribute("signup.email",request.email());
        http.setAttribute("signup.nickname",request.nickname());
        return ResponseEntity.status(201).body(ApiResponse.created("회원가입에 성공했습니다.",memberService.signup(request)));
    }
}
