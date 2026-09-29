package com.umc11th.service;

import com.umc11th.repository.BookRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

@Service // 비즈니스 로직을 수행하는 메인 셰프 계층
@RequiredArgsConstructor
public class BookService {

    // 창고지기(Repository)를 생성자 주입으로 데려옵니다.
    private final BookRepository bookRepository;

    // [실습 1] 도서 전체 목록 조회 API (GET /books)
    public List<Map<String, Object>> getAllBooks() {
        // 지금은 별도 가공 없이 창고지기가 가져온 도서 목록을 그대로 반환합니다.
        return bookRepository.findAll();
    }

    // [필수 미션 1] 특정 카테고리 도서 목록 조회
    public List<Map<String, Object>> getBooksByCategoryId(Long categoryId) {
        return bookRepository.findByCategoryId(categoryId);
    }

    // [실습 2] 신규 도서 등록 API (POST /books)
    public void createBook(Map<String, Object> body) {
        bookRepository.save(body);
    }
}
