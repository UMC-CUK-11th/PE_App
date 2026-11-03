package com.umc.movie.service;
import com.umc.movie.dto.*;
import com.umc.movie.entity.*;
import com.umc.movie.exception.ApiException;
import com.umc.movie.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
@Service
@RequiredArgsConstructor
public class RatingService {
    private final RatingRepository ratingRepository;
    private final MemberRepository memberRepository;
    @Transactional(readOnly=true)
    public List<RatingResponse> getRatingsByMember(Long memberId) {
        if (!memberRepository.existsById(memberId))
            throw new ApiException(HttpStatus.NOT_FOUND,"MEMBER4041","존재하지 않는 유저입니다.");
        return ratingRepository.findByMember_MemberIdOrderByRatingIdDesc(memberId).stream().map(RatingResponse::from).toList();
    }
    @Transactional
    public Long create(Long memberId, CreateRatingRequest request) {
        Member member = memberRepository.findById(memberId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND,"MEMBER4041","존재하지 않는 유저입니다."));
        if (ratingRepository.existsByMember_MemberIdAndMovieId(memberId,request.movieId()))
            throw new ApiException(HttpStatus.CONFLICT,"RATING4091","이미 이 영화에 평점을 남기셨습니다.");
        return ratingRepository.saveAndFlush(new Rating(member,request.movieId(),request.score(),request.comment())).getRatingId();
    }
    @Transactional
    public void update(Long ratingId, Long memberId, UpdateRatingRequest request) {
        Rating rating = findOwnedRating(ratingId,memberId);
        rating.update(request.score(),request.comment());
        ratingRepository.flush();
    }
    @Transactional
    public void delete(Long ratingId, Long memberId) {
        ratingRepository.delete(findOwnedRating(ratingId,memberId));
        ratingRepository.flush();
    }
    private Rating findOwnedRating(Long ratingId, Long memberId) {
        Rating rating = ratingRepository.findById(ratingId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND,"RATING4041","존재하지 않는 평점입니다."));
        if (!rating.getMember().getMemberId().equals(memberId))
            throw new ApiException(HttpStatus.FORBIDDEN,"RATING4031","본인이 작성한 평점만 수정하거나 삭제할 수 있습니다.");
        return rating;
    }
}
