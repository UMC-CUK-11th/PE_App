package com.umc.movie.service;

import com.umc.movie.dto.CreateRatingRequest;
import com.umc.movie.dto.RatingResponse;
import com.umc.movie.dto.UpdateRatingRequest;
import com.umc.movie.entity.Member;
import com.umc.movie.entity.Rating;
import com.umc.movie.exception.ApiException;
import com.umc.movie.exception.ErrorCode;
import com.umc.movie.repository.MemberRepository;
import com.umc.movie.repository.RatingRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/** 7주차 이후 쓰기 API는 요청에 memberId를 받지 않고, 토큰의 회원(memberId)만 다룹니다. */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class RatingService {

    private final RatingRepository ratingRepository;
    private final MemberRepository memberRepository;

    public List<RatingResponse> getRatingsByMember(Long memberId) {
        if (!memberRepository.existsById(memberId)) {
            throw new ApiException(ErrorCode.MEMBER_NOT_FOUND);
        }

        return ratingRepository.findByMember_MemberIdOrderByRatingIdDesc(memberId).stream()
                .map(RatingResponse::from)
                .toList();
    }

    @Transactional
    public RatingResponse create(Long memberId, CreateRatingRequest request) {
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new ApiException(ErrorCode.MEMBER_NOT_FOUND));

        // (member_id, movie_id) UNIQUE 제약이 최종 방어선이지만, 정해 둔 code로 응답하려고 먼저 확인합니다.
        if (ratingRepository.existsByMember_MemberIdAndMovieId(memberId, request.movieId())) {
            throw new ApiException(ErrorCode.RATING_DUPLICATED);
        }

        Rating rating = Rating.builder()
                .member(member)
                .movieId(request.movieId())
                .score(request.score())
                .comment(request.comment())
                .build();

        return RatingResponse.from(ratingRepository.saveAndFlush(rating));
    }

    /** PATCH지만 전체 교체입니다. comment를 빼고 보내면 기존 후기가 null로 덮입니다. */
    @Transactional
    public RatingResponse update(Long memberId, Long ratingId, UpdateRatingRequest request) {
        Rating rating = findOwnedRating(memberId, ratingId);
        rating.update(request.score(), request.comment());
        // flush 시점에 @UpdateTimestamp가 updatedAt을 갱신하므로, 응답에 새 값을 담으려고 먼저 flush합니다.
        return RatingResponse.from(ratingRepository.saveAndFlush(rating));
    }

    @Transactional
    public void delete(Long memberId, Long ratingId) {
        ratingRepository.delete(findOwnedRating(memberId, ratingId));
    }

    /** 평점이 없으면 404 RATING404_1, 토큰의 회원이 작성한 평점이 아니면 403 RATING403_1입니다. */
    private Rating findOwnedRating(Long memberId, Long ratingId) {
        Rating rating = ratingRepository.findById(ratingId)
                .orElseThrow(() -> new ApiException(ErrorCode.RATING_NOT_FOUND));

        if (!rating.isWrittenBy(memberId)) {
            throw new ApiException(ErrorCode.RATING_FORBIDDEN);
        }
        return rating;
    }
}
