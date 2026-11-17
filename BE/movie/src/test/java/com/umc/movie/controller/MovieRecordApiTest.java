package com.umc.movie.controller;

import com.umc.movie.entity.Favorite;
import com.umc.movie.entity.Member;
import com.umc.movie.jwt.JwtProvider;
import com.umc.movie.repository.FavoriteRepository;
import com.umc.movie.repository.MemberRepository;
import com.umc.movie.repository.RatingRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * 9주차 선택 미션: POST /movie-records의 트랜잭션이 정말 되돌리는지 HTTP 요청으로 증명합니다.
 *
 * 이 클래스에는 @Transactional을 붙이지 않습니다.
 * 붙이면 서비스의 트랜잭션이 테스트 트랜잭션에 "합류"해서, 서비스가 예외로 끝나도 rollback은
 * 테스트가 끝날 때까지 미뤄집니다. 그 사이 같은 트랜잭션에서 count()를 하면 방금 INSERT된 평점이
 * 보이므로 "데이터가 남지 않았다"를 확인할 수 없습니다. 대신 매 테스트 뒤에 직접 지웁니다.
 */
@SpringBootTest
@AutoConfigureMockMvc
class MovieRecordApiTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private MemberRepository memberRepository;

    @Autowired
    private RatingRepository ratingRepository;

    @Autowired
    private FavoriteRepository favoriteRepository;

    @Autowired
    private JwtProvider jwtProvider;

    private Member member;
    private String token;

    @BeforeEach
    void setUp() {
        member = memberRepository.save(Member.builder()
                .email("record@umc.com").password("$2a$10$abcdefghijklmnopqrstuv").nickname("기록왕").build());
        token = "Bearer " + jwtProvider.createAccessToken(member.getMemberId());
    }

    @AfterEach
    void tearDown() {
        favoriteRepository.deleteAll();
        ratingRepository.deleteAll();
        memberRepository.deleteAll();
    }

    @Test
    @DisplayName("이미 즐겨찾기한 영화를 addToFavorites true로 기록하면 409 FAVORITE409_1이고, 먼저 저장하려던 평점도 남지 않는다")
    void rollbackRatingWhenFavoriteDuplicated() throws Exception {
        // given: 550번 영화는 이미 즐겨찾기했고, 평점은 아직 없다
        favoriteRepository.save(Favorite.builder().member(member).movieId(550L).build());
        long ratingCountBefore = ratingRepository.count();

        // when: 평점 + 즐겨찾기를 한 번에 저장하면
        mockMvc.perform(post("/movie-records")
                        .header(HttpHeaders.AUTHORIZATION, token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"movieId":550,"score":5,"comment":"롤백될 평점","addToFavorites":true}"""))
                // then: 즐겨찾기 단계에서 실패하고
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("FAVORITE409_1"));

        // then: "예외가 났다"에서 멈추지 않고, 앞서 INSERT된 평점이 rollback되어 개수가 그대로인지 확인한다
        assertThat(ratingRepository.count()).isEqualTo(ratingCountBefore);
        assertThat(ratingRepository.existsByMember_MemberIdAndMovieId(member.getMemberId(), 550L)).isFalse();
        assertThat(favoriteRepository.count()).isEqualTo(1);
    }

    @Test
    @DisplayName("둘 다 처음이면 201과 rating·favorite이 함께 저장된다")
    void commitBoth() throws Exception {
        mockMvc.perform(post("/movie-records")
                        .header(HttpHeaders.AUTHORIZATION, token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"movieId":238,"score":5,"comment":"다시 보고 싶은 영화","addToFavorites":true}"""))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.result.rating.movieId").value(238))
                .andExpect(jsonPath("$.result.favorite.movieId").value(238));

        assertThat(ratingRepository.count()).isEqualTo(1);
        assertThat(favoriteRepository.count()).isEqualTo(1);
    }
}
