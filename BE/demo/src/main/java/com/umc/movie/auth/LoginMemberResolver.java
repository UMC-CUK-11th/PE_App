package com.umc.movie.auth;

import org.springframework.core.MethodParameter;
import org.springframework.stereotype.Component;
import org.springframework.web.bind.support.WebDataBinderFactory;
import org.springframework.web.context.request.NativeWebRequest;
import org.springframework.web.context.request.RequestAttributes;
import org.springframework.web.method.support.HandlerMethodArgumentResolver;
import org.springframework.web.method.support.ModelAndViewContainer;

@Component
public class LoginMemberResolver implements HandlerMethodArgumentResolver {
    /** 로그인 회원 ID로 선언한 Long 인자에만 적용합니다. */
    @Override
    public boolean supportsParameter(MethodParameter parameter) {
        return parameter.hasParameterAnnotation(LoginMember.class)
            && parameter.getParameterType() == Long.class;
    }

    /** 인터셉터가 저장한 검증된 회원 ID만 컨트롤러에 전달합니다. */
    @Override
    public Object resolveArgument(MethodParameter parameter, ModelAndViewContainer container,
        NativeWebRequest request, WebDataBinderFactory binderFactory) {
        Object memberId = request.getAttribute(JwtInterceptor.MEMBER_ID, RequestAttributes.SCOPE_REQUEST);
        if (memberId instanceof Long id) return id;
        throw AuthError.MISSING_TOKEN.exception();
    }
}
