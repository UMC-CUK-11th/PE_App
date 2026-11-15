package com.umc.movie;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.umc.movie.repository.MemberRepository;
import com.umc.movie.repository.RatingRepository;
import java.nio.charset.StandardCharsets;
import java.time.Clock;
import java.time.Instant;
import java.util.Base64;
import java.util.Map;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class Week07AuthApiTest {
    private static final Instant START = Instant.parse("2026-11-10T00:00:00Z");
    private static final String EMAIL_A = "a@example.com";
    private static final String EMAIL_B = "b@example.com";
    private static final String PASSWORD = "Study123!";
    @Autowired MockMvc mvc;
    @Autowired ObjectMapper json;
    @Autowired MemberRepository members;
    @Autowired RatingRepository ratings;
    @MockitoBean Clock clock;

    @BeforeEach
    void cleanTestDatabase() {
        when(clock.instant()).thenReturn(START);
        ratings.deleteAll();
        members.deleteAll();
    }

    @Test
    void loginUsesSameErrorForUnknownEmailAndWrongPassword() throws Exception {
        signup(EMAIL_A, "회원가");
        JsonNode wrongPassword = body(login(EMAIL_A, "Wrong123!").andExpect(status().isUnauthorized()));
        JsonNode unknownEmail = body(login(EMAIL_B, PASSWORD).andExpect(status().isUnauthorized()));
        assertEquals(wrongPassword, unknownEmail);
        assertEquals("AUTH401_1", wrongPassword.path("code").asText());
        login(EMAIL_A, "").andExpect(status().isBadRequest());
    }

    @Test
    void tokenAbsenceTamperingAndExpiryAreDistinct() throws Exception {
        long id = signup(EMAIL_A, "회원가");
        String token = token(EMAIL_A);
        mvc.perform(get("/members/me")).andExpect(status().isUnauthorized())
            .andExpect(jsonPath("$.code").value("AUTH401_2"));
        mvc.perform(get("/members/me").header("Authorization", "Bearer malformed"))
            .andExpect(status().isUnauthorized()).andExpect(jsonPath("$.code").value("AUTH401_3"));
        String[] pieces = token.split("\\.");
        String payload = new String(Base64.getUrlDecoder().decode(pieces[1]), StandardCharsets.UTF_8);
        String altered = payload.replace("\"sub\":\"" + id + "\"", "\"sub\":\"" + (id + 1) + "\"");
        assertNotEquals(payload, altered);
        pieces[1] = Base64.getUrlEncoder().withoutPadding().encodeToString(altered.getBytes(StandardCharsets.UTF_8));
        mvc.perform(bearer(get("/members/me"), String.join(".", pieces)))
            .andExpect(status().isUnauthorized()).andExpect(jsonPath("$.code").value("AUTH401_3"));
        when(clock.instant()).thenReturn(START.plusSeconds(59));
        mvc.perform(bearer(get("/members/me"), token)).andExpect(status().isOk());
        when(clock.instant()).thenReturn(START.plusSeconds(60));
        mvc.perform(bearer(get("/members/me"), token))
            .andExpect(status().isUnauthorized()).andExpect(jsonPath("$.code").value("AUTH401_4"));
    }

    @Test
    void profileReturnsOnlyPublicFieldsAndRejectsDuplicateNickname() throws Exception {
        signup(EMAIL_A, "회원가");
        signup(EMAIL_B, "회원나");
        String token = token(EMAIL_A);
        mvc.perform(bearer(get("/members/me"), token)).andExpect(status().isOk())
            .andExpect(jsonPath("$.result.email").value(EMAIL_A))
            .andExpect(jsonPath("$.result.nickname").value("회원가"))
            .andExpect(jsonPath("$.result.createdAt").exists())
            .andExpect(jsonPath("$.result.memberId").doesNotExist())
            .andExpect(jsonPath("$.result.password").doesNotExist());
        mvc.perform(bearer(json(patch("/members/me"), Map.of("nickname", " 회원가 ")), token))
            .andExpect(status().isOk());
        mvc.perform(bearer(json(patch("/members/me"), Map.of("nickname", "회원나")), token))
            .andExpect(status().isConflict()).andExpect(jsonPath("$.code").value("MEMBER409_1"));
        mvc.perform(bearer(json(patch("/members/me"), Map.of("nickname", " 영화광 ")), token))
            .andExpect(status().isOk()).andExpect(jsonPath("$.result.nickname").value("영화광"));
        assertEquals("영화광", members.findByEmail(EMAIL_A).orElseThrow().getNickname());
    }

    @Test
    void ratingOwnershipComesFromTokenAndLegacyWritesAreUnavailable() throws Exception {
        long owner = signup(EMAIL_A, "회원가");
        long other = signup(EMAIL_B, "회원나");
        String ownerToken = token(EMAIL_A);
        String otherToken = token(EMAIL_B);
        var ratingBody = Map.of("movieId", 550, "score", 5, "comment", "추천");
        long id = body(mvc.perform(bearer(json(post("/ratings"), ratingBody), ownerToken))
            .andExpect(status().isCreated())).at("/result/ratingId").asLong();
        assertEquals(owner, ratings.findById(id).orElseThrow().getMember().getMemberId());
        mvc.perform(bearer(json(post("/ratings"), ratingBody), ownerToken))
            .andExpect(status().isConflict()).andExpect(jsonPath("$.code").value("RATING409_1"));
        String path = "/ratings/" + id;
        var update = Map.of("score", 3, "comment", "수정");
        mvc.perform(bearer(json(patch(path), update), ownerToken))
            .andExpect(status().isOk()).andExpect(jsonPath("$.result.score").value(3));
        mvc.perform(bearer(json(patch(path), update), otherToken))
            .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value("RATING403_1"));
        mvc.perform(bearer(delete(path), otherToken))
            .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value("RATING403_1"));
        mvc.perform(json(patch(path), update)).andExpect(status().isUnauthorized())
            .andExpect(jsonPath("$.code").value("AUTH401_2"));
        mvc.perform(json(post("/members/" + other + "/ratings"), ratingBody))
            .andExpect(status().isMethodNotAllowed());
        mvc.perform(json(patch("/members/" + owner + "/ratings/" + id), update))
            .andExpect(status().isNotFound());
        mvc.perform(delete("/members/" + owner + "/ratings/" + id)).andExpect(status().isNotFound());
        mvc.perform(bearer(delete("/ratings/99999"), ownerToken))
            .andExpect(status().isNotFound()).andExpect(jsonPath("$.code").value("RATING404_1"));
        mvc.perform(bearer(delete(path), ownerToken))
            .andExpect(status().isOk()).andExpect(jsonPath("$.code").value("COMMON200"));
        assertTrue(ratings.findById(id).isEmpty());
    }

    private long signup(String email, String nickname) throws Exception {
        return body(mvc.perform(json(post("/members"),
            Map.of("email", email, "password", PASSWORD, "nickname", nickname)))
            .andExpect(status().isCreated())).at("/result/memberId").asLong();
    }

    private ResultActions login(String email, String password) throws Exception {
        return mvc.perform(json(post("/auth/login"), Map.of("email", email, "password", password)));
    }

    private String token(String email) throws Exception {
        JsonNode result = body(login(email, PASSWORD).andExpect(status().isOk())
            .andExpect(header().string("Cache-Control", "no-store"))).path("result");
        assertFalse(result.has("memberId"));
        assertFalse(result.has("password"));
        return result.path("accessToken").asText();
    }

    private MockHttpServletRequestBuilder json(MockHttpServletRequestBuilder request, Map<String, ?> body)
        throws Exception {
        return request.contentType(MediaType.APPLICATION_JSON).content(json.writeValueAsBytes(body));
    }

    private MockHttpServletRequestBuilder bearer(MockHttpServletRequestBuilder request, String token) {
        return request.header("Authorization", "Bearer " + token);
    }

    private JsonNode body(ResultActions result) throws Exception {
        return json.readTree(result.andReturn().getResponse().getContentAsByteArray());
    }
}
