package com.umc.study.repository;

import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

@Repository
@RequiredArgsConstructor
public class BookRepository {

    private final JdbcTemplate jdbcTemplate;

    public List<Map<String, Object>> findAll() {
        String sql = "SELECT * FROM book";
        return jdbcTemplate.queryForList(sql);
    }

    // 미션: 특정 카테고리 도서 목록 (WHERE category_id = ?)
    public List<Map<String, Object>> findByCategoryId(Long categoryId) {
        String sql = "SELECT book_id, category_id, title, description, is_available "
                + "FROM book WHERE category_id = ? ORDER BY book_id DESC";
        return jdbcTemplate.queryForList(sql, categoryId);
    }

    public void save(Map<String, Object> body) {
        // book_id는 AUTO_INCREMENT이므로 생략, is_available은 기본 true로 삽입
        String sql = "INSERT INTO book (category_id, title, description, is_available) VALUES (?, ?, ?, true)";

        jdbcTemplate.update(
                sql,
                body.get("categoryId"),
                body.get("title"),
                body.get("description")
        );
    }
}
