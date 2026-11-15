package com.umc.movie.repository;

import com.umc.movie.entity.Rating;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface RatingRepository extends JpaRepository<Rating, Long> {

    List<Rating> findByMember_MemberIdOrderByRatingIdDesc(Long memberId);

    // 언더스코어(_)는 rating.member.memberId처럼 연관 엔티티를 따라 들어간다는 뜻입니다.
    boolean existsByMember_MemberIdAndMovieId(Long memberId, Long movieId);
}
