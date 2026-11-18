package com.umc.movie.docs;

import com.umc.movie.exception.ErrorCode;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * 이 API가 돌려줄 수 있는 실패 응답을 {@link ErrorCode}로 적습니다.
 * SwaggerConfig가 상태 코드별로 묶어 { isSuccess:false, code, message, result:null } 예시를 문서에 그려 줍니다.
 * 토큰이 필요한 API(@SecurityRequirement)의 401(AUTH401_2/3/4)은 자동으로 붙으므로 적지 않습니다.
 */
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
public @interface ApiErrorCodes {

    ErrorCode[] value();
}
