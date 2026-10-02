package com.umc11th.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
// [04_선택 미션 3] DB에서도 같은 제목이 중복되지 않도록 UNIQUE 제약조건 선언
@Table(
        name = "book",
        uniqueConstraints = @UniqueConstraint(name = "uk_book_title", columnNames = "title")
)
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Book {

    // [04_필수 미션 1] book 테이블의 기본 키를 AUTO_INCREMENT 방식으로 매핑
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "book_id")
    private Long bookId;

    // [04_필수 미션 1] 여러 도서가 하나의 카테고리에 속하는 다대일 관계
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id", nullable = false)
    private Category category;

    @Column(nullable = false, length = 100)
    private String title;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(name = "is_available", nullable = false)
    private Boolean isAvailable = true;

    public Book(Category category, String title, String description) {
        this.category = category;
        this.title = title;
        this.description = description;
    }
}
