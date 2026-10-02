package com.umc11th.controller;

import com.umc11th.service.RentalService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/rentals")
@RequiredArgsConstructor
public class RentalController {

    private final RentalService rentalService;

    // [03_필수 미션 2] 신규 도서 대여 기록 생성 API
    // POST http://localhost:8080/rentals
    @PostMapping
    public String createRental(@RequestBody Map<String, Object> body) {
        rentalService.createRental(body);
        return "도서 대여 기록이 생성되었습니다!";
    }

    // [03_선택 미션 3] 도서 반납 처리 API
    // PATCH http://localhost:8080/rentals/{rentalId}/return
    @PatchMapping("/{rentalId}/return")
    public String returnRental(@PathVariable("rentalId") Long rentalId) {
        rentalService.returnRental(rentalId);
        return "도서 반납 처리가 완료되었습니다!";
    }
}
