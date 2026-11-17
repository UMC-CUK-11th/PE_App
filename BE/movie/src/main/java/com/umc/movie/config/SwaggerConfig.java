package com.umc.movie.config;

import com.umc.movie.docs.ApiErrorCodes;
import com.umc.movie.exception.ErrorCode;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.examples.Example;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.media.Content;
import io.swagger.v3.oas.models.media.MediaType;
import io.swagger.v3.oas.models.responses.ApiResponse;
import io.swagger.v3.oas.models.responses.ApiResponses;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.springdoc.core.customizers.OperationCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.annotation.AnnotatedElementUtils;
import org.springframework.http.HttpStatus;
import org.springframework.web.method.HandlerMethod;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 9주차 실습 1: Swagger(OpenAPI) 문서의 표지와 인증 방식.
 * 문서 화면 /swagger-ui.html, 화면이 읽는 JSON /v3/api-docs (둘 다 AuthInterceptor 공개 목록에 있음)
 */
@Configuration
public class SwaggerConfig {

    // 각 API에 @SecurityRequirement(name = "bearerAuth")로 연결할 때 쓰는 이름입니다.
    public static final String BEARER_AUTH = "bearerAuth";

    private static final List<ErrorCode> AUTH_ERRORS =
            List.of(ErrorCode.TOKEN_MISSING, ErrorCode.TOKEN_INVALID, ErrorCode.TOKEN_EXPIRED);

    @Bean
    public OpenAPI movieOpenAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("영화 평점 서비스 API")
                        .description("""
                                UMC 11기 백엔드 워크북에서 만든 회원/평점/즐겨찾기 API 문서입니다.
                                실패 응답은 모두 { isSuccess:false, code, message, result:null } 형식입니다.
                                자물쇠가 있는 API는 POST /auth/login의 accessToken을 Authorize에 넣고 호출합니다.""")
                        .version("v1"))
                // 자물쇠 버튼(Authorize)에 쓸 인증 방식을 등록합니다. 어떤 API에 필요한지는 컨트롤러에서 지정합니다.
                .components(new Components()
                        .addSecuritySchemes(BEARER_AUTH, new SecurityScheme()
                                .type(SecurityScheme.Type.HTTP)
                                .scheme("bearer")
                                .bearerFormat("JWT")));
    }

    /**
     * 실패 응답 예시를 ErrorCode에서 만들어 붙입니다.
     * 손으로 JSON 예시를 적으면 message를 바꿀 때 문서가 조용히 틀어지므로, 실제 응답과 같은 값을 쓰게 합니다.
     */
    @Bean
    public OperationCustomizer errorResponseCustomizer() {
        return (operation, handlerMethod) -> {
            List<ErrorCode> errorCodes = new ArrayList<>();
            if (requiresToken(handlerMethod)) {
                errorCodes.addAll(AUTH_ERRORS);
            }
            ApiErrorCodes declared = handlerMethod.getMethodAnnotation(ApiErrorCodes.class);
            if (declared != null) {
                errorCodes.addAll(Arrays.asList(declared.value()));
            }
            if (errorCodes.isEmpty()) {
                return operation;
            }

            if (operation.getResponses() == null) {
                operation.setResponses(new ApiResponses());
            }
            Map<HttpStatus, List<ErrorCode>> byStatus = errorCodes.stream()
                    .collect(Collectors.groupingBy(ErrorCode::getStatus, LinkedHashMap::new, Collectors.toList()));
            byStatus.forEach((status, codes) ->
                    operation.getResponses().addApiResponse(String.valueOf(status.value()), toResponse(codes)));
            return operation;
        };
    }

    private boolean requiresToken(HandlerMethod handlerMethod) {
        return AnnotatedElementUtils.hasAnnotation(handlerMethod.getMethod(), SecurityRequirement.class)
                || AnnotatedElementUtils.hasAnnotation(handlerMethod.getBeanType(), SecurityRequirement.class);
    }

    private ApiResponse toResponse(List<ErrorCode> codes) {
        MediaType mediaType = new MediaType();
        for (ErrorCode code : codes) {
            Map<String, Object> body = new LinkedHashMap<>();
            body.put("isSuccess", false);
            body.put("code", code.getCode());
            body.put("message", code.getMessage());
            body.put("result", null);
            mediaType.addExamples(code.name(), new Example()
                    .summary(code.getCode() + " " + code.getMessage())
                    .value(body));
        }
        String description = codes.stream()
                .map(code -> "`" + code.getCode() + "` " + code.getMessage())
                .collect(Collectors.joining(" / "));
        return new ApiResponse()
                .description(description)
                .content(new Content().addMediaType("application/json", mediaType));
    }
}
