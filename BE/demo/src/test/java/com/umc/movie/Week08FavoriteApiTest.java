package com.umc.movie;

import com.umc.movie.auth.JwtService;
import com.umc.movie.entity.Member;
import com.umc.movie.repository.FavoriteRepository;
import com.umc.movie.repository.MemberRepository;
import com.umc.movie.repository.RatingRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoSpyBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

import static org.hamcrest.Matchers.nullValue;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.doReturn;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(properties = "spring.datasource.url=jdbc:h2:mem:movie-week08;MODE=MySQL;DB_CLOSE_DELAY=-1")
@AutoConfigureMockMvc
@ActiveProfiles("test")
class Week08FavoriteApiTest {
    @Autowired MockMvc mvc;
    @Autowired JwtService jwt;
    @Autowired MemberRepository members;
    @Autowired RatingRepository ratings;
    @MockitoSpyBean FavoriteRepository favorites;
    long first;
    long second;

    @BeforeEach
    void setup() {
        favorites.deleteAll();
        ratings.deleteAll();
        members.deleteAll();
        first = members.save(new Member("week08-a@example.com", "test-only", "회원가")).getMemberId();
        second = members.save(new Member("week08-b@example.com", "test-only", "회원나")).getMemberId();
    }

    @Test
    void newEndpointsRequireAuthentication() throws Exception {
        for (var request : new MockHttpServletRequestBuilder[] {
            post("/favorites"), get("/favorites"), get("/favorites/550"),
            delete("/favorites/550"), post("/movie-records")
        }) {
            mvc.perform(request).andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("AUTH401_2"));
        }
    }

    @Test
    void favoritesAreOwnedByTokenAndListedNewestFirst() throws Exception {
        mvc.perform(as(first, get("/favorites/550")))
            .andExpect(status().isOk()).andExpect(jsonPath("$.result.isFavorite").value(false));
        mvc.perform(as(first, post("/favorites"), "{\"movieId\":550,\"memberId\":" + second + "}"))
            .andExpect(status().isCreated()).andExpect(jsonPath("$.code").value("COMMON201"))
            .andExpect(jsonPath("$.result.favoriteId").isNumber())
            .andExpect(jsonPath("$.result.movieId").value(550))
            .andExpect(jsonPath("$.result.createdAt").isString());
        mvc.perform(as(first, post("/favorites"), "{\"movieId\":550}"))
            .andExpect(status().isConflict()).andExpect(jsonPath("$.code").value("FAVORITE409_1"));
        mvc.perform(as(first, post("/favorites"), "{\"movieId\":238}"))
            .andExpect(status().isCreated());
        mvc.perform(as(first, get("/favorites"))).andExpect(status().isOk())
            .andExpect(jsonPath("$.result[0].movieId").value(238))
            .andExpect(jsonPath("$.result[1].movieId").value(550));
        mvc.perform(as(second, get("/favorites").param("memberId", Long.toString(first))))
            .andExpect(status().isOk()).andExpect(jsonPath("$.result").isEmpty());
        mvc.perform(as(first, get("/favorites/550")))
            .andExpect(status().isOk()).andExpect(jsonPath("$.result.isFavorite").value(true));
        mvc.perform(as(second, delete("/favorites/550"))).andExpect(status().isNotFound())
            .andExpect(jsonPath("$.code").value("FAVORITE404_1"));
        mvc.perform(as(second, post("/favorites"), "{\"movieId\":550}"))
            .andExpect(status().isCreated());
        mvc.perform(as(first, delete("/favorites/550"))).andExpect(status().isOk())
            .andExpect(jsonPath("$.code").value("COMMON200"))
            .andExpect(jsonPath("$.result").value(nullValue()));
        mvc.perform(as(first, get("/favorites/550"))).andExpect(status().isOk())
            .andExpect(jsonPath("$.result.isFavorite").value(false));
        mvc.perform(as(second, get("/favorites/550"))).andExpect(status().isOk())
            .andExpect(jsonPath("$.result.isFavorite").value(true));
    }

    @Test
    void movieRecordHonorsFavoriteFlagAndPreservesRatingConflictCode() throws Exception {
        String withFavorite = "{\"movieId\":238,\"score\":5,\"comment\":\"추천\",\"addToFavorites\":true}";
        mvc.perform(as(first, post("/movie-records"), withFavorite))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.result.rating.movieId").value(238))
            .andExpect(jsonPath("$.result.favorite.movieId").value(238));
        mvc.perform(as(first, post("/movie-records"), withFavorite))
            .andExpect(status().isConflict()).andExpect(jsonPath("$.code").value("RATING409_1"));
        mvc.perform(as(first, post("/movie-records"), "{\"movieId\":550,\"score\":4,\"addToFavorites\":false}"))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.result.rating.movieId").value(550))
            .andExpect(jsonPath("$.result.favorite").value(nullValue()));
        assertFalse(favorites.existsByMember_MemberIdAndMovieId(first, 550L));
    }

    @Test
    void databaseDuplicateAfterPrecheckRollsBackAlreadyInsertedRating() throws Exception {
        mvc.perform(as(first, post("/favorites"), "{\"movieId\":550}"))
            .andExpect(status().isCreated());
        // Simulate a concurrent insert that the service's earlier read did not see.
        doReturn(false).when(favorites).existsByMember_MemberIdAndMovieId(first, 550L);
        mvc.perform(as(first, post("/movie-records"), "{\"movieId\":550,\"score\":4,\"addToFavorites\":true}"))
            .andExpect(status().isConflict()).andExpect(jsonPath("$.code").value("FAVORITE409_1"));
        assertTrue(ratings.findByMember_MemberIdOrderByRatingIdDesc(first).isEmpty());
        mvc.perform(as(first, get("/favorites"))).andExpect(status().isOk())
            .andExpect(jsonPath("$.result.length()").value(1))
            .andExpect(jsonPath("$.result[0].movieId").value(550));
    }

    @Test
    void invalidMovieIdAndMissingFavoriteFlagReturnBadRequest() throws Exception {
        mvc.perform(as(first, post("/favorites"), "{\"movieId\":0}"))
            .andExpect(status().isBadRequest()).andExpect(jsonPath("$.code").value("COMMON400"));
        mvc.perform(as(first, get("/favorites/0"))).andExpect(status().isBadRequest());
        mvc.perform(as(first, post("/movie-records"), "{\"movieId\":550,\"score\":4}"))
            .andExpect(status().isBadRequest()).andExpect(jsonPath("$.code").value("COMMON400"));
    }

    private MockHttpServletRequestBuilder as(long memberId, MockHttpServletRequestBuilder request) {
        return request.header("Authorization", "Bearer " + jwt.issue(memberId));
    }

    private MockHttpServletRequestBuilder as(long memberId, MockHttpServletRequestBuilder request, String body) {
        return as(memberId, request).contentType(MediaType.APPLICATION_JSON).content(body);
    }
}
