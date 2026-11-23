package com.umc.movie.service;

import com.umc.movie.dto.CreateMovieRecordRequest;
import com.umc.movie.dto.CreateRatingRequest;
import com.umc.movie.dto.MovieRecordResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class MovieRecordService {
    private final RatingService ratings;
    private final FavoriteService favorites;

    /** 평점과 선택한 즐겨찾기 저장을 같은 트랜잭션에서 처리합니다. */
    @Transactional
    public MovieRecordResponse create(Long memberId, CreateMovieRecordRequest request) {
        var rating = ratings.create(memberId, new CreateRatingRequest(
            request.movieId(), request.score(), request.comment()
        ));
        var favorite = request.addToFavorites() ? favorites.create(memberId, request.movieId()) : null;
        return new MovieRecordResponse(rating, favorite);
    }
}
