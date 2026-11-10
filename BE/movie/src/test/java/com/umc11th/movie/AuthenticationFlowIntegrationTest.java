package com.umc11th.movie;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
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
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class AuthenticationFlowIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private RatingRepository ratingRepository;

    @Autowired
    private MemberRepository memberRepository;

    @BeforeEach
    void cleanDatabase() {
        ratingRepository.deleteAll();
        memberRepository.deleteAll();
    }

    @Test
    void completesLoginAndOwnerBasedRatingScenario() throws Exception {
        signUp("owner@example.com", "owner");
        signUp("other@example.com", "other");
        String ownerToken = login("owner@example.com");
        String otherToken = login("other@example.com");

        mockMvc.perform(get("/members/me"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("AUTH401_2"));

        mockMvc.perform(get("/members/me")
                        .header("Authorization", bearer(ownerToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.email").value("owner@example.com"));

        String createResponse = mockMvc.perform(post("/ratings")
                        .header("Authorization", bearer(ownerToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "movieId": 550,
                                  "score": 5,
                                  "comment": "인증 기반으로 등록한 평점"
                                }
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.code").value("COMMON201"))
                .andReturn()
                .getResponse()
                .getContentAsString();
        long ratingId = objectMapper.readTree(createResponse).path("result").asLong();

        mockMvc.perform(patch("/ratings/{ratingId}", ratingId)
                        .header("Authorization", bearer(otherToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "score": 1,
                                  "comment": "다른 회원의 수정 시도"
                                }
                                """))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value("AUTH403_1"));

        mockMvc.perform(patch("/ratings/{ratingId}", ratingId)
                        .header("Authorization", bearer(ownerToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "score": 4,
                                  "comment": "본인이 수정한 평점"
                                }
                                """))
                .andExpect(status().isOk());

        mockMvc.perform(delete("/ratings/{ratingId}", ratingId)
                        .header("Authorization", bearer(ownerToken)))
                .andExpect(status().isNoContent())
                .andExpect(content().string(""));
    }

    private void signUp(String email, String nickname) throws Exception {
        mockMvc.perform(post("/members")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "email": "%s",
                                  "password": "Umc!1234",
                                  "nickname": "%s"
                                }
                                """.formatted(email, nickname)))
                .andExpect(status().isCreated());
    }

    private String login(String email) throws Exception {
        String response = mockMvc.perform(post("/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "email": "%s",
                                  "password": "Umc!1234"
                                }
                                """.formatted(email)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.accessToken").isNotEmpty())
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
