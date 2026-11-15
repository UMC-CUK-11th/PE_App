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
    /**
     * 이메일과 닉네임의 앞뒤 공백을 제거한 가입 요청을 구성합니다.
     * null은 그대로 두어 Bean Validation이 필수값 누락을 처리하게 하며 비밀번호는 변경하지 않습니다.
     *
     * @param email 정규화할 이메일
     * @param nickname 정규화할 닉네임
     * @param password 공백 제거 없이 검증하고 해싱할 원문 비밀번호
     */
    public SignupRequest {
        if (email != null) email = email.strip();
        if (nickname != null) nickname = nickname.strip();
    }
    /**
     * bcrypt가 처리할 수 있는 비밀번호의 UTF-8 바이트 길이를 검사합니다.
     * null 여부는 별도의 NotBlank 검증이 담당합니다.
     *
     * @return null이거나 UTF-8 인코딩 결과가 72바이트 이하이면 true
     */
    @AssertTrue(message="비밀번호는 UTF-8 기준 72바이트 이하여야 합니다.")
    public boolean isPasswordWithinBcryptLimit() {
        return password == null || password.getBytes(StandardCharsets.UTF_8).length <= 72;
    }
}
