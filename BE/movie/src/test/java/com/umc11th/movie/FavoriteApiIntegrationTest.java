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

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class FavoriteApiIntegrationTest {

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
    void completesFavoriteCreateDuplicateReadAndDeleteFlow() throws Exception {
        signUp();
        String token = login();

        mockMvc.perform(post("/v8/favorites")
                        .header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"movieId\": 550}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.result.movieId").value(550));

        mockMvc.perform(post("/v8/favorites")
                        .header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"movieId\": 550}"))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("FAVORITE409_1"));

        mockMvc.perform(get("/v8/favorites")
                        .header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.length()").value(1));

        mockMvc.perform(get("/v8/favorites/{movieId}", 550)
                        .header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.isFavorite").value(true));

        mockMvc.perform(delete("/v8/favorites/{movieId}", 550)
                        .header("Authorization", bearer(token)))
                .andExpect(status().isOk());

        mockMvc.perform(get("/v8/favorites/{movieId}", 550)
                        .header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.isFavorite").value(false));
    }

    private void signUp() throws Exception {
        mockMvc.perform(post("/v8/members")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "email": "favorite-api@example.com",
                                  "password": "Umc!1234",
                                  "nickname": "favoriteapi"
                                }
                                """))
                .andExpect(status().isCreated());
    }

    private String login() throws Exception {
        String response = mockMvc.perform(post("/v8/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "email": "favorite-api@example.com",
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
