package com.umc11th.movie;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.umc11th.movie.repository.FavoriteRepository;
import com.umc11th.movie.repository.MemberRepository;
import com.umc11th.movie.repository.RatingRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class Week08FavoriteFlowIntegrationTest {

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

    @AfterEach
    void cleanUpDatabase() {
        cleanDatabase();
    }

    @Test
    void completesFavoriteCrudAndTransactionalMovieRecordScenario() throws Exception {
        signUp();
        String token = login();

        mockMvc.perform(get("/favorites/{movieId}", 550)
                        .header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.isFavorite").value(false));

        mockMvc.perform(post("/favorites")
                        .header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"movieId":550}
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.code").value("COMMON201"));

        mockMvc.perform(post("/favorites")
                        .header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"movieId":550}
                                """))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("FAVORITE409_1"));

        mockMvc.perform(get("/favorites")
                        .header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.length()").value(1));

        mockMvc.perform(get("/favorites/{movieId}", 550)
                        .header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.isFavorite").value(true));

        mockMvc.perform(delete("/favorites/{movieId}", 550)
                        .header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value("COMMON200"))
                .andExpect(jsonPath("$.result").doesNotExist());

        mockMvc.perform(get("/favorites/{movieId}", 550)
                        .header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.isFavorite").value(false));

        mockMvc.perform(post("/movie-records")
                        .header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "movieId":680,
                                  "score":5,
                                  "comment":"평점과 즐겨찾기를 함께 저장",
                                  "addToFavorites":true
                                }
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.result.rating.movieId").value(680))
                .andExpect(jsonPath("$.result.favorite.movieId").value(680));

        assertThat(ratingRepository.count()).isEqualTo(1);
        assertThat(favoriteRepository.count()).isEqualTo(1);
    }

    @Test
    void exposesWeek08ApisInOpenApiDocument() throws Exception {
        mockMvc.perform(get("/v3/api-docs"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.components.securitySchemes.bearerAuth").exists())
                .andExpect(jsonPath("$.paths['/favorites']").exists())
                .andExpect(jsonPath("$.paths['/movie-records']").exists())
                .andExpect(jsonPath("$.paths['/favorites'].post.parameters").doesNotExist())
                .andExpect(jsonPath("$.paths['/movie-records'].post.parameters").doesNotExist());

        mockMvc.perform(get("/swagger-ui/index.html"))
                .andExpect(status().isOk());
    }

    private void signUp() throws Exception {
        mockMvc.perform(post("/members")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "email":"week08@example.com",
                                  "password":"Umc!1234",
                                  "nickname":"week08"
                                }
                                """))
                .andExpect(status().isCreated());
    }

    private String login() throws Exception {
        String response = mockMvc.perform(post("/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "email":"week08@example.com",
                                  "password":"Umc!1234"
                                }
                                """))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString();
        JsonNode root = objectMapper.readTree(response);
        return root.path("result").path("accessToken").asText();
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }
}
