package com.umc.movie.dto;

public record LoginResponse(String nickname, String accessToken) {
    @Override
    public String toString() {
        return "LoginResponse[accessToken=redacted]";
    }
}
