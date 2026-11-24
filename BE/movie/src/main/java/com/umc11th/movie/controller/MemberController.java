package com.umc11th.movie.controller;

import com.umc11th.movie.auth.LoginMember;
import com.umc11th.movie.dto.ApiResponse;
import com.umc11th.movie.dto.EmailCheckResponse;
import com.umc11th.movie.dto.MemberResponse;
import com.umc11th.movie.dto.NicknameCheckResponse;
import com.umc11th.movie.dto.SignUpRequest;
import com.umc11th.movie.dto.UpdateNicknameRequest;
import com.umc11th.movie.service.MemberService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Size;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Validated
@RestController
@RequiredArgsConstructor
@RequestMapping({"/members", "/v7/members", "/v8/members"})
@Tag(name = "회원", description = "회원가입, 중복 확인 및 인증 회원 정보 API")
public class MemberController {

    private final MemberService memberService;

    @GetMapping("/me")
    @Operation(summary = "내 정보 조회", description = "Bearer 토큰이 필요합니다.")
    @SecurityRequirement(name = "bearerAuth")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "조회 성공"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", description = "AUTH401_2/AUTH401_3/AUTH401_4 - 인증 실패"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "MEMBER404_1 - 회원 없음")
    })
    public ResponseEntity<ApiResponse<MemberResponse>> getMe(
            @Parameter(hidden = true) @LoginMember Long memberId
    ) {
        return ResponseEntity.ok(ApiResponse.ok(
                "내 정보 조회에 성공했습니다.",
                memberService.getMe(memberId)
        ));
    }

    @PatchMapping("/me")
    @Operation(summary = "내 닉네임 수정", description = "Bearer 토큰이 필요합니다.")
    @SecurityRequirement(name = "bearerAuth")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "수정 성공"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "400", description = "COMMON4001 - 입력값 오류"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", description = "인증 실패"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "409", description = "MEMBER409_2 - 닉네임 중복")
    })
    public ResponseEntity<ApiResponse<MemberResponse>> updateNickname(
            @Parameter(hidden = true) @LoginMember Long memberId,
            @Valid @RequestBody UpdateNicknameRequest request
    ) {
        return ResponseEntity.ok(ApiResponse.ok(
                "닉네임 수정에 성공했습니다.",
                memberService.updateNickname(memberId, request)
        ));
    }

    @GetMapping("/nickname/{nickname}")
    @Operation(summary = "닉네임 중복 확인", description = "토큰이 필요하지 않은 공개 API입니다.")
    public NicknameCheckResponse checkNickname(
            @PathVariable @Size(min = 2, max = 12) String nickname
    ) {
        return memberService.checkNickname(nickname);
    }

    @GetMapping("/email/{email}")
    @Operation(summary = "이메일 중복 확인", description = "토큰이 필요하지 않은 공개 API입니다.")
    public EmailCheckResponse checkEmail(
            @PathVariable @Email @Size(max = 254) String email
    ) {
        return memberService.checkEmail(email);
    }

    @PostMapping
    @Operation(summary = "회원가입", description = "토큰이 필요하지 않은 공개 API입니다. 비밀번호는 응답에 포함하지 않습니다.")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "201", description = "회원가입 성공"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "400",
                    description = "COMMON4001 - 입력값 오류",
                    content = @Content(examples = @ExampleObject(value = """
                            {"isSuccess":false,"code":"COMMON4001","message":"요청 값이 올바르지 않습니다.","result":null}
                            """))
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "409", description = "MEMBER409_1/MEMBER409_2 - 이메일 또는 닉네임 중복")
    })
    public ResponseEntity<ApiResponse<MemberResponse>> signUp(
            @Valid @RequestBody SignUpRequest request
    ) {
        MemberResponse response = memberService.signUp(request);
        return ResponseEntity.status(201)
                .body(ApiResponse.created("회원가입에 성공했습니다.", response));
    }
}
