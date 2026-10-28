package com.umc11th.movie.service;

import com.umc11th.movie.dto.RatingResponse;
import com.umc11th.movie.repository.RatingRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class RatingService {

    private static final int MAX_PAGE_SIZE = 100;

    private final RatingRepository ratingRepository;

    @Transactional(readOnly = true)
    public List<RatingResponse> getRatings(Long memberId, int page, int size) {
        int safeSize = Math.min(size, MAX_PAGE_SIZE);
        return ratingRepository
                .findAllByMemberMemberIdOrderByCreatedAtDescRatingIdDesc(
                        memberId,
                        PageRequest.of(page, safeSize)
                )
                .stream()
                .map(RatingResponse::from)
                .toList();
    }
}
