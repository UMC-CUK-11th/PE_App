package com.umc11th.controller;

import com.umc11th.dto.res.BookResponseDTO;
import com.umc11th.dto.req.CreateBookRequestDTO;
import com.umc11th.service.BookService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/books")
@RequiredArgsConstructor
public class BookController {

    private final BookService bookService;

    // [04_실습 1, 04_필수 미션 1] 도서 목록을 최신순으로 반환
    // [04_선택 미션 2] GET /books?keyword=스프링 형태의 제목 검색 지원
    @GetMapping
    public List<BookResponseDTO> getBooks(
            @RequestParam(name = "keyword", required = false) String keyword
    ) {
        return bookService.getBooks(keyword);
    }

    // [03_필수 미션 1] GET /books/category/{categoryId}
    @GetMapping("/category/{categoryId}")
    public List<BookResponseDTO> getBooksByCategory(
            @PathVariable("categoryId") Long categoryId
    ) {
        return bookService.getBooksByCategoryId(categoryId);
    }

    // [04_실습 2, 04_필수 미션 1] 검증된 요청으로 도서를 등록하고 201 반환
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public BookResponseDTO createBook(@Valid @RequestBody CreateBookRequestDTO request) {
        return bookService.createBook(request);
    }
}
