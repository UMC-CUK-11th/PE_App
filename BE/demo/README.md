# 6주차 — 회원가입과 평점 CRUD

Java 21 / Spring Boot 3.5.0 / MySQL. 기존 조회 API와 CORS 정책은 유지합니다.

## 실행

IntelliJ에서 DemoApplication 실행 또는 .\gradlew.bat bootRun. 포트는 3036입니다.
MySQL movie 스키마가 필요하며 ddl-auto=validate를 유지합니다. 처음 실행할 때는 먼저 테이블을 생성하세요.

1. MySQL에 접속해 CREATE DATABASE movie CHARACTER SET utf8mb4; 로 새 스키마를 생성합니다(이미 있으면 생략).
2. BE/demo 디렉터리에서 mysql -u root -p movie 로 접속한 뒤 SOURCE sql/create-tables.sql; 을 실행합니다. Windows에서는 SOURCE에 SQL 파일의 절대 경로를 써도 됩니다.
3. 아래 DB 비밀번호를 설정한 뒤 앱을 실행합니다. SQL은 초기 설치용으로, 기존 테이블을 삭제하거나 변경하지 않습니다. 이미 테이블이 있다면 실행하지 말고 엔티티와 컬럼·제약이 일치하는지 먼저 확인하세요.

테이블 정의는 [sql/create-tables.sql](sql/create-tables.sql)에 있습니다. 기존 데이터가 삭제되지 않도록 ddl-auto=validate를 유지합니다.
DB_PASSWORD 환경 변수 또는 Git에서 제외된 src/main/resources/application-local.yaml에 DB 비밀번호를 설정합니다.

## API 명세

| Method | URL | 성공 |
| --- | --- | --- |
| POST | /members | 201, result: memberId/email/nickname |
| POST | /members/{memberId}/ratings | 201, result: ratingId |
| PATCH | /members/{memberId}/ratings/{ratingId} | 200, result: null |
| DELETE | /members/{memberId}/ratings/{ratingId} | 204, 응답 본문 없음 |
| GET | /members/nickname?nickname={encodedNickname} | 200, available 응답 |
| GET | /members/nickname/{nickname} | 200, 이전 주차 호환용(단일 경로 세그먼트) |
| GET | /members/email?email={encodedEmail} | 200, available 응답 |
| GET | /members/email/{email} | 200, 이전 주차 호환용(단일 경로 세그먼트) |
| GET | /members/{memberId}/ratings | 200, 기존 평점 배열 응답 유지 |

회원가입 요청: email, nickname, password. 이메일 형식·최대 254자, 닉네임 2~12자, 비밀번호 대문자/소문자/숫자/특수문자 포함 8자 이상을 검증합니다. bcrypt 입력 제한 때문에 최대 72자 및 UTF-8 72바이트를 검증합니다. password와 bcrypt 해시는 응답에 포함하지 않습니다.
평점 등록 요청: movieId(양의 정수), score(1~5 정수), comment(null 허용, 최대 500자).
평점 수정 요청: score(필수), comment(선택). comment 생략 또는 null은 기존 후기를 유지하고, 빈 문자열은 후기를 비웁니다. PATCH에서 movieId는 변경하지 않습니다.
중복 확인에서도 가입과 동일하게 이메일·닉네임의 앞뒤 공백을 제거합니다. 슬래시 등이 포함된 값은 쿼리 파라미터로 URL 인코딩해 보내세요. 예: /members/nickname?nickname=%EC%A0%9C%EC%9E%84%EC%8A%A4%2F%ED%99%80%EB%9E%80%EB%93%9C.
FE는 외부 v5 워크북 서버의 기존 경로 계약을 사용하며, 이 로컬 BE로 연결된 클라이언트는 아닙니다.
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

- .\gradlew.bat test --no-daemon: 36개 통과 (실패/오류/건너뜀 0).
- test 프로필은 H2 전용이며 MySQL의 기존 데이터를 수정하지 않습니다.
- 두 요청의 사전 조회를 barrier로 동시에 통과시킨 뒤, 실제 H2 UNIQUE 제약으로 이메일·닉네임·평점 중복을 재현: 각 201 하나 + 409 하나, DB 1건 보존.
- 실제 MySQL HTTP 요청 17건 검증. 테스트 회원 3·4를 생성했고 평점은 등록→수정→삭제 후 빈 목록을 확인했습니다. 기존 회원 1·2 데이터는 수정하지 않았습니다.
- 테스트 계정의 비밀번호는 검증용 예시이며 원문/해시는 응답 및 인증 자료에서 제외했습니다.

src/main/resources/application-local.yaml 및 build/ 결과물은 Git에 포함하지 않습니다. FE·BE를 week06 브랜치와 PR 18에 함께 제출합니다.


## PR 18 리뷰 보완 검증

- 가입·중복 확인의 공백 정규화를 일치시키고, 특수문자 닉네임을 쿼리로 조회합니다. 이전 경로도 호환용으로 유지합니다.
- 별점만 PATCH하거나 comment를 null로 보내면 후기를 유지하고, 빈 문자열을 보내면 비웁니다.
- 예상치 못한 예외는 서버 로그에 스택 트레이스를 남기고 클라이언트에는 기존 COMMON500 응답만 보냅니다.
- 테스트에 회원별 평점 격리, 미사용 값의 available=true, 공백 포함 원시 JSON 가입, PATCH 후기 보존, 쿼리 필수값과 예외 로그를 추가했습니다.
- 새 임시 MySQL 8.0 스키마에 sql/create-tables.sql을 적용한 뒤 ddl-auto=validate 상태로 서버 기동을 확인했습니다. 슬래시 닉네임·공백·후기 보존/비우기를 실제 HTTP 요청 11건으로 추가 검증했습니다. 기존 movie 데이터는 변경하지 않았습니다.
