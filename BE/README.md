# BE (Spring Boot · JPA)

UMC 11기 PE 워크북 Backend 실습 코드입니다.

## 5주차~: 영화 평점 서비스 (`BE/movie`)

- Spring Boot 3.5.0 · Java 21 · 패키지 `com.umc.movie` (controller · service · repository · entity · dto · config · exception · docs)
- 영화 정보는 프론트가 TMDB를 직접 호출하고, 이 서버는 회원·평점·즐겨찾기만 담당합니다. `movie_id`는 TMDB 영화 ID입니다.
- 9주차 기준 API 계약은 워크북 참조 서버 `/v8` 명세(15개 API)와 같습니다.

### 실행 전 준비

1. MySQL에서 `movie/sql/01_schema.sql` → `02_seed.sql` 순서로 실행합니다. (`umc_movie` DB 생성 포함)
2. 환경 변수 `DB_PASSWORD`(필수), `DB_USER`(기본 `root`)를 실행 구성에 등록합니다.
   JWT는 `JWT_SECRET`(32바이트 이상), `JWT_ACCESS_EXPIRATION`(초, 기본 3600)으로 덮어씁니다. 기본 secret은 로컬 개발용입니다.
3. `cd movie && ./gradlew bootRun`
4. 테스트: `./gradlew test` (MySQL 없이 H2 메모리 DB로 실행)

### API 문서 (9주차 Swagger)

- 문서 화면 `http://localhost:8080/swagger-ui.html`, 화면이 읽는 JSON `http://localhost:8080/v3/api-docs` (둘 다 토큰 없이 열림)
- `POST /auth/login`의 `accessToken`을 Authorize에 넣으면 자물쇠 API에 `Bearer`가 자동으로 붙습니다.
- 실패 응답 예시는 손으로 적지 않고 `ErrorCode` enum에서 만듭니다. 컨트롤러 메서드에 `@ApiErrorCodes({...})`만 적으면
  `SwaggerConfig`가 상태 코드별 예시를 그리고, `@SecurityRequirement`가 있는 API에는 401(`AUTH401_2/3/4`)을 자동으로 붙입니다.
- `SwaggerDocsTest`가 "15개 API 모두 summary 있음 · 공개 5개만 자물쇠 없음 · 409 예시 = 실제 code/message"를 지킵니다.

### 인증

- `Authorization: Bearer {token}` (HS256, subject = memberId). `AuthInterceptor`는 기본 "모든 경로 보호"이고 아래 표의 (공개) API와 Swagger 경로만 예외입니다.
- 토큰 없음 `AUTH401_2`, 무효 `AUTH401_3`, 만료 `AUTH401_4` (모두 401)

### API

조회 3종(중복 체크 2개·유저별 평점)은 결과를 그대로, 나머지는 `{ isSuccess, code, message, result }`로 응답합니다. 실패는 모두 같은 형식입니다.

| API | Method | URL | 성공 | 실패 code |
| --- | --- | --- | --- | --- |
| 닉네임 중복 체크 (공개) | GET | `/members/nickname/{nickname}` | 200 `{ available }` | 400 `COMMON400`(2~12자) |
| 이메일 중복 체크 (공개) | GET | `/members/email/{email}` | 200 `{ available }` | 400 `COMMON400` |
| 유저별 평점 조회 (공개) | GET | `/members/{memberId}/ratings` | 200 평점 배열(ratingId 내림차순) | 404 `MEMBER404_1` |
| 회원가입 (공개) | POST | `/members` `{ email, password, nickname }` | 201 `{ memberId, email, nickname }` | 400 `COMMON400`, 409 `COMMON409`(이메일·닉네임·DB 제약) |
| 로그인 (공개) | POST | `/auth/login` `{ email, password }` | 200 `{ nickname, accessToken }` | 400 `COMMON400`, 401 `AUTH401_1` |
| 내 정보 조회 | GET | `/members/me` | 200 `{ email, nickname, createdAt }` | 401, 404 `MEMBER404_1` |
| 내 정보 수정 | PATCH | `/members/me` `{ nickname }` | 200 `{ email, nickname, createdAt }` | 400, 401, 404, 409 `MEMBER409_1`(자기 닉네임은 허용) |
| 평점 등록 | POST | `/ratings` `{ movieId, score, comment }` | 201 평점 객체 | 400, 401, 404 `MEMBER404_1`, 409 `RATING409_1` |
| 평점 수정 | PATCH | `/ratings/{ratingId}` `{ score, comment }` | 200 평점 객체(comment 생략 시 null로 교체) | 400, 401, 403 `RATING403_1`, 404 `RATING404_1` |
| 평점 삭제 | DELETE | `/ratings/{ratingId}` | 200 `result: null` | 401, 403 `RATING403_1`, 404 `RATING404_1` |
| 즐겨찾기 등록 | POST | `/favorites` `{ movieId }` | 201 `{ favoriteId, movieId, createdAt }` | 400, 401, 404, 409 `FAVORITE409_1`·`COMMON409` |
| 내 즐겨찾기 | GET | `/favorites` | 200 배열(최신 등록순, 없으면 `[]`) | 401 |
| 즐겨찾기 여부 | GET | `/favorites/{movieId}` | 200 `{ isFavorite }` | 400, 401 |
| 즐겨찾기 해제 | DELETE | `/favorites/{movieId}` | 200 `result: null` | 401, 404 `FAVORITE404_1` |
| 영화 기록 | POST | `/movie-records` `{ movieId, score, comment, addToFavorites }` | 201 `{ rating, favorite }` | 400, 401, 404, 409 `RATING409_1`·`FAVORITE409_1` |

- 9주차에 에러 code를 `ErrorCode` enum 하나로 모으고 `{도메인}{상태}_{번호}` 형식으로 통일했습니다.
  6주차 `MEMBER4041`·`RATING4091`·`RATING4031`·`RATING4041` → `MEMBER404_1`·`RATING409_1`·`RATING403_1`·`RATING404_1`,
  `COMMON4001` → `COMMON400`, `COMMON4091`·`MEMBER4091/4092` → `COMMON409`.
- 6주차 `/members/{memberId}/ratings` 쓰기(POST·PATCH·DELETE)는 7주차 계약대로 `/ratings`로 옮겼습니다. 예전 쓰기 경로는 405 `COMMON405`입니다.
- 비밀번호는 대문자·소문자·숫자·특수문자(`!@#$%^&*`)를 포함한 8자 이상이며 bcrypt 해시(60자)로만 저장합니다. 별점은 1~5, 후기는 500자 이하입니다.
- `POST /movie-records`는 평점 INSERT 후 즐겨찾기 중복을 확인합니다. `FAVORITE409_1`이면 `@Transactional`이 평점까지 rollback합니다.
- `created_at`·`updated_at`은 저장 전에 초 단위로 자릅니다. MySQL `DATETIME`이 소수 초를 반올림해 응답 값과 DB 값이 달라지는 문제를 막습니다.

### 테스트 (9주차, 54개)

| 종류 | 클래스 | 확인하는 것 |
| --- | --- | --- |
| 단위(Mockito) | `service.FavoriteServiceTest` | 실습 4: 즐겨찾기 저장 / 중복이면 `FAVORITE409_1`·save 미호출 |
| 단위(Mockito) | `service.RatingServiceTest` | 미션: 중복 등록 `RATING409_1`, 남의 평점 수정 `RATING403_1`(값 그대로), 등록 성공, 없는 평점 `RATING404_1` |
| 통합(H2) | `controller.FavoriteApiTest` | 실습 5: 토큰 없음 401 · 등록 201 · 중복 409 · 미등록 여부 200 false · `/v3/api-docs` 공개 |
| 통합(H2) | `controller.RatingApiTest` | 미션: `POST /ratings` 토큰 없음 401 · 토큰 있음 201, 중복 409, 남의 평점 403, 수정·삭제 200, 공개 조회 |
| 통합(H2) | `controller.MemberApiTest` | `GET/PATCH /members/me` 200·401·409 `MEMBER409_1`·400 |
| 통합(H2) | `controller.MovieRecordApiTest` | 선택 미션: 이미 즐겨찾기한 영화 기록 → 409, 평점 개수 그대로(테스트에 `@Transactional` 없음) |
| 통합(H2) | `controller.SwaggerDocsTest` | 문서 회귀: 15개 API·summary·자물쇠·실패 예시 |
| 시나리오(H2) | `controller.AuthFlowScenarioTest` | 실습 2·3 클릭 순서: 가입 → 로그인 → 201 → 409 → 토큰 없이 401 |
| 슬라이스 | `AuthApiTest`, `FavoriteControllerTest`, `WriteApiTest`, `MemberControllerTest` | 컨트롤러 응답 형식·검증·401 코드 구분·CORS |
| 통합(H2) | `MovieRecordTransactionTest` | 8주차: UNIQUE 위반 시 평점 rollback |

테스트 설정은 `src/test/resources/application.yml`(H2 `MODE=MySQL`, `ddl-auto: create-drop`)입니다. 이 파일은 main 설정을 덮어쓰지 않고 통째로 가리므로 jwt·springdoc 값도 함께 적어 둡니다.

CORS는 `http://localhost:5173`만 허용합니다. 브라우저 확인은 `mock-frontend/`(`npx serve -l 5173`) 또는 Flutter Web(`flutter run -d web-server --web-port 5173`)으로 합니다.

## 0~4주차: 도서 대여 서비스 (`BE/` 루트)


- Spring Boot 3.5.0 · Java 21 · Gradle
- 의존성: Spring Web, Spring Data JPA, Validation, MySQL Driver, Lombok
- 패키지: `com.umc.study` (Controller → Service → Repository 3계층 + entity · dto · exception)
- 3주차 Raw SQL 버전은 `week03` 브랜치에 그대로 있습니다. 도서 API는 4주차에 JPA로 바꿨고 대여 API는 JdbcTemplate을 유지합니다.

## 실행 전 준비

1. MySQL에 실습 DB를 만들고 `sql/week02/01_schema.sql` → `02_seed.sql` 순서로 실행합니다.
   4주차 중복 제목 방지까지 쓰려면 `sql/week04/01_add_unique_title.sql`도 실행합니다.
   `ddl-auto: validate`라 서버가 테이블을 만들지 않고 엔티티와 구조가 맞는지만 확인합니다.
2. IntelliJ 실행 구성에 환경 변수 3개를 등록합니다. 값은 코드에 적지 않습니다.
   - `DB_URL` = `jdbc:mysql://localhost:3306/<DB 이름>`
   - `DB_USER` = MySQL 계정
   - `DB_PW` = MySQL 비밀번호

## API

| Method | URL | 설명 |
| --- | --- | --- |
| GET | `/books` | 도서 전체 목록 (최신순, `?keyword=`로 제목 검색) |
| POST | `/books` | 도서 등록 `{ "categoryId": 1, "title": "...", "description": "..." }` → 201 · 검증 실패 400 · 없는 카테고리 404 · 중복 제목 409 |
| GET | `/books/category/{categoryId}` | 카테고리별 도서 목록 (없는 카테고리 404) |
| POST | `/rentals` | 대여 기록 생성 `{ "userId": 1, "bookId": 3 }` (반납 예정일 7일 뒤) |
| PATCH | `/rentals/{rentalId}/return` | 반납 처리 |

## SQL

- `sql/week02/`: 공통 스키마·시드, 미션 1~3 조회 쿼리, 1주차 내 ERD 확장 쿼리
- `sql/week04/`: 제목 UNIQUE 제약 추가
