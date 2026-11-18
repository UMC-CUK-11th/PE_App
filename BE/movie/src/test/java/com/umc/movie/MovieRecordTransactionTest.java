package com.umc.movie;

import com.umc.movie.dto.CreateMovieRecordRequest;
import com.umc.movie.dto.MovieRecordResponse;
import com.umc.movie.entity.Favorite;
import com.umc.movie.entity.Member;
import com.umc.movie.exception.ApiException;
import com.umc.movie.repository.FavoriteRepository;
import com.umc.movie.repository.MemberRepository;
import com.umc.movie.repository.RatingRepository;
import com.umc.movie.service.MovieRecordService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.test.context.bean.override.mockito.MockitoSpyBean;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.willReturn;

/**
 * 실제 DB(H2, MySQL 모드)에서 MovieRecordService의 @Transactional을 확인합니다.
 * 테스트 메서드에는 @Transactional을 붙이지 않습니다. 붙이면 서비스가 테스트 트랜잭션에 합류해
 * 롤백 여부를 볼 수 없기 때문입니다.
 */
@SpringBootTest(properties = {
        "spring.datasource.url=jdbc:h2:mem:movielog;MODE=MySQL;DATABASE_TO_LOWER=TRUE;DB_CLOSE_DELAY=-1",
        "spring.datasource.username=sa",
        "spring.datasource.password=",
        "spring.datasource.driver-class-name=org.h2.Driver",
        "spring.jpa.hibernate.ddl-auto=create-drop"
})
class MovieRecordTransactionTest {

    @Autowired
    MovieRecordService movieRecordService;

    @Autowired
    MemberRepository memberRepository;

    @Autowired
    RatingRepository ratingRepository;

    // 진짜 Repository를 감싸 사전 검사만 속이고, INSERT는 실제 DB로 보냅니다.
    @MockitoSpyBean
    FavoriteRepository favoriteRepository;

    private Long memberId;

    @BeforeEach
    void setUp() {
        memberId = memberRepository.save(Member.builder()
                .email("tx@example.com")
                .password("$2a$10$abcdefghijklmnopqrstuuabcdefghijklmnopqrstuvwxyzabcde")
                .nickname("txtester")
                .build()).getMemberId();
    }

    @AfterEach
    void tearDown() {
        favoriteRepository.deleteAll();
        ratingRepository.deleteAll();
        memberRepository.deleteAll();
    }

    @Test
    void 두_저장이_모두_성공하면_commit() {
        MovieRecordResponse response = movieRecordService.create(memberId,
                new CreateMovieRecordRequest(238L, 5, "다시 보고 싶은 영화입니다.", true));

        assertThat(response.rating().ratingId()).isNotNull();
        assertThat(response.favorite().favoriteId()).isNotNull();
        assertThat(ratingRepository.existsByMember_MemberIdAndMovieId(memberId, 238L)).isTrue();
        assertThat(favoriteRepository.existsByMember_MemberIdAndMovieId(memberId, 238L)).isTrue();
    }

    @Test
    void 즐겨찾기_저장이_UNIQUE_제약에_막히면_먼저_저장한_평점도_rollback() {
        // 같은 회원·영화의 즐겨찾기를 미리 넣어 둡니다.
        Member member = memberRepository.findById(memberId).orElseThrow();
        favoriteRepository.save(Favorite.builder().member(member).movieId(550L).build());

        // 동시 요청이 사전 검사를 함께 통과한 상황을 흉내 냅니다: 검사는 false, INSERT는 실제 UNIQUE 위반.
        willReturn(false).given(favoriteRepository).existsByMember_MemberIdAndMovieId(any(), any());

        assertThatThrownBy(() -> movieRecordService.create(memberId,
                new CreateMovieRecordRequest(550L, 5, "롤백될 평점", true)))
                .isInstanceOf(DataIntegrityViolationException.class);

        // rating INSERT는 이미 실행됐지만(IDENTITY) 트랜잭션 rollback으로 사라져야 합니다.
        assertThat(ratingRepository.count()).isZero();
        assertThat(favoriteRepository.count()).isEqualTo(1);
    }

    @Test
    void 이미_평점이_있으면_RATING409_1_새_행이_생기지_않음() {
        movieRecordService.create(memberId, new CreateMovieRecordRequest(238L, 5, null, false));

        assertThatThrownBy(() -> movieRecordService.create(memberId,
                new CreateMovieRecordRequest(238L, 4, null, true)))
                .isInstanceOf(ApiException.class)
                .hasFieldOrPropertyWithValue("code", "RATING409_1");

        assertThat(ratingRepository.count()).isEqualTo(1);
        assertThat(favoriteRepository.count()).isZero();
    }
}
