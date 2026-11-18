package com.umc.movie.service;

import com.umc.movie.dto.CreateMovieRecordRequest;
import com.umc.movie.dto.FavoriteResponse;
import com.umc.movie.dto.MovieRecordResponse;
import com.umc.movie.dto.RatingResponse;
import com.umc.movie.entity.Favorite;
import com.umc.movie.entity.Member;
import com.umc.movie.entity.Rating;
import com.umc.movie.exception.ApiException;
import com.umc.movie.exception.ErrorCode;
import com.umc.movie.repository.FavoriteRepository;
import com.umc.movie.repository.MemberRepository;
import com.umc.movie.repository.RatingRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * "영화 기록" 한 가지 사용자 행동을 처리합니다.
 * 평점 저장과 즐겨찾기 저장을 이 메서드 하나의 트랜잭션으로 묶습니다.
 *
 * 순서: 평점 중복 확인 → 평점 INSERT → 즐겨찾기 중복 확인 → 즐겨찾기 INSERT.
 * 즐겨찾기 단계에서 FAVORITE409_1이 나면 이미 INSERT된 평점까지 rollback됩니다.
 * (9주차 선택 미션 MovieRecordApiTest가 "평점 개수가 그대로인지"로 이를 증명합니다.)
 */
@Service
@RequiredArgsConstructor
public class MovieRecordService {

    private final MemberRepository memberRepository;
    private final RatingRepository ratingRepository;
    private final FavoriteRepository favoriteRepository;

    @Transactional
    public MovieRecordResponse create(Long memberId, CreateMovieRecordRequest request) {
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new ApiException(ErrorCode.MEMBER_NOT_FOUND));

        if (ratingRepository.existsByMember_MemberIdAndMovieId(memberId, request.movieId())) {
            throw new ApiException(ErrorCode.RATING_DUPLICATED);
        }

        Rating savedRating = ratingRepository.save(Rating.builder()
                .member(member)
                .movieId(request.movieId())
                .score(request.score())
                .comment(request.comment())
                .build());

        FavoriteResponse favoriteResponse = null;
        if (request.addToFavorites()) {
            if (favoriteRepository.existsByMember_MemberIdAndMovieId(memberId, request.movieId())) {
                // 평점은 이미 INSERT된 상태입니다. 여기서 던지면 @Transactional이 평점까지 되돌립니다.
                throw new ApiException(ErrorCode.FAVORITE_DUPLICATED);
            }
            Favorite savedFavorite = favoriteRepository.save(Favorite.builder()
                    .member(member)
                    .movieId(request.movieId())
                    .build());
            favoriteResponse = FavoriteResponse.from(savedFavorite);
        }

        return new MovieRecordResponse(RatingResponse.from(savedRating), favoriteResponse);
    }
}
