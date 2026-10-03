package com.umc.study.service;

import com.umc.study.dto.book.BookResponse;
import com.umc.study.dto.book.CreateBookRequest;
import com.umc.study.entity.Book;
import com.umc.study.entity.Category;
import com.umc.study.exception.CategoryNotFoundException;
import com.umc.study.exception.DuplicateBookTitleException;
import com.umc.study.repository.BookRepository;
import com.umc.study.repository.CategoryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class BookService {

    private final BookRepository bookRepository;
    private final CategoryRepository categoryRepository;

    @Transactional(readOnly = true)
    public List<BookResponse> getBooks(String keyword) {
        List<Book> books = (keyword == null || keyword.isBlank())
                ? bookRepository.findAllByOrderByBookIdDesc()
                : bookRepository.findByTitleContainingOrderByBookIdDesc(keyword.strip());
        return books.stream()
                .map(BookResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<BookResponse> getBooksByCategory(Long categoryId) {
        if (!categoryRepository.existsById(categoryId)) {
            throw new CategoryNotFoundException(categoryId);
        }
        return bookRepository.findAllByCategory_CategoryIdOrderByBookIdDesc(categoryId).stream()
                .map(BookResponse::from)
                .toList();
    }

    @Transactional
    public BookResponse createBook(CreateBookRequest request) {
        Category category = categoryRepository.findById(request.categoryId())
                .orElseThrow(() -> new CategoryNotFoundException(request.categoryId()));

        String title = request.title().strip();
        if (bookRepository.existsByTitle(title)) {
            throw new DuplicateBookTitleException(title);
        }

        Book book = new Book(category, title, request.description());
        try {
            // flush로 INSERT를 즉시 실행해 UNIQUE 위반을 이 메서드 안에서 잡는다 (동시 요청 대비)
            return BookResponse.from(bookRepository.saveAndFlush(book));
        } catch (DataIntegrityViolationException e) {
            throw new DuplicateBookTitleException(title);
        }
    }
}
