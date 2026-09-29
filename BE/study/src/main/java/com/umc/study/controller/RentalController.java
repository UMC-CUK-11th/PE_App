package com.umc.study.controller;

import com.umc.study.dto.RentalRequest;
import com.umc.study.repository.RentalRepository; // <--- 이 부분이 핵심입니다!
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class RentalController {

    private final RentalRepository rentalRepository;

    public RentalController(RentalRepository rentalRepository) {
        this.rentalRepository = rentalRepository;
    }

    // POST /rentals
    @PostMapping("/rentals")
    public String rentBook(@RequestBody RentalRequest request) {
        rentalRepository.createRentalRecord(request.getUserId(), request.getBookId());
        return "도서 대여 기록이 성공적으로 저장되었습니다.";
    }
}