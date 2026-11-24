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
class RatingApiIntegrationTest {

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
    void rejectsRatingCreationWithoutBearerTokenWith401() throws Exception {
        mockMvc.perform(post("/v8/ratings")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(ratingRequest(550L)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.isSuccess").value(false))
                .andExpect(jsonPath("$.code").value("AUTH401_2"));

        assertThat(ratingRepository.count()).isZero();
    }

    @Test
    void createsRatingWithBearerTokenWith201() throws Exception {
        signUp();
        String token = login();

        mockMvc.perform(post("/v8/ratings")
                        .header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(ratingRequest(550L)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.isSuccess").value(true))
                .andExpect(jsonPath("$.code").value("COMMON201"))
                .andExpect(jsonPath("$.result").isNumber());

        assertThat(ratingRepository.count()).isEqualTo(1);
    }

    private void signUp() throws Exception {
        mockMvc.perform(post("/v8/members")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "email": "rating-api@example.com",
                                  "password": "Umc!1234",
                                  "nickname": "ratingapi"
                                }
                                """))
                .andExpect(status().isCreated());
    }

    private String login() throws Exception {
        String response = mockMvc.perform(post("/v8/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "email": "rating-api@example.com",
                                  "password": "Umc!1234"
                                }
                                """))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString();
        return objectMapper.readTree(response).path("result").path("accessToken").asText();
    }

    private String ratingRequest(long movieId) {
        return """
                {
                  "movieId": %d,
                  "score": 5,
                  "comment": "9주차 통합 테스트 평점"
                }
                """.formatted(movieId);
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }
}
