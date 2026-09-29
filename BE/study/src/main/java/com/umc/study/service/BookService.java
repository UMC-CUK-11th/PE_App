package com.umc.study.service;

import com.umc.study.repository.BookRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

@Service
public class BookService {

    private final BookRepository bookRepository;

    public BookService(BookRepository bookRepository) {
        this.bookRepository = bookRepository;
    }

    public List<Map<String, Object>> getBooksByCategory(Long categoryId) {
        // 추후 여기에 "카테고리가 존재하는지 확인" 등의 비즈니스 로직이 추가될 수 있습니다.
        return bookRepository.findBooksByCategoryId(categoryId);
    }
}