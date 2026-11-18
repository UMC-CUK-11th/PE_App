package com.umc.movie.entity;

import jakarta.persistence.Column;
import jakarta.persistence.MappedSuperclass;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import lombok.Getter;

import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;

/**
 * Member·Rating·Favorite이 공통으로 갖는 생성/수정 시각입니다.
 * MySQL DATETIME은 소수 초를 저장하지 않고 "반올림"합니다(03:59:06.84 → 03:59:07).
 * 메모리 값(마이크로초)과 DB 값이 달라져 수정 응답에서 updatedAt이 createdAt보다 앞서 보이는 일이 있어,
 * 저장 전에 초 단위로 잘라 응답과 DB가 같은 값을 갖게 합니다(9주차 curl 점검에서 발견).
 */
@Getter
@MappedSuperclass
public abstract class BaseTimeEntity {

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    void onCreate() {
        LocalDateTime now = now();
        this.createdAt = now;
        this.updatedAt = now;
    }

    @PreUpdate
    void onUpdate() {
        this.updatedAt = now();
    }

    private static LocalDateTime now() {
        return LocalDateTime.now().truncatedTo(ChronoUnit.SECONDS);
    }
}
