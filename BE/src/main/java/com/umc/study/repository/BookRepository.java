package com.umc.study.repository;

import com.umc.study.entity.Book;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface BookRepository extends JpaRepository<Book, Long> {

    // category를 함께 가져와 목록 조회 시 N+1 쿼리를 막는다
    @EntityGraph(attributePaths = "category")
    List<Book> findAllByOrderByBookIdDesc();

    @EntityGraph(attributePaths = "category")
    List<Book> findAllByCategory_CategoryIdOrderByBookIdDesc(Long categoryId);

    // 선택 미션: 제목 검색 (LIKE '%keyword%')
    @EntityGraph(attributePaths = "category")
    List<Book> findByTitleContainingOrderByBookIdDesc(String keyword);

    // 선택 미션: 중복 제목 확인
    boolean existsByTitle(String title);
}
