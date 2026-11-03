package com.umc.movie.exception;

import com.umc.movie.dto.ApiResponse;
import com.umc.movie.repository.MemberRepository;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.ConstraintViolationException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.method.annotation.HandlerMethodValidationException;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.servlet.resource.NoResourceFoundException;
import java.sql.SQLException;
import java.util.Locale;
import java.util.stream.Collectors;

@RestControllerAdvice
@RequiredArgsConstructor
@Slf4j
public class GlobalExceptionHandler {
    private final MemberRepository memberRepository;
    private ResponseEntity<ApiResponse<Void>> response(int status, String code, String message) {
        return ResponseEntity.status(status).body(ApiResponse.error(code, message));
    }
    @ExceptionHandler(ApiException.class)
    public ResponseEntity<ApiResponse<Void>> business(ApiException error) {
        return response(error.getStatus().value(), error.getCode(), error.getMessage());
    }
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponse<Void>> validation(MethodArgumentNotValidException error) {
        // rejectedValue에는 비밀번호가 들어갈 수 있어 응답/로그에 포함하지 않습니다.
        String message = error.getBindingResult().getAllErrors().stream()
            .map(e -> e.getDefaultMessage()).distinct().sorted().collect(Collectors.joining(" "));
        return response(400, "COMMON400", message);
    }
    @ExceptionHandler({HandlerMethodValidationException.class, ConstraintViolationException.class})
    public ResponseEntity<ApiResponse<Void>> methodValidation(Exception error) {
        return response(400, "COMMON400", "요청 ID와 입력값의 형식을 확인해주세요.");
    }
    @ExceptionHandler({HttpMessageNotReadableException.class, MethodArgumentTypeMismatchException.class})
    public ResponseEntity<ApiResponse<Void>> malformed(Exception error) {
        return response(400, "COMMON400", "JSON 형식과 정수 입력값을 확인해주세요.");
    }
    @ExceptionHandler(MissingServletRequestParameterException.class)
    public ResponseEntity<ApiResponse<Void>> missingParameter(MissingServletRequestParameterException error) {
        return response(400, "COMMON400", "필수 쿼리 파라미터를 입력해주세요.");
    }
    @ExceptionHandler(ResponseStatusException.class)
    public ResponseEntity<ApiResponse<Void>> status(ResponseStatusException error) {
        return response(error.getStatusCode().value(), "COMMON" + error.getStatusCode().value(),
            error.getReason() == null ? "요청을 처리하지 못했습니다." : error.getReason());
    }
    @ExceptionHandler(NoResourceFoundException.class)
    public ResponseEntity<ApiResponse<Void>> notFound(NoResourceFoundException error) {
        return response(404, "COMMON404", "요청 경로를 찾을 수 없습니다.");
    }
    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<ApiResponse<Void>> database(DataIntegrityViolationException error, HttpServletRequest request) {
        boolean unique = false;
        String constraint = "";
        for (Throwable cause = error; cause != null; cause = cause.getCause()) {
            if (cause instanceof SQLException sql &&
                (sql.getErrorCode() == 1062 || "23505".equals(sql.getSQLState()))) unique = true;
            if (cause instanceof org.hibernate.exception.ConstraintViolationException violation &&
                violation.getConstraintName() != null) constraint = violation.getConstraintName().toLowerCase(Locale.ROOT);
        }
        if (!unique) return response(500, "COMMON500", "저장 중 오류가 발생했습니다.");
        if (request.getAttribute("signup.email") instanceof String email) {
            if (constraint.contains("email")) return response(409, "MEMBER4091", "이미 사용 중인 이메일입니다.");
            if (constraint.contains("nickname")) return response(409, "MEMBER4092", "이미 사용 중인 닉네임입니다.");
            // Service 트랜잭션 롤백이 끝난 뒤에 조회합니다. 실패한 트랜잭션 안에서 조회하지 않습니다.
            if (memberRepository.existsByEmail(email)) return response(409, "MEMBER4091", "이미 사용 중인 이메일입니다.");
            if (request.getAttribute("signup.nickname") instanceof String nickname && memberRepository.existsByNickname(nickname))
                return response(409, "MEMBER4092", "이미 사용 중인 닉네임입니다.");
            return response(409, "MEMBER4090", "이미 사용 중인 회원 정보입니다.");
        }
        return response(409, "RATING4091", "이미 이 영화에 평점을 남기셨습니다.");
    }
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<Void>> unexpected(Exception error) {
        log.error("처리되지 않은 예외가 발생했습니다.", error);
        return response(500, "COMMON500", "서버에서 요청을 처리하지 못했습니다.");
    }
}
