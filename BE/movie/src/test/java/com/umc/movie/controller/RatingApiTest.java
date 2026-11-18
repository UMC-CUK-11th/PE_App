package com.umc.movie.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.umc.movie.dto.CreateRatingRequest;
import com.umc.movie.entity.Member;
import com.umc.movie.entity.Rating;
import com.umc.movie.jwt.JwtProvider;
import com.umc.movie.repository.MemberRepository;
import com.umc.movie.repository.RatingRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.matchesPattern;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** 9주차 필수 미션: 평점 API 통합 테스트(인증·검증·서비스·H2 DB까지 실제로 동작) */
@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class RatingApiTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private MemberRepository memberRepository;

    @Autowired
    private RatingRepository ratingRepository;

    @Autowired
    private JwtProvider jwtProvider;

    private Member writer;
    private String writerToken;
    private String otherToken;

    @BeforeEach
    void setUp() {
        writer = memberRepository.save(Member.builder()
                .email("writer@umc.com").password("$2a$10$abcdefghijklmnopqrstuv").nickname("작성자").build());
        Member other = memberRepository.save(Member.builder()
                .email("other@umc.com").password("$2a$10$abcdefghijklmnopqrstuv").nickname("다른사람").build());
        writerToken = "Bearer " + jwtProvider.createAccessToken(writer.getMemberId());
        otherToken = "Bearer " + jwtProvider.createAccessToken(other.getMemberId());
    }

    private String body(long movieId, int score, String comment) throws Exception {
        return objectMapper.writeValueAsString(new CreateRatingRequest(movieId, score, comment));
    }

    @Test
    @DisplayName("토큰 없이 평점을 등록하면 401과 AUTH401_2를 응답하고 평점은 저장되지 않는다")
    void createRatingWithoutToken() throws Exception {
        mockMvc.perform(post("/ratings")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body(550L, 5, "최고의 영화!")))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.isSuccess").value(false))
                .andExpect(jsonPath("$.code").value("AUTH401_2"))
                .andExpect(jsonPath("$.message").value("로그인이 필요한 요청입니다."));

        assertThat(ratingRepository.count()).isZero();
    }

    @Test
    @DisplayName("토큰을 담아 평점을 등록하면 201과 저장된 평점을 응답하고 토큰의 회원으로 저장된다")
    void createRating() throws Exception {
        mockMvc.perform(post("/ratings")
                        .header(HttpHeaders.AUTHORIZATION, writerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body(550L, 5, "최고의 영화!")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.isSuccess").value(true))
                .andExpect(jsonPath("$.code").value("COMMON201"))
                .andExpect(jsonPath("$.message").value("평점을 등록했습니다."))
                .andExpect(jsonPath("$.result.ratingId").isNumber())
                .andExpect(jsonPath("$.result.movieId").value(550))
                .andExpect(jsonPath("$.result.score").value(5))
                // MySQL DATETIME과 같은 초 단위여야 응답 값과 DB 값이 어긋나지 않습니다(소수 초 없음).
                .andExpect(jsonPath("$.result.createdAt").value(matchesPattern("\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}")));

        assertThat(ratingRepository.existsByMember_MemberIdAndMovieId(writer.getMemberId(), 550L)).isTrue();
    }

    @Test
    @DisplayName("같은 영화에 평점을 다시 등록하면 409와 RATING409_1을 응답한다")
    void createRatingWhenDuplicated() throws Exception {
        ratingRepository.save(Rating.builder().member(writer).movieId(550L).score(5).build());

        mockMvc.perform(post("/ratings")
                        .header(HttpHeaders.AUTHORIZATION, writerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body(550L, 4, null)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("RATING409_1"));

        assertThat(ratingRepository.count()).isEqualTo(1);
    }

    @Test
    @DisplayName("남의 평점을 수정·삭제하면 403과 RATING403_1을 응답하고 평점은 그대로다")
    void updateOthersRating() throws Exception {
        Rating rating = ratingRepository.save(Rating.builder().member(writer).movieId(550L).score(5).comment("최고").build());

        mockMvc.perform(patch("/ratings/{ratingId}", rating.getRatingId())
                        .header(HttpHeaders.AUTHORIZATION, otherToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"score\":1,\"comment\":\"별로\"}"))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value("RATING403_1"));

        mockMvc.perform(delete("/ratings/{ratingId}", rating.getRatingId())
                        .header(HttpHeaders.AUTHORIZATION, otherToken))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value("RATING403_1"));

        assertThat(ratingRepository.findById(rating.getRatingId())).get()
                .extracting(Rating::getScore).isEqualTo(5);
    }

    @Test
    @DisplayName("내 평점을 수정하면 200과 바뀐 평점, 삭제하면 200과 result null을 응답한다")
    void updateAndDeleteMyRating() throws Exception {
        Rating rating = ratingRepository.save(Rating.builder().member(writer).movieId(550L).score(5).comment("최고").build());

        mockMvc.perform(patch("/ratings/{ratingId}", rating.getRatingId())
                        .header(HttpHeaders.AUTHORIZATION, writerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"score\":3}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("평점을 수정했습니다."))
                .andExpect(jsonPath("$.result.score").value(3))
                // PATCH지만 전체 교체라 comment를 빼면 null로 덮입니다.
                .andExpect(jsonPath("$.result.comment").isEmpty());

        mockMvc.perform(delete("/ratings/{ratingId}", rating.getRatingId())
                        .header(HttpHeaders.AUTHORIZATION, writerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("평점을 삭제했습니다."))
                .andExpect(jsonPath("$.result").isEmpty());

        assertThat(ratingRepository.count()).isZero();
    }

    @Test
    @DisplayName("유저별 평점 조회는 토큰 없이 200과 배열, 없는 회원은 404와 MEMBER404_1을 응답한다")
    void getMemberRatings() throws Exception {
        ratingRepository.save(Rating.builder().member(writer).movieId(550L).score(5).build());

        mockMvc.perform(get("/members/{memberId}/ratings", writer.getMemberId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].movieId").value(550));

        mockMvc.perform(get("/members/{memberId}/ratings", 999_999L))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("MEMBER404_1"));
    }
}
