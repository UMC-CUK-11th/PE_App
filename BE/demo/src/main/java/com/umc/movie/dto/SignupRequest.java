package com.umc.movie.dto;

import jakarta.validation.constraints.*;
import java.nio.charset.StandardCharsets;

public record SignupRequest(
    @NotBlank(message="이메일을 입력해주세요.")
    @Email(message="올바른 이메일 형식이 아닙니다.")
    @Size(max=254, message="이메일은 254자 이하여야 합니다.") String email,
    @NotBlank(message="닉네임을 입력해주세요.")
    @Size(min=2,max=12,message="닉네임은 2~12자여야 합니다.") String nickname,
    @NotBlank(message="비밀번호를 입력해주세요.")
    @Pattern(regexp="^(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9])(?=.*[^A-Za-z0-9\\s])\\S{8,72}$",
        message="비밀번호는 대문자·소문자·숫자·특수문자를 포함한 8~72자여야 합니다.") String password
) {
    public SignupRequest {
        if (email != null) email = email.strip();
        if (nickname != null) nickname = nickname.strip();
    }
    @AssertTrue(message="비밀번호는 UTF-8 기준 72바이트 이하여야 합니다.")
    public boolean isPasswordWithinBcryptLimit() {
        return password == null || password.getBytes(StandardCharsets.UTF_8).length <= 72;
    }
}
