package com.umc.movie.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

/** 로그인은 비밀번호 형식 규칙을 검사하지 않습니다. 규칙이 바뀌기 전에 가입한 회원도 로그인할 수 있어야 하기 때문입니다. */
public record LoginRequest(
        @Schema(description = "가입할 때 사용한 이메일", example = "challenger@umc.com")
        @NotBlank(message = "이메일을 입력해주세요.")
        @Email(message = "이메일 형식이 올바르지 않습니다.")
        String email,

        @Schema(description = "가입할 때 사용한 비밀번호", example = "Umc1234!")
        @NotBlank(message = "비밀번호를 입력해주세요.")
        String password
) {}
