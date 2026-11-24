package com.umc11th.movie.service;

import com.umc11th.movie.dto.CreateMovieRecordRequest;
import com.umc11th.movie.dto.FavoriteResponse;
import com.umc11th.movie.dto.MovieRecordResponse;
import com.umc11th.movie.dto.RatingResponse;
import com.umc11th.movie.entity.Favorite;
import com.umc11th.movie.entity.Member;
import com.umc11th.movie.entity.Rating;
import com.umc11th.movie.exception.ApiException;
import com.umc11th.movie.repository.FavoriteRepository;
import com.umc11th.movie.repository.MemberRepository;
import com.umc11th.movie.repository.RatingRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class MovieRecordService {

    private final MemberRepository memberRepository;
    private final RatingRepository ratingRepository;
    private final FavoriteRepository favoriteRepository;

    @Transactional
    public MovieRecordResponse create(Long memberId, CreateMovieRecordRequest request) {
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new ApiException(
                        HttpStatus.NOT_FOUND,
                        "MEMBER404_1",
                        "해당 회원을 찾을 수 없습니다."
                ));

        if (ratingRepository.existsByMemberMemberIdAndMovieId(memberId, request.movieId())) {
            throw new ApiException(
                    HttpStatus.CONFLICT,
                    "RATING409_1",
                    "이미 이 영화에 평점을 남기셨습니다."
            );
        }
        Rating rating = ratingRepository.save(new Rating(
                member,
                request.movieId(),
                request.score(),
                request.comment()
        ));

        FavoriteResponse favoriteResponse = null;
        if (request.addToFavorites()) {
            if (favoriteRepository.existsByMemberMemberIdAndMovieId(
                    memberId,
                    request.movieId()
            )) {
                throw new ApiException(
                        HttpStatus.CONFLICT,
                        "FAVORITE409_1",
                        "이미 이 영화를 즐겨찾기하셨습니다."
                );
            }
            Favorite favorite = favoriteRepository.save(
                    new Favorite(member, request.movieId())
            );
            favoriteResponse = FavoriteResponse.from(favorite);
        }

        return new MovieRecordResponse(RatingResponse.from(rating), favoriteResponse);
    }
}
