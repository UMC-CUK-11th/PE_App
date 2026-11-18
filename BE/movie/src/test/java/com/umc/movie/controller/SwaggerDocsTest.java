package com.umc.movie.controller;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Iterator;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * 9주차: 문서도 테스트로 지킵니다.
 * 누군가 @Operation·@SecurityRequirement를 빠뜨리거나 공개 목록을 건드리면 여기서 먼저 빨간불이 켜집니다.
 */
@SpringBootTest
@AutoConfigureMockMvc
class SwaggerDocsTest {

    // 토큰 없이 부르는 공개 API. 나머지는 모두 자물쇠(bearerAuth)가 있어야 합니다.
    private static final Set<String> PUBLIC_OPERATIONS = Set.of(
            "POST /auth/login",
            "POST /members",
            "GET /members/nickname/{nickname}",
            "GET /members/email/{email}",
            "GET /members/{memberId}/ratings"
    );

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    private JsonNode apiDocs() throws Exception {
        String json = mockMvc.perform(get("/v3/api-docs"))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        return objectMapper.readTree(json);
    }

    @Test
    @DisplayName("문서 화면 주소는 토큰 없이 Swagger UI로 이동한다")
    void swaggerUiIsPublic() throws Exception {
        mockMvc.perform(get("/swagger-ui.html"))
                .andExpect(status().is3xxRedirection())
                .andExpect(header().string("Location", "/swagger-ui/index.html"));
    }

    @Test
    @DisplayName("15개 API가 모두 문서에 있고, 각각 한 줄 설명이 있으며, 공개 API 5개만 자물쇠가 없다")
    void everyOperationIsDocumented() throws Exception {
        JsonNode paths = apiDocs().get("paths");
        Set<String> operations = new TreeSet<>();
        Set<String> publicOperations = new TreeSet<>();

        for (Iterator<Map.Entry<String, JsonNode>> it = paths.fields(); it.hasNext(); ) {
            Map.Entry<String, JsonNode> path = it.next();
            path.getValue().fields().forEachRemaining(method -> {
                String operation = method.getKey().toUpperCase() + " " + path.getKey();
                JsonNode spec = method.getValue();
                operations.add(operation);

                assertThat(spec.path("summary").asText()).as(operation + " summary").isNotBlank();
                assertThat(spec.path("tags")).as(operation + " tags").isNotEmpty();
                if (spec.path("security").isMissingNode()) {
                    publicOperations.add(operation);
                } else {
                    // 자물쇠가 있는 API는 401 실패 예시(AUTH401_2)도 문서에 있어야 합니다.
                    assertThat(spec.at("/responses/401/content/application~1json/examples/TOKEN_MISSING/value/code").asText())
                            .as(operation + " 401 example").isEqualTo("AUTH401_2");
                }
            });
        }

        assertThat(operations).hasSize(15);
        assertThat(publicOperations).isEqualTo(new TreeSet<>(PUBLIC_OPERATIONS));
    }

    @Test
    @DisplayName("POST /favorites 문서의 409 예시는 실제 응답과 같은 FAVORITE409_1과 메시지를 담는다")
    void favoriteConflictExampleMatchesErrorCode() throws Exception {
        mockMvc.perform(get("/v3/api-docs"))
                .andExpect(jsonPath("$.paths['/favorites'].post.security[0].bearerAuth").isArray())
                .andExpect(jsonPath("$.paths['/favorites'].post.responses['201'].description").value("즐겨찾기 등록 성공"))
                .andExpect(jsonPath("$.paths['/favorites'].post.responses['409'].content['application/json']"
                        + ".examples.FAVORITE_DUPLICATED.value.code").value("FAVORITE409_1"))
                .andExpect(jsonPath("$.paths['/favorites'].post.responses['409'].content['application/json']"
                        + ".examples.FAVORITE_DUPLICATED.value.message").value("이미 이 영화를 즐겨찾기하셨습니다."))
                .andExpect(jsonPath("$.paths['/ratings/{ratingId}'].patch.responses['403'].description")
                        .value("`RATING403_1` 본인이 작성한 평점만 수정하거나 삭제할 수 있습니다."))
                .andExpect(jsonPath("$.components.securitySchemes.bearerAuth.scheme").value("bearer"));
    }
}
