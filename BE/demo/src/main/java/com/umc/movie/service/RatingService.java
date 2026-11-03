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
    /**
     * 존재하는 회원의 평점만 평점 ID 내림차순으로 조회합니다.
     *
     * @param memberId 조회할 회원 ID
     * @return 최신 등록순 평점 목록; 평점이 없으면 빈 목록
     * @throws ApiException 회원이 존재하지 않으면 MEMBER4041
     */
    @Transactional(readOnly=true)
    public List<RatingResponse> getRatingsByMember(Long memberId) {
        if (!memberRepository.existsById(memberId))
            throw new ApiException(HttpStatus.NOT_FOUND,"MEMBER4041","존재하지 않는 유저입니다.");
        return ratingRepository.findByMember_MemberIdOrderByRatingIdDesc(memberId).stream().map(RatingResponse::from).toList();
    }
    /**
     * 회원의 영화 평점을 생성하고 저장 시점에 DB 제약을 확인합니다.
     * 회원·영화의 복합 UNIQUE가 동시 요청에서도 중복을 막습니다.
     *
     * @param memberId 평점을 작성할 회원 ID
     * @param request 영화 ID, 정수 별점, 선택적 후기가 검증된 요청
     * @return 새 평점 ID
     * @throws ApiException 회원이 없거나 같은 회원의 영화 평점이 이미 존재하는 경우
     */
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
    /**
     * 평점 존재 여부를 먼저 검사한 뒤 수정·삭제 요청자의 소유권을 확인합니다.
     *
     * @param ratingId 수정 또는 삭제할 평점 ID
     * @param memberId 요청 경로로 받은 실습용 회원 ID
     * @return 요청 회원이 소유한 영속 평점
     * @throws ApiException 평점이 없으면 RATING4041, 다른 회원 소유이면 RATING4031
     */
    private Rating findOwnedRating(Long ratingId, Long memberId) {
        Rating rating = ratingRepository.findById(ratingId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND,"RATING4041","존재하지 않는 평점입니다."));
        if (!rating.getMember().getMemberId().equals(memberId))
            throw new ApiException(HttpStatus.FORBIDDEN,"RATING4031","본인이 작성한 평점만 수정하거나 삭제할 수 있습니다.");
        return rating;
    }
}
