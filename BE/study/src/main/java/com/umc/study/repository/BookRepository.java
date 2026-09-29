package com.umc.study.repository;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

@Repository // 이제 JpaRepository를 상속받지 않는 순수 클래스입니다.
public class BookRepository {

    private final JdbcTemplate jdbcTemplate;

    public BookRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public List<Map<String, Object>> findBooksByCategoryId(Long categoryId) {
        String sql = "SELECT * FROM book WHERE category_id = ?";
        // queryForList는 결과를 자동으로 Map 형태로 만들어주어 JSON 반환에 유리합니다.
        return jdbcTemplate.queryForList(sql, categoryId);
    }
}