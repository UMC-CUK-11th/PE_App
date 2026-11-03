# 6주차 — 회원가입과 평점 CRUD

Java 21 / Spring Boot 3.5.0 / MySQL. 기존 조회 API와 CORS 정책은 유지합니다.

## 실행

IntelliJ에서 DemoApplication 실행 또는 .\gradlew.bat bootRun. 포트는 3036입니다.
MySQL movie 스키마가 필요하며 ddl-auto=validate를 유지합니다.
DB_PASSWORD 환경 변수 또는 Git에서 제외된 src/main/resources/application-local.yaml에 DB 비밀번호를 설정합니다.

## API 명세

| Method | URL | 성공 |
| --- | --- | --- |
| POST | /members | 201, result: memberId/email/nickname |
| POST | /members/{memberId}/ratings | 201, result: ratingId |
| PATCH | /members/{memberId}/ratings/{ratingId} | 200, result: null |
| DELETE | /members/{memberId}/ratings/{ratingId} | 204, 응답 본문 없음 |
| GET | /members/nickname/{nickname} | 200, 기존 available 응답 유지 |
| GET | /members/email/{email} | 200, 기존 available 응답 유지 |
| GET | /members/{memberId}/ratings | 200, 기존 평점 배열 응답 유지 |

회원가입 요청: email, nickname, password. 이메일 형식·최대 254자, 닉네임 2~12자, 비밀번호 대문자/소문자/숫자/특수문자 포함 8자 이상을 검증합니다. bcrypt 입력 제한 때문에 최대 72자 및 UTF-8 72바이트를 검증합니다. password와 bcrypt 해시는 응답에 포함하지 않습니다.
평점 등록 요청: movieId(양의 정수), score(1~5 정수), comment(null 허용, 최대 500자).
평점 수정 요청: score(필수), comment(선택). PATCH에서 movieId는 변경하지 않습니다.
현재 주차는 로그인 전이므로 경로 memberId와 저장된 소유자를 비교합니다. 이것은 실제 로그인 인증을 대신하지 않으며 JWT 주차에 토큰 기반으로 변경합니다.

## 공통 응답

저장 API 성공과 모든 실패는 isSuccess/code/message/result를 사용합니다. 204에는 본문을 보내지 않습니다. 기존 GET의 성공 응답은 워크북 예시대로 유지합니다.

- MEMBER4091: 이메일 중복 / MEMBER4092: 닉네임 중복
- RATING4091: 같은 회원·영화 조합 중복
- COMMON400: 검증 실패, 잘못된 JSON, 소수 별점 등
- RATING4031: 다른 회원의 평점 수정·삭제
- MEMBER4041 / RATING4041: 없는 회원 또는 평점
- COMMON500: 상세 DB 오류를 노출하지 않는 서버 오류

## 선택미션과 트랜잭션

사전 중복 조회 후에도 동시에 저장하면 UNIQUE 충돌이 가능합니다. saveAndFlush로 DB 제약을 확인하고 트랜잭션이 롤백된 뒤 전역 예외 처리에서 409로 변환합니다. MySQL 1062 / H2 SQLState 23505를 식별하고 회원 이메일·닉네임 오류를 구분합니다. 다른 무결성 오류를 무조건 중복 오류로 숨기지 않습니다.
비밀번호 해싱은 spring-security-crypto만 사용하며 로그인 필터를 새로 적용하지 않습니다. 기본 bcrypt 비용은 10입니다.

## 검증 (2026-11-03)

- .\gradlew.bat test --no-daemon: 32개 통과 (실패/오류/건너뜀 0).
- test 프로필은 H2 전용이며 MySQL의 기존 데이터를 수정하지 않습니다.
- 두 요청의 사전 조회를 barrier로 동시에 통과시킨 뒤, 실제 H2 UNIQUE 제약으로 이메일·닉네임·평점 중복을 재현: 각 201 하나 + 409 하나, DB 1건 보존.
- 실제 MySQL HTTP 요청 17건 검증. 테스트 회원 3·4를 생성했고 평점은 등록→수정→삭제 후 빈 목록을 확인했습니다. 기존 회원 1·2 데이터는 수정하지 않았습니다.
- 테스트 계정의 비밀번호는 검증용 예시이며 원문/해시는 응답 및 인증 자료에서 제외했습니다.

src/main/resources/application-local.yaml 및 build/ 결과물은 Git에 포함하지 않습니다. 현재 BE 작업은 로컬 수정이며 FE 전용 week06 PR에 추가하지 않았습니다.
