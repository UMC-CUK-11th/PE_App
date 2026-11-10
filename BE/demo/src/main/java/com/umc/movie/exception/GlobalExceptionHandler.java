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
import org.springframework.web.HttpRequestMethodNotSupportedException;
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
    /**
     * 명시적인 HTTP 예외의 상태 코드를 보존한 공통 오류 응답을 만듭니다.
     *
     * @param error 응답 상태와 선택적인 사용자 안내를 가진 예외
     * @return COMMON 상태 코드와 안내 문구; 안내가 없으면 기본 문구를 사용한 응답
     */
    @ExceptionHandler(ResponseStatusException.class)
    public ResponseEntity<ApiResponse<Void>> status(ResponseStatusException error) {
        return response(error.getStatusCode().value(), "COMMON" + error.getStatusCode().value(),
            error.getReason() == null ? "요청을 처리하지 못했습니다." : error.getReason());
    }
    @ExceptionHandler(NoResourceFoundException.class)
    public ResponseEntity<ApiResponse<Void>> notFound(NoResourceFoundException error) {
        return response(404, "COMMON404", "요청 경로를 찾을 수 없습니다.");
    }
    @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
    public ResponseEntity<ApiResponse<Void>> methodNotAllowed(HttpRequestMethodNotSupportedException error) {
        return ResponseEntity.status(405).headers(error.getHeaders())
            .body(ApiResponse.error("COMMON405", "지원하지 않는 요청 방식입니다."));
    }
    /**
     * 저장 중 발생한 중복 키 위반을 회원 또는 평점의 409 오류로 변환합니다.
     * MySQL 1062와 H2 SQLState 23505를 중복으로 판별하며, 그 외 무결성 오류는 500입니다.
     * 가입 충돌 종류는 제약 이름으로 구분하고, 이름이 불명확하면 서비스 트랜잭션이
     * 롤백된 뒤 요청 속성의 이메일과 닉네임으로 재조회합니다. DB 원문은 응답하지 않습니다.
     *
     * @param error SQL 원인과 제약 이름을 확인할 저장 예외
     * @param request 가입 여부와 정규화된 가입 정보를 담은 요청
     * @return 중복 종류별 409 공통 응답 또는 중복이 아닌 무결성 오류의 500 응답
     */
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
        if (request.getAttribute("profile.nickname") instanceof String nickname
            && (constraint.contains("nickname") || memberRepository.existsByNickname(nickname))) {
            return response(409, "MEMBER409_1", "이미 사용 중인 닉네임입니다.");
        }
        if (constraint.contains("rating_member_movie")) {
            return response(409, "RATING409_1", "이미 이 영화에 평점을 남기셨습니다.");
        }
        return response(500, "COMMON500", "저장 중 오류가 발생했습니다.");
    }
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<Void>> unexpected(Exception error) {
        log.error("처리되지 않은 예외가 발생했습니다.", error);
        return response(500, "COMMON500", "서버에서 요청을 처리하지 못했습니다.");
    }
}
