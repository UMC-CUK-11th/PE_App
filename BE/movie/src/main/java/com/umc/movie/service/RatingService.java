package com.umc.movie.service;

import com.umc.movie.dto.CreateRatingRequest;
import com.umc.movie.dto.RatingResponse;
import com.umc.movie.dto.UpdateRatingRequest;
import com.umc.movie.entity.Member;
import com.umc.movie.entity.Rating;
import com.umc.movie.exception.ApiException;
import com.umc.movie.repository.MemberRepository;
import com.umc.movie.repository.RatingRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class RatingService {

    private final RatingRepository ratingRepository;
    private final MemberRepository memberRepository;

    public List<RatingResponse> getRatingsByMember(Long memberId) {
        if (!memberRepository.existsById(memberId)) {
            throw memberNotFound();
        }

        return ratingRepository.findByMember_MemberIdOrderByRatingIdDesc(memberId).stream()
                .map(RatingResponse::from)
                .toList();
    }

    @Transactional
    public Long create(Long memberId, CreateRatingRequest request) {
        Member member = memberRepository.findById(memberId).orElseThrow(this::memberNotFound);

        // (member_id, movie_id) UNIQUE 제약이 최종 방어선이지만, 정해 둔 메시지로 응답하려고 먼저 확인합니다.
        if (ratingRepository.existsByMember_MemberIdAndMovieId(memberId, request.movieId())) {
            throw ApiException.conflict("RATING4091", "이미 이 영화에 평점을 남기셨습니다.");
        }

        Rating rating = Rating.builder()
                .member(member)
                .movieId(request.movieId())
                .score(request.score())
                .comment(request.comment())
                .build();

        return ratingRepository.saveAndFlush(rating).getRatingId();
    }

    @Transactional
    public void update(Long ratingId, Long memberId, UpdateRatingRequest request) {
        // 변경 감지로 트랜잭션이 끝날 때 UPDATE가 실행되고 updated_at도 갱신됩니다.
        findOwnedRating(ratingId, memberId).update(request.score(), request.comment());
    }

    @Transactional
    public void delete(Long ratingId, Long memberId) {
        ratingRepository.delete(findOwnedRating(ratingId, memberId));
    }

    /** 평점이 없으면 404, 요청한 회원의 평점이 아니면 403입니다. */
    private Rating findOwnedRating(Long ratingId, Long memberId) {
        Rating rating = ratingRepository.findById(ratingId)
                .orElseThrow(() -> ApiException.notFound("RATING4041", "존재하지 않는 평점입니다."));

        if (!rating.isWrittenBy(memberId)) {
            throw ApiException.forbidden("RATING4031", "본인이 작성한 평점만 수정하거나 삭제할 수 있습니다.");
        }
        return rating;
    }

    private ApiException memberNotFound() {
        return ApiException.notFound("MEMBER4041", "존재하지 않는 유저입니다.");
    }
}
