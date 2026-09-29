package com.umc11th.service;

import com.umc11th.repository.RentalRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.Map;

@Service
@RequiredArgsConstructor
public class RentalService {

    private final RentalRepository rentalRepository;

    // [필수 미션 2] 신규 도서 대여 기록 생성
    public void createRental(Map<String, Object> body) {
        rentalRepository.save(body);
    }

    // [선택 미션 3] 도서 반납 처리
    public void returnRental(Long rentalId) {
        rentalRepository.returnRental(rentalId);
    }
}
