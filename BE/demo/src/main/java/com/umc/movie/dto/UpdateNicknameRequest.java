package com.umc.movie.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record UpdateNicknameRequest(
    @NotBlank(message = "닉네임을 입력해주세요.")
    @Size(min = 2, max = 12, message = "닉네임은 2~12자여야 합니다.") String nickname
) {
    /** 가입과 같은 닉네임 정규화를 적용합니다. */
    public UpdateNicknameRequest {
        if (nickname != null) nickname = nickname.strip();
    }
}
