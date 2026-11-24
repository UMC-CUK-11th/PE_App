package com.umc11th.movie;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.umc11th.movie.repository.FavoriteRepository;
import com.umc11th.movie.repository.MemberRepository;
import com.umc11th.movie.repository.RatingRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class MovieRecordTransactionIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private FavoriteRepository favoriteRepository;

    @Autowired
    private RatingRepository ratingRepository;

    @Autowired
    private MemberRepository memberRepository;

    @BeforeEach
    void cleanDatabase() {
        favoriteRepository.deleteAll();
        ratingRepository.deleteAll();
        memberRepository.deleteAll();
    }

    @Test
    void rollsBackRatingWhenFavoriteAlreadyExists() throws Exception {
        signUp();
        String token = login();
        long movieId = 680L;

        mockMvc.perform(post("/v8/favorites")
                        .header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"movieId\": 680}"))
                .andExpect(status().isCreated());

        long ratingCountBeforeRequest = ratingRepository.count();

        mockMvc.perform(post("/v8/movie-records")
                        .header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "movieId": 680,
                                  "score": 5,
                                  "comment": "롤백 검증",
                                  "addToFavorites": true
                                }
                                """))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("FAVORITE409_1"));

        assertThat(ratingRepository.count()).isEqualTo(ratingCountBeforeRequest);
        assertThat(favoriteRepository.count()).isEqualTo(1);
        assertThat(ratingRepository.existsByMemberMemberIdAndMovieId(
                memberRepository.findByEmail("transaction@example.com").orElseThrow().getMemberId(),
                movieId
        )).isFalse();
    }

    private void signUp() throws Exception {
        mockMvc.perform(post("/v8/members")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "email": "transaction@example.com",
                                  "password": "Umc!1234",
                                  "nickname": "transaction"
                                }
                                """))
                .andExpect(status().isCreated());
    }

    private String login() throws Exception {
        String response = mockMvc.perform(post("/v8/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "email": "transaction@example.com",
                                  "password": "Umc!1234"
                                }
                                """))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString();
        return objectMapper.readTree(response).path("result").path("accessToken").asText();
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }
}
