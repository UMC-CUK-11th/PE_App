package com.umc.study.service;

import com.umc.study.repository.RentalRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.Map;

@Service
@RequiredArgsConstructor
public class RentalService {

    private final RentalRepository rentalRepository;

    public void createRental(Map<String, Object> body) {
        Object userId = body.get("userId");
        Object bookId = body.get("bookId");
        if (userId == null || bookId == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "userId와 bookId는 필수입니다.");
        }
        try {
            rentalRepository.save(userId, bookId);
        } catch (DataIntegrityViolationException e) {
            // 존재하지 않는 user_id / book_id → FK 제약조건 위반
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "존재하지 않는 사용자 또는 도서입니다.");
        }
    }

    public void returnRental(Long rentalId) {
        int updated = rentalRepository.markReturned(rentalId);
        if (updated == 0) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "반납할 대여 기록이 없습니다.");
        }
    }
}
