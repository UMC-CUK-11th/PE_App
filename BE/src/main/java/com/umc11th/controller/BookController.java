package com.umc11th.controller;

import com.umc11th.service.BookService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController // 1. "나는 데이터를 JSON으로 서빙하는 API 카운터야!"
@RequestMapping("/books") // 2. 이 컨트롤러로 들어오는 요청의 기본 주소는 /books
@RequiredArgsConstructor
public class BookController {

    // 주방장(Service)을 주입받아 카운터 옆에 대기시킵니다.
    private final BookService bookService;

    // [실습 1] 도서 전체 목록 조회 API (GET /books)
    // 3. HTTP GET 방식으로 /books 요청이 들어왔을 때 이 메서드가 실행됩니다.
    @GetMapping
    public List<Map<String, Object>> getBooks() {
        return bookService.getAllBooks();
    }

    // [필수 미션 1] 특정 카테고리 도서 목록 조회 API
    // GET http://localhost:8080/books/category/{categoryId}
    @GetMapping("/category/{categoryId}")
    public List<Map<String, Object>> getBooksByCategory(
            @PathVariable("categoryId") Long categoryId
    ) {
        return bookService.getBooksByCategoryId(categoryId);
    }

    // [실습 2] 신규 도서 등록 API (POST /books)
    // POST http://localhost:8080/books
    @PostMapping
    public String createBook(@RequestBody Map<String, Object> body) {
        bookService.createBook(body);
        return "도서 등록이 완료되었습니다!";
    }
}
