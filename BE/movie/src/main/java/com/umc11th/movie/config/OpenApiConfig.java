package com.umc11th.movie.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI movieLogOpenApi() {
        return new OpenAPI()
                .info(new Info()
                        .title("MovieLog API")
                        .version("v9")
                        .description("회원가입·로그인은 공개 API이며, 내 정보·평점·즐겨찾기·영화 기록 API는 Bearer 토큰이 필요합니다."))
                .components(new Components().addSecuritySchemes(
                        "bearerAuth",
                        new SecurityScheme()
                                .type(SecurityScheme.Type.HTTP)
                                .scheme("bearer")
                                .bearerFormat("JWT")
                                .description("Authorization: Bearer {token}")
                ));
    }
}
