package com.umc.study.repository;

import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

@Repository
@RequiredArgsConstructor
public class RentalRepository {

    private final JdbcTemplate jdbcTemplate;

    // 미션: 대여 기록 생성 (rented_at = NOW(), due_at = 7일 뒤)
    public int save(Object userId, Object bookId) {
        String sql = "INSERT INTO rental (user_id, book_id, rented_at, due_at, returned_at) "
                + "VALUES (?, ?, NOW(), DATE_ADD(NOW(), INTERVAL 7 DAY), NULL)";
        return jdbcTemplate.update(sql, userId, bookId);
    }

    // 선택 미션: 반납 처리 (이미 반납된 기록은 다시 갱신하지 않음)
    public int markReturned(Long rentalId) {
        String sql = "UPDATE rental SET returned_at = NOW() "
                + "WHERE rental_id = ? AND returned_at IS NULL";
        return jdbcTemplate.update(sql, rentalId);
    }
}
