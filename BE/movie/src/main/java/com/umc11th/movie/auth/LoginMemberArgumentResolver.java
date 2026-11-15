package com.umc11th.movie.auth;

import com.umc11th.movie.exception.AuthException;
import org.springframework.core.MethodParameter;
import org.springframework.stereotype.Component;
import org.springframework.web.bind.support.WebDataBinderFactory;
import org.springframework.web.context.request.NativeWebRequest;
import org.springframework.web.method.support.HandlerMethodArgumentResolver;
import org.springframework.web.method.support.ModelAndViewContainer;

@Component
public class LoginMemberArgumentResolver implements HandlerMethodArgumentResolver {

    @Override
    public boolean supportsParameter(MethodParameter parameter) {
        return parameter.hasParameterAnnotation(LoginMember.class)
                && Long.class.equals(parameter.getParameterType());
    }

    @Override
    public Object resolveArgument(
            MethodParameter parameter,
            ModelAndViewContainer mavContainer,
            NativeWebRequest webRequest,
            WebDataBinderFactory binderFactory
    ) {
        Object memberId = webRequest.getAttribute(
                JwtAuthenticationInterceptor.LOGIN_MEMBER_ATTRIBUTE,
                NativeWebRequest.SCOPE_REQUEST
        );
        if (!(memberId instanceof Long)) {
            throw AuthException.missingToken();
        }
        return memberId;
    }
}
