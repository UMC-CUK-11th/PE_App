package com.umc11th.service;

import com.umc11th.dto.res.BookResponseDTO;
import com.umc11th.dto.req.CreateBookRequestDTO;
import com.umc11th.entity.Book;
import com.umc11th.entity.Category;
import com.umc11th.exception.CategoryNotFoundException;
import com.umc11th.exception.DuplicateBookTitleException;
import com.umc11th.repository.BookRepository;
import com.umc11th.repository.CategoryRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.dao.DataIntegrityViolationException;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class BookServiceTest {

    private BookRepository bookRepository;
    private CategoryRepository categoryRepository;
    private BookService bookService;

    @BeforeEach
    void setUp() {
        bookRepository = mock(BookRepository.class);
        categoryRepository = mock(CategoryRepository.class);
        bookService = new BookService(bookRepository, categoryRepository);
    }

    @Test
    void 전체_목록은_최신순_조회_결과를_DTO로_반환한다() {
        Book book = book(2L, "스프링 입문", "개발", true);
        when(bookRepository.findAllByOrderByBookIdDesc()).thenReturn(List.of(book));

        List<BookResponseDTO> result = bookService.getBooks(null);

        assertThat(result).containsExactly(
                new BookResponseDTO(2L, "스프링 입문", "설명", "개발", true)
        );
    }

    @Test
    void 검색어가_있으면_제목_포함_검색을_사용한다() {
        when(bookRepository.findByTitleContainingIgnoreCaseOrderByBookIdDesc("스프링"))
                .thenReturn(List.of());

        bookService.getBooks("  스프링  ");

        verify(bookRepository)
                .findByTitleContainingIgnoreCaseOrderByBookIdDesc("스프링");
    }

    @Test
    void 정상_요청은_도서를_저장한다() {
        Category category = mock(Category.class);
        when(category.getName()).thenReturn("개발");
        when(categoryRepository.findById(1L)).thenReturn(Optional.of(category));
        when(bookRepository.existsByTitleIgnoreCase("클린 코드")).thenReturn(false);
        when(bookRepository.saveAndFlush(any(Book.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        BookResponseDTO response = bookService.createBook(
                new CreateBookRequestDTO(1L, "  클린 코드  ", "애자일 소프트웨어 장인 정신")
        );

        assertThat(response.title()).isEqualTo("클린 코드");
        assertThat(response.categoryName()).isEqualTo("개발");
        assertThat(response.isAvailable()).isTrue();
    }

    @Test
    void 없는_카테고리는_예외를_발생시킨다() {
        when(categoryRepository.findById(999L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> bookService.createBook(
                new CreateBookRequestDTO(999L, "새 도서", null)
        )).isInstanceOf(CategoryNotFoundException.class);
    }

    @Test
    void 중복_제목은_예외를_발생시킨다() {
        when(categoryRepository.findById(1L)).thenReturn(Optional.of(mock(Category.class)));
        when(bookRepository.existsByTitleIgnoreCase("클린 코드")).thenReturn(true);

        assertThatThrownBy(() -> bookService.createBook(
                new CreateBookRequestDTO(1L, "클린 코드", null)
        )).isInstanceOf(DuplicateBookTitleException.class);
    }

    @Test
    void 저장_시점의_중복_제약조건_위반도_중복_제목_예외로_변환한다() {
        when(categoryRepository.findById(1L)).thenReturn(Optional.of(mock(Category.class)));
        when(bookRepository.existsByTitleIgnoreCase("클린 코드")).thenReturn(false);
        when(bookRepository.saveAndFlush(any(Book.class)))
                .thenThrow(new DataIntegrityViolationException("duplicate title"));

        assertThatThrownBy(() -> bookService.createBook(
                new CreateBookRequestDTO(1L, "클린 코드", null)
        )).isInstanceOf(DuplicateBookTitleException.class);
    }

    private Book book(Long id, String title, String categoryName, boolean available) {
        Category category = mock(Category.class);
        when(category.getName()).thenReturn(categoryName);

        Book book = mock(Book.class);
        when(book.getBookId()).thenReturn(id);
        when(book.getTitle()).thenReturn(title);
        when(book.getDescription()).thenReturn("설명");
        when(book.getCategory()).thenReturn(category);
        when(book.getIsAvailable()).thenReturn(available);
        return book;
    }
}
