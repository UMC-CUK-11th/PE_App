package com.umc.study.entity;

import jakarta.persistence.*;
import lombok.Getter; // 👈 1. 임포트 추가

@Entity
@Getter // 👈 2. 이 어노테이션을 추가합니다! (스프링이 안의 데이터를 읽을 수 있게 해줍니다)
public class Book {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String title;
    private String author;

    @Column(name = "category_id")
    private Long categoryId;
}