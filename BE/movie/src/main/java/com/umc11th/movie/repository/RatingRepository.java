package com.umc11th.movie.repository;

import com.umc11th.movie.entity.Rating;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface RatingRepository extends JpaRepository<Rating, Long> {

    Page<Rating> findAllByMemberMemberIdOrderByCreatedAtDescRatingIdDesc(
            Long memberId,
            Pageable pageable
    );
}
