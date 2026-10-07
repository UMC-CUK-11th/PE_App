package com.umc11th.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.umc11th.dto.res.BookResponseDTO;
import com.umc11th.dto.req.CreateBookRequestDTO;
import com.umc11th.exception.CategoryNotFoundException;
import com.umc11th.exception.DuplicateBookTitleException;
import com.umc11th.exception.GlobalExceptionHandler;
import com.umc11th.service.BookService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.validation.beanvalidation.LocalValidatorFactoryBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class BookControllerTest {

    private final ObjectMapper objectMapper = new ObjectMapper();
    private BookService bookService;
    private MockMvc mockMvc;

    @BeforeEach
    void setUp() {
        bookService = mock(BookService.class);
        LocalValidatorFactoryBean validator = new LocalValidatorFactoryBean();
        validator.afterPropertiesSet();

        mockMvc = MockMvcBuilders
                .standaloneSetup(new BookController(bookService))
                .setControllerAdvice(new GlobalExceptionHandler())
                .setValidator(validator)
                .build();
    }

    @Test
    void GET_도서_검색은_응답_DTO를_반환한다() throws Exception {
        when(bookService.getBooks("스프링")).thenReturn(List.of(
                new BookResponseDTO(3L, "스프링 입문", "설명", "개발", true)
        ));

        mockMvc.perform(get("/books").param("keyword", "스프링"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].bookId").value(3))
                .andExpect(jsonPath("$[0].categoryName").value("개발"));
    }

    @Test
    void POST_도서_등록은_201을_반환한다() throws Exception {
        CreateBookRequestDTO request = new CreateBookRequestDTO(1L, "클린 코드", "설명");
        when(bookService.createBook(any(CreateBookRequestDTO.class))).thenReturn(
                new BookResponseDTO(10L, "클린 코드", "설명", "개발", true)
        );

        mockMvc.perform(post("/books")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.bookId").value(10))
                .andExpect(jsonPath("$.title").value("클린 코드"));
    }

    @Test
    void 빈_제목은_400을_반환한다() throws Exception {
        CreateBookRequestDTO request = new CreateBookRequestDTO(1L, " ", "설명");

        mockMvc.perform(post("/books")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("도서 제목은 필수입니다."));

        verify(bookService, never()).createBook(any(CreateBookRequestDTO.class));
    }

    @Test
    void 없는_카테고리는_404를_반환한다() throws Exception {
        when(bookService.createBook(any(CreateBookRequestDTO.class)))
                .thenThrow(new CategoryNotFoundException(999L));

        mockMvc.perform(post("/books")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"categoryId":999,"title":"새 도서","description":"설명"}
                                """))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.message").value(
                        "존재하지 않는 카테고리입니다. categoryId=999"
                ));
    }

    @Test
    void 중복_제목은_409를_반환한다() throws Exception {
        when(bookService.createBook(any(CreateBookRequestDTO.class)))
                .thenThrow(new DuplicateBookTitleException("클린 코드"));

        mockMvc.perform(post("/books")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"categoryId":1,"title":"클린 코드","description":"설명"}
                                """))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.message").value(
                        "이미 등록된 도서 제목입니다. title=클린 코드"
                ));
    }
}
