package com.umc.movie.controller;

import com.umc.movie.config.SwaggerConfig;
import com.umc.movie.docs.ApiErrorCodes;
import com.umc.movie.dto.ApiResponse;
import com.umc.movie.dto.EmailCheckResponse;
import com.umc.movie.dto.MemberInfoResponse;
import com.umc.movie.dto.MemberResponse;
import com.umc.movie.dto.NicknameCheckResponse;
import com.umc.movie.dto.SignUpRequest;
import com.umc.movie.dto.UpdateMemberRequest;
import com.umc.movie.exception.ErrorCode;
import com.umc.movie.interceptor.AuthInterceptor;
import com.umc.movie.service.MemberService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Size;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestAttribute;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
@RequestMapping("/members")
@Tag(name = "회원", description = "회원가입·중복 체크(공개)와 내 정보(토큰 필요) API")
public class MemberController {

    private final MemberService memberService;

    // (5주차 선택 미션) 형식이 틀리면 중복 여부를 보기 전에 400으로 응답합니다.
    @Operation(summary = "닉네임 중복 체크",
            description = "공개 API. 성공 응답은 공통 형식으로 감싸지 않고 { available }만 돌려줍니다. 2~12자가 아니면 400.")
    @ApiErrorCodes(ErrorCode.INVALID_INPUT)
    @GetMapping("/nickname/{nickname}")
    public NicknameCheckResponse checkNickname(
            @Parameter(example = "영화조아") @PathVariable @Size(min = 2, max = 12) String nickname
    ) {
        return memberService.checkNickname(nickname);
    }

    @Operation(summary = "이메일 중복 체크",
            description = "공개 API. 성공 응답은 공통 형식으로 감싸지 않고 { available }만 돌려줍니다. 이메일 형식이 아니면 400.")
    @ApiErrorCodes(ErrorCode.INVALID_INPUT)
    @GetMapping("/email/{email}")
    public EmailCheckResponse checkEmail(
            @Parameter(example = "challenger@umc.com") @PathVariable @Email String email
    ) {
        return memberService.checkEmail(email);
    }

    @Operation(
            summary = "회원가입",
            description = "이메일, 비밀번호, 닉네임으로 회원을 등록합니다. 토큰이 없어도 호출할 수 있는 공개 API입니다."
    )
    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "201", description = "COMMON201 회원가입에 성공했습니다.")
    @ApiErrorCodes({ErrorCode.INVALID_INPUT, ErrorCode.EMAIL_DUPLICATED, ErrorCode.NICKNAME_DUPLICATED})
    @PostMapping
    public ResponseEntity<ApiResponse<MemberResponse>> signUp(@Valid @RequestBody SignUpRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.created("회원가입에 성공했습니다.", memberService.signUp(request)));
    }

    @Operation(summary = "내 정보 조회", description = "토큰의 회원 정보를 돌려줍니다. memberId와 password는 담기지 않습니다.")
    @SecurityRequirement(name = SwaggerConfig.BEARER_AUTH)
    @ApiErrorCodes(ErrorCode.MEMBER_NOT_FOUND)
    @GetMapping("/me")
    public ResponseEntity<ApiResponse<MemberInfoResponse>> getMyInfo(
            @Parameter(hidden = true) @RequestAttribute(AuthInterceptor.MEMBER_ID) Long memberId
    ) {
        return ResponseEntity.ok(ApiResponse.ok("회원 정보를 조회했습니다.", memberService.getMyInfo(memberId)));
    }

    @Operation(summary = "내 정보 수정",
            description = "수정 가능한 항목은 닉네임뿐입니다. 중복 검사에서 자기 자신은 제외하므로 지금 쓰는 닉네임을 그대로 보내도 409가 아닙니다.")
    @SecurityRequirement(name = SwaggerConfig.BEARER_AUTH)
    @ApiErrorCodes({ErrorCode.INVALID_INPUT, ErrorCode.MEMBER_NOT_FOUND, ErrorCode.MY_NICKNAME_DUPLICATED})
    @PatchMapping("/me")
    public ResponseEntity<ApiResponse<MemberInfoResponse>> updateMyInfo(
            @Parameter(hidden = true) @RequestAttribute(AuthInterceptor.MEMBER_ID) Long memberId,
            @Valid @RequestBody UpdateMemberRequest request
    ) {
        return ResponseEntity.ok(ApiResponse.ok("회원 정보를 수정했습니다.", memberService.updateMyInfo(memberId, request)));
    }
}
