# BE (Spring Boot · JPA)

UMC 11기 PE 워크북 Backend 실습 코드입니다.

## 5주차~: 영화 평점 서비스 (`BE/movie`)

- Spring Boot 3.5.0 · Java 21 · 패키지 `com.umc.movie` (controller · service · repository · entity · dto · config)
- 영화 정보는 프론트가 TMDB를 직접 호출하고, 이 서버는 회원·평점(·8주차 즐겨찾기)만 담당합니다. 평점의 `movie_id`는 TMDB 영화 ID입니다.

### 실행 전 준비

1. MySQL에서 `movie/sql/01_schema.sql` → `02_seed.sql` 순서로 실행합니다. (`umc_movie` DB 생성 포함)
2. 환경 변수 `DB_PASSWORD`(필수), `DB_USER`(기본 `root`)를 실행 구성에 등록합니다.
3. `cd movie && ./gradlew bootRun`

### API

5주차 조회 API는 결과를 그대로, 6주차 저장 API는 `{ isSuccess, code, message, result }` 형식으로 응답합니다. 실패는 모두 같은 형식입니다.

| API | Method | URL | 성공 | 대표 실패 |
| --- | --- | --- | --- | --- |
| 닉네임 중복 체크 | GET | `/members/nickname/{nickname}` | 200 `{ "available": true }` | 400 형식 오류(2~12자) |
| 이메일 중복 체크 | GET | `/members/email/{email}` | 200 `{ "available": true }` | 400 형식 오류 |
| 유저별 평점 조회 | GET | `/members/{memberId}/ratings` | 200 평점 배열(최신순) | 404 `MEMBER4041` |
| 회원가입 | POST | `/members` `{ email, password, nickname }` | 201 `result: { memberId, email, nickname }` | 400 `COMMON4001`, 409 `MEMBER4091`(이메일)·`MEMBER4092`(닉네임)·`COMMON4091`(DB 제약) |
| 평점 등록 | POST | `/members/{memberId}/ratings` `{ movieId, score, comment }` | 201 `result: ratingId` | 400, 404 `MEMBER4041`, 409 `RATING4091` |
| 평점 수정 | PATCH | `/members/{memberId}/ratings/{ratingId}` `{ score, comment }` | 200 | 400, 403 `RATING4031`, 404 `RATING4041` |
| 평점 삭제 | DELETE | `/members/{memberId}/ratings/{ratingId}` | 204 | 403 `RATING4031`, 404 `RATING4041` |

- 비밀번호는 대문자·소문자·숫자·특수문자(`!@#$%^&*`)를 포함한 8자 이상이며 bcrypt 해시(60자)로만 저장합니다.
- 별점은 1~5, 후기는 500자 이하입니다.

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
