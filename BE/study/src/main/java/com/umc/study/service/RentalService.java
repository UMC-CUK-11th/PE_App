package com.umc.study.service;

import com.umc.study.repository.RentalRepository;
import org.springframework.stereotype.Service;

@Service
public class RentalService {

    private final RentalRepository rentalRepository;

    public RentalService(RentalRepository rentalRepository) {
        this.rentalRepository = rentalRepository;
    }

    public void rentBook(Long userId, Long bookId) {
        rentalRepository.createRentalRecord(userId, bookId);
    }
}