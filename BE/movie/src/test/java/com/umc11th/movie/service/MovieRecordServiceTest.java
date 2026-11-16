package com.umc11th.movie.service;

import com.umc11th.movie.dto.CreateMovieRecordRequest;
import com.umc11th.movie.dto.MovieRecordResponse;
import com.umc11th.movie.entity.Favorite;
import com.umc11th.movie.entity.Member;
import com.umc11th.movie.entity.Rating;
import com.umc11th.movie.repository.FavoriteRepository;
import com.umc11th.movie.repository.MemberRepository;
import com.umc11th.movie.repository.RatingRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.transaction.annotation.Transactional;

import java.lang.reflect.Method;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class MovieRecordServiceTest {

    @Mock
    private MemberRepository memberRepository;

    @Mock
    private RatingRepository ratingRepository;

    @Mock
    private FavoriteRepository favoriteRepository;

    @InjectMocks
    private MovieRecordService movieRecordService;

    @Test
    void savesRatingAndFavoriteInTransactionalMethod() throws Exception {
        Member member = new Member("member@example.com", "encoded", "member");
        Rating savedRating = mock(Rating.class);
        Favorite savedFavorite = mock(Favorite.class);
        when(memberRepository.findById(1L)).thenReturn(Optional.of(member));
        when(ratingRepository.save(any(Rating.class))).thenReturn(savedRating);
        when(favoriteRepository.save(any(Favorite.class))).thenReturn(savedFavorite);

        MovieRecordResponse response = movieRecordService.create(
                1L,
                new CreateMovieRecordRequest(550L, 5, "좋은 영화", true)
        );

        verify(ratingRepository).save(any(Rating.class));
        verify(favoriteRepository).save(any(Favorite.class));
        assertThat(response.favorite()).isNotNull();

        Method create = MovieRecordService.class.getMethod(
                "create",
                Long.class,
                CreateMovieRecordRequest.class
        );
        assertThat(create.isAnnotationPresent(Transactional.class)).isTrue();
    }

    @Test
    void savesOnlyRatingWhenFavoriteIsNotRequested() {
        Member member = new Member("member@example.com", "encoded", "member");
        Rating savedRating = mock(Rating.class);
        when(memberRepository.findById(1L)).thenReturn(Optional.of(member));
        when(ratingRepository.save(any(Rating.class))).thenReturn(savedRating);

        MovieRecordResponse response = movieRecordService.create(
                1L,
                new CreateMovieRecordRequest(550L, 4, null, false)
        );

        verify(favoriteRepository, never()).save(any(Favorite.class));
        assertThat(response.favorite()).isNull();
    }
}
