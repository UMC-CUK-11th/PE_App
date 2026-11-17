package com.umc.movie.config;

import io.swagger.v3.oas.annotations.OpenAPIDefinition;
import io.swagger.v3.oas.annotations.enums.SecuritySchemeType;
import io.swagger.v3.oas.annotations.info.Info;
import io.swagger.v3.oas.annotations.security.SecurityScheme;
import org.springframework.context.annotation.Configuration;

/** Swagger UI: /swagger-ui/index.html. 우측 상단 Authorize에 로그인 accessToken을 넣습니다. */
@Configuration
@OpenAPIDefinition(info = @Info(title = "UMC Movie API", version = "week08",
        description = "실패 응답은 모두 { isSuccess:false, code, message, result:null } 형식입니다."))
@SecurityScheme(name = "bearerAuth", type = SecuritySchemeType.HTTP, scheme = "bearer", bearerFormat = "JWT")
public class OpenApiConfig {
}
