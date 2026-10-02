package com.umc11th.repository;

import com.umc11th.entity.Book;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface BookRepository extends JpaRepository<Book, Long> {

    // [04_실습 1] 모든 도서를 최신 등록순으로 조회
    @EntityGraph(attributePaths = "category")
    List<Book> findAllByOrderByBookIdDesc();

    // [04_선택 미션 2] 제목에 검색어가 포함된 도서를 최신순으로 조회
    @EntityGraph(attributePaths = "category")
    List<Book> findByTitleContainingIgnoreCaseOrderByBookIdDesc(String keyword);

    // [03_필수 미션 1] 특정 카테고리에 속한 도서를 ORM으로 조회
    @EntityGraph(attributePaths = "category")
    List<Book> findByCategory_CategoryIdOrderByBookIdDesc(Long categoryId);

    // [04_선택 미션 3] 대소문자를 구분하지 않고 중복 제목 확인
    boolean existsByTitleIgnoreCase(String title);
}
