# 5주차 Spring Boot 실습

- Java 21, MySQL, Spring Boot 3.5.0
- 기본 패키지: com.umc.movie
- 서버 포트: 3036
- DB: localhost:3306/movie (기존 스키마를 validate하므로 테이블과 시드 데이터가 필요합니다.)

## 실행

DB_PASSWORD 환경 변수에 로컬 MySQL 비밀번호를 설정하고 IntelliJ의 DemoApplication을 실행합니다.
또는 Git에서 제외된 src/main/resources/application-local.yaml에 아래 로컬 설정을 작성합니다.

```yaml
spring:
  datasource:
    password: "자신의 MySQL 비밀번호"
```

비밀번호가 들어 있는 application-local.yaml은 커밋하지 않습니다.
터미널에서는 Windows 기준 .\gradlew.bat bootRun으로 실행할 수 있습니다.

## API

- GET /members/nickname/{nickname}: 닉네임 중복 여부 (available)
- GET /members/email/{email}: 이메일 중복 여부 (available)
- GET /members/{memberId}/ratings: 회원별 평점 목록, ratingId 내림차순
- 존재하지 않는 회원의 평점 조회: 404
- CORS 허용 출처: http://localhost:5173

현재 저장된 코드는 필수미션 기준입니다. 선택미션의 입력 검증과 페이지네이션은 아직 포함하지 않습니다.
