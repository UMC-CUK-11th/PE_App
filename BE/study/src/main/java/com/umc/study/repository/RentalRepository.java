package com.umc.study.repository;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

@Repository
public class RentalRepository {

    private final JdbcTemplate jdbcTemplate;

    public RentalRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public void createRentalRecord(Long userId, Long bookId) {
        String sql = "INSERT INTO rental (user_id, book_id, rented_at, due_at) " +
                "VALUES (?, ?, NOW(), DATE_ADD(NOW(), INTERVAL 7 DAY))";

        // update 메서드의 파라미터로 SQL과 물음표(?)에 들어갈 값들을 순서대로 넣어줍니다.
        jdbcTemplate.update(sql, userId, bookId);
    }
}