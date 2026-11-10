package com.umc11th.movie.service;

import com.umc11th.movie.dto.CreateRatingRequest;
import com.umc11th.movie.dto.UpdateRatingRequest;
import com.umc11th.movie.entity.Member;
import com.umc11th.movie.entity.Rating;
import com.umc11th.movie.exception.AuthException;
import com.umc11th.movie.repository.MemberRepository;
import com.umc11th.movie.repository.RatingRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.web.server.ResponseStatusException;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class RatingServiceTest {

    @Mock
    private RatingRepository ratingRepository;

    @Mock
    private MemberRepository memberRepository;

    @InjectMocks
    private RatingService ratingService;

    @Test
    void createsRatingForExistingMember() {
        Member member = mock(Member.class);
        Rating savedRating = mock(Rating.class);
        when(memberRepository.findById(1L)).thenReturn(Optional.of(member));
        when(ratingRepository.existsByMemberMemberIdAndMovieId(1L, 550L))
                .thenReturn(false);
        when(ratingRepository.save(any(Rating.class))).thenReturn(savedRating);
        when(savedRating.getRatingId()).thenReturn(7L);

        Long ratingId = ratingService.create(
                1L,
                new CreateRatingRequest(550L, 5, "최고의 영화!")
        );

        assertThat(ratingId).isEqualTo(7L);
    }

    @Test
    void rejectsDuplicateRating() {
        Member member = mock(Member.class);
        when(memberRepository.findById(1L)).thenReturn(Optional.of(member));
        when(ratingRepository.existsByMemberMemberIdAndMovieId(1L, 550L))
                .thenReturn(true);

        assertThatThrownBy(() -> ratingService.create(
                1L,
                new CreateRatingRequest(550L, 5, null)
        ))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("이미 이 영화에 평점을 남기셨습니다.");

        verify(ratingRepository, never()).save(any());
    }

    @Test
    void rejectsUpdateByAnotherMember() {
        Member owner = mock(Member.class);
        when(owner.getMemberId()).thenReturn(2L);
        Rating rating = new Rating(owner, 550L, 5, "원래 후기");
        when(ratingRepository.findById(7L)).thenReturn(Optional.of(rating));

        assertThatThrownBy(() -> ratingService.update(
                7L,
                1L,
                new UpdateRatingRequest(4, "수정 시도")
        ))
                .isInstanceOf(AuthException.class)
                .satisfies(exception -> assertThat(
                        ((AuthException) exception).getStatus().value()
                ).isEqualTo(403));
    }

    @Test
    void rejectsDeleteForMissingRating() {
        when(ratingRepository.findById(999L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> ratingService.delete(999L, 1L))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(exception -> assertThat(
                        ((ResponseStatusException) exception).getStatusCode().value()
                ).isEqualTo(404));
    }
}
