package com.umc11th.movie.exception;

import com.umc11th.movie.dto.ApiResponse;
import jakarta.validation.ConstraintViolationException;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.server.ResponseStatusException;

@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final String EMAIL_CONSTRAINT = "uk_member_email";
    private static final String NICKNAME_CONSTRAINT = "uk_member_nickname";

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponse<Void>> handleValidation(
            MethodArgumentNotValidException exception
    ) {
        String message = exception.getBindingResult().getFieldErrors().stream()
                .findFirst()
                .map(error -> error.getDefaultMessage())
                .orElse("요청 값이 올바르지 않습니다.");
        return ResponseEntity.badRequest()
                .body(ApiResponse.failure("COMMON4001", message));
    }

    @ExceptionHandler(ConstraintViolationException.class)
    public ResponseEntity<ApiResponse<Void>> handleConstraintViolation(
            ConstraintViolationException exception
    ) {
        String message = exception.getConstraintViolations().stream()
                .findFirst()
                .map(violation -> violation.getPropertyPath() + ": " + violation.getMessage())
                .orElse("요청 값이 올바르지 않습니다.");
        return ResponseEntity.badRequest()
                .body(ApiResponse.failure("COMMON4001", message));
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<ApiResponse<Void>> handleDataIntegrity(
            DataIntegrityViolationException exception
    ) {
        String causeMessage = getCauseMessages(exception).toLowerCase();
        if (causeMessage.contains(EMAIL_CONSTRAINT)) {
            return conflict(MemberConflictException.duplicateEmail());
        }
        if (causeMessage.contains(NICKNAME_CONSTRAINT)) {
            return conflict(MemberConflictException.duplicateNickname());
        }
        if (isLegacyMemberUniqueViolation(causeMessage)) {
            String duplicateValue = extractDuplicateValue(causeMessage);
            if (duplicateValue.contains("@")) {
                return conflict(MemberConflictException.duplicateEmail());
            }
            return conflict(MemberConflictException.duplicateNickname());
        }
        return ResponseEntity.status(HttpStatus.CONFLICT)
                .body(ApiResponse.failure("COMMON4091", "이미 존재하는 데이터입니다."));
    }

    @ExceptionHandler(MemberConflictException.class)
    public ResponseEntity<ApiResponse<Void>> handleMemberConflict(
            MemberConflictException exception
    ) {
        return conflict(exception);
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<ApiResponse<Void>> handleIllegalArgument(
            IllegalArgumentException exception
    ) {
        return ResponseEntity.status(HttpStatus.CONFLICT)
                .body(ApiResponse.failure("COMMON4092", exception.getMessage()));
    }

    @ExceptionHandler(ResponseStatusException.class)
    public ResponseEntity<ApiResponse<Void>> handleResponseStatus(
            ResponseStatusException exception
    ) {
        int status = exception.getStatusCode().value();
        return ResponseEntity.status(exception.getStatusCode())
                .body(ApiResponse.failure("COMMON" + status, exception.getReason()));
    }

    private ResponseEntity<ApiResponse<Void>> conflict(MemberConflictException exception) {
        return ResponseEntity.status(HttpStatus.CONFLICT)
                .body(ApiResponse.failure(exception.getCode(), exception.getMessage()));
    }

    private String getCauseMessages(Throwable throwable) {
        StringBuilder messages = new StringBuilder();
        Throwable current = throwable;
        while (current != null) {
            if (current.getMessage() != null) {
                messages.append(' ').append(current.getMessage());
            }
            current = current.getCause();
        }
        return messages.toString();
    }

    private boolean isLegacyMemberUniqueViolation(String causeMessage) {
        return causeMessage.contains("duplicate entry")
                && causeMessage.contains("key 'member.");
    }

    private String extractDuplicateValue(String causeMessage) {
        String prefix = "duplicate entry '";
        int start = causeMessage.indexOf(prefix);
        if (start < 0) {
            return "";
        }
        start += prefix.length();
        int end = causeMessage.indexOf("'", start);
        return end < 0 ? "" : causeMessage.substring(start, end);
    }
}
