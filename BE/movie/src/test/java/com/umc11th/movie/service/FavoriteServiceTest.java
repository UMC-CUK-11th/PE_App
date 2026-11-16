package com.umc11th.movie.service;

import com.umc11th.movie.dto.CreateFavoriteRequest;
import com.umc11th.movie.entity.Favorite;
import com.umc11th.movie.entity.Member;
import com.umc11th.movie.exception.ApiException;
import com.umc11th.movie.repository.FavoriteRepository;
import com.umc11th.movie.repository.MemberRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class FavoriteServiceTest {

    @Mock
    private FavoriteRepository favoriteRepository;

    @Mock
    private MemberRepository memberRepository;

    @InjectMocks
    private FavoriteService favoriteService;

    @Test
    void rejectsDuplicateFavoriteWithMissionCode() {
        Member member = new Member("member@example.com", "encoded", "member");
        when(memberRepository.findById(1L)).thenReturn(Optional.of(member));
        when(favoriteRepository.existsByMemberMemberIdAndMovieId(1L, 550L))
                .thenReturn(true);

        assertThatThrownBy(() -> favoriteService.create(
                1L,
                new CreateFavoriteRequest(550L)
        ))
                .isInstanceOf(ApiException.class)
                .satisfies(error -> {
                    ApiException exception = (ApiException) error;
                    org.assertj.core.api.Assertions.assertThat(exception.getCode())
                            .isEqualTo("FAVORITE409_1");
                });

        verify(favoriteRepository, never()).save(any(Favorite.class));
    }
}
