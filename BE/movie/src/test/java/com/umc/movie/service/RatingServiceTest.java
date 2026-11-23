package com.umc.movie.service;

import com.umc.movie.dto.CreateRatingRequest;
import com.umc.movie.dto.RatingResponse;
import com.umc.movie.dto.UpdateRatingRequest;
import com.umc.movie.entity.Member;
import com.umc.movie.entity.Rating;
import com.umc.movie.exception.ApiException;
import com.umc.movie.repository.MemberRepository;
import com.umc.movie.repository.RatingRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

/** 9주차 필수 미션: 평점 서비스의 판단(중복·작성자 확인)을 DB 없이 확인하는 단위 테스트 */
@ExtendWith(MockitoExtension.class)
class RatingServiceTest {

    private static final Long WRITER_ID = 1L;
    private static final Long OTHER_ID = 2L;

    @Mock
    private RatingRepository ratingRepository;

    @Mock
    private MemberRepository memberRepository;

    @InjectMocks
    private RatingService ratingService;

    private Member member(Long memberId, String nickname) {
        Member member = Member.builder()
                .email(nickname + "@umc.com")
                .password("암호화된비밀번호")
                .nickname(nickname)
                .build();
        // ID는 DB가 채우는 값이라 빌더에 없습니다. 작성자 비교에 필요하므로 테스트에서 직접 넣습니다.
        ReflectionTestUtils.setField(member, "memberId", memberId);
        return member;
    }

    @Test
    @DisplayName("아직 평점을 남기지 않은 영화면 평점을 저장하고 저장된 평점을 돌려준다")
    void createRating() {
        // given: 회원은 존재하고, 이 영화에 아직 평점이 없는 상황
        given(memberRepository.findById(WRITER_ID)).willReturn(Optional.of(member(WRITER_ID, "영화조아")));
        given(ratingRepository.existsByMember_MemberIdAndMovieId(WRITER_ID, 550L)).willReturn(false);
        given(ratingRepository.saveAndFlush(any(Rating.class))).willAnswer(invocation -> invocation.getArgument(0));

        // when: 평점을 등록하면
        RatingResponse response = ratingService.create(WRITER_ID, new CreateRatingRequest(550L, 5, "최고의 영화!"));

        // then: 요청한 영화·별점이 응답에 담기고, 저장이 실제로 호출된다
        assertThat(response.movieId()).isEqualTo(550L);
        assertThat(response.score()).isEqualTo(5);
        verify(ratingRepository).saveAndFlush(any(Rating.class));
    }

    @Test
    @DisplayName("같은 영화에 평점을 중복 등록하면 RATING409_1 예외를 던지고 저장하지 않는다")
    void createRatingWhenDuplicated() {
        // given: 같은 회원이 같은 영화에 이미 평점을 남긴 상황
        given(memberRepository.findById(WRITER_ID)).willReturn(Optional.of(member(WRITER_ID, "영화조아")));
        given(ratingRepository.existsByMember_MemberIdAndMovieId(WRITER_ID, 550L)).willReturn(true);

        // when & then: 409 예외가 나고, 저장은 시도조차 하지 않는다
        assertThatThrownBy(() -> ratingService.create(WRITER_ID, new CreateRatingRequest(550L, 4, null)))
                .isInstanceOf(ApiException.class)
                .hasMessage("이미 이 영화에 평점을 남기셨습니다.")
                .hasFieldOrPropertyWithValue("code", "RATING409_1");
        verify(ratingRepository, never()).saveAndFlush(any(Rating.class));
    }

    @Test
    @DisplayName("남의 평점을 수정하려 하면 RATING403_1 예외를 던지고 평점은 그대로다")
    void updateOthersRating() {
        // given: 1번 회원이 쓴 평점을 2번 회원의 토큰으로 수정하려는 상황
        Rating rating = Rating.builder()
                .member(member(WRITER_ID, "작성자"))
                .movieId(550L)
                .score(5)
                .comment("최고의 영화!")
                .build();
        given(ratingRepository.findById(10L)).willReturn(Optional.of(rating));

        // when & then: 403 예외가 나고, 별점·후기는 바뀌지 않으며 저장도 하지 않는다
        assertThatThrownBy(() -> ratingService.update(OTHER_ID, 10L, new UpdateRatingRequest(1, "별로")))
                .isInstanceOf(ApiException.class)
                .hasMessage("본인이 작성한 평점만 수정하거나 삭제할 수 있습니다.")
                .hasFieldOrPropertyWithValue("code", "RATING403_1");
        assertThat(rating.getScore()).isEqualTo(5);
        assertThat(rating.getComment()).isEqualTo("최고의 영화!");
        verify(ratingRepository, never()).saveAndFlush(any(Rating.class));
    }

    @Test
    @DisplayName("없는 평점을 수정하려 하면 RATING404_1 예외를 던진다")
    void updateMissingRating() {
        given(ratingRepository.findById(999L)).willReturn(Optional.empty());

        assertThatThrownBy(() -> ratingService.update(WRITER_ID, 999L, new UpdateRatingRequest(3, null)))
                .isInstanceOf(ApiException.class)
                .hasFieldOrPropertyWithValue("code", "RATING404_1");
    }
}
