package com.umc11th.service;

import com.umc11th.dto.res.BookResponseDTO;
import com.umc11th.dto.req.CreateBookRequestDTO;
import com.umc11th.entity.Book;
import com.umc11th.entity.Category;
import com.umc11th.exception.CategoryNotFoundException;
import com.umc11th.exception.DuplicateBookTitleException;
import com.umc11th.repository.BookRepository;
import com.umc11th.repository.CategoryRepository;
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

    // [04_실습 1] 전체 도서 또는 검색 결과를 응답 DTO로 변환
    // [04_선택 미션 2] keyword가 있으면 제목 검색, 없으면 전체 목록 조회
    @Transactional(readOnly = true)
    public List<BookResponseDTO> getBooks(String keyword) {
        List<Book> books = keyword == null || keyword.isBlank()
                ? bookRepository.findAllByOrderByBookIdDesc()
                : bookRepository.findByTitleContainingIgnoreCaseOrderByBookIdDesc(keyword.trim());

        return books.stream()
                .map(BookResponseDTO::from)
                .toList();
    }

    // [03_필수 미션 1] 카테고리 ID에 해당하는 도서를 ORM으로 조회
    @Transactional(readOnly = true)
    public List<BookResponseDTO> getBooksByCategoryId(Long categoryId) {
        return bookRepository.findByCategory_CategoryIdOrderByBookIdDesc(categoryId).stream()
                .map(BookResponseDTO::from)
                .toList();
    }

    // [04_실습 2, 04_필수 미션 1] 카테고리를 확인하고 새 도서를 저장
    // [04_선택 미션 3] 같은 제목이 존재하면 중복 등록 예외 발생
    @Transactional
    public BookResponseDTO createBook(CreateBookRequestDTO request) {
        Category category = categoryRepository.findById(request.categoryId())
                .orElseThrow(() -> new CategoryNotFoundException(request.categoryId()));

        String title = request.title().trim();
        if (bookRepository.existsByTitleIgnoreCase(title)) {
            throw new DuplicateBookTitleException(title);
        }

        try {
            Book savedBook = bookRepository.saveAndFlush(
                    new Book(category, title, request.description())
            );
            return BookResponseDTO.from(savedBook);
        } catch (DataIntegrityViolationException exception) {
            throw new DuplicateBookTitleException(title);
        }
    }
}
