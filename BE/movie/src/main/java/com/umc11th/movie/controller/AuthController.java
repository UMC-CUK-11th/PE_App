package com.umc11th.movie.controller;

import com.umc11th.movie.dto.ApiResponse;
import com.umc11th.movie.dto.LoginRequest;
import com.umc11th.movie.dto.LoginResponse;
import com.umc11th.movie.service.AuthService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
@RequestMapping({"/auth", "/v7/auth", "/v8/auth"})
@Tag(name = "인증", description = "토큰 없이 호출하는 공개 인증 API")
public class AuthController {

    private final AuthService authService;

    @PostMapping("/login")
    @Operation(summary = "로그인", description = "공개 API입니다. 이메일과 비밀번호가 일치하면 Bearer accessToken을 발급합니다.")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "200",
                    description = "로그인 성공"
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "400",
                    description = "COMMON4001 - 입력값 오류",
                    content = @Content(examples = @ExampleObject(value = """
                            {"isSuccess":false,"code":"COMMON4001","message":"요청 값이 올바르지 않습니다.","result":null}
                            """))
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "401",
                    description = "AUTH401_1 - 이메일 또는 비밀번호 불일치"
            )
    })
    public ResponseEntity<ApiResponse<LoginResponse>> login(
            @Valid @RequestBody LoginRequest request
    ) {
        return ResponseEntity.ok(ApiResponse.ok(
                "로그인에 성공했습니다.",
                authService.login(request)
        ));
    }
}
