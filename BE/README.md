# BE (Spring Boot · Raw SQL)

UMC 11기 PE 워크북 Backend 실습 코드입니다.

- Spring Boot 3.5.0 · Java 21 · Gradle
- 의존성: Spring Web, JDBC API, MySQL Driver, Lombok
- 패키지: `com.umc.study` (Controller → Service → Repository 3계층)

## 실행 전 준비

1. MySQL에 실습 DB를 만들고 `sql/week02/01_schema.sql` → `02_seed.sql` 순서로 실행합니다.
2. IntelliJ 실행 구성에 환경 변수 3개를 등록합니다. 값은 코드에 적지 않습니다.
   - `DB_URL` = `jdbc:mysql://localhost:3306/<DB 이름>`
   - `DB_USER` = MySQL 계정
   - `DB_PW` = MySQL 비밀번호

## API (3주차)

| Method | URL | 설명 |
| --- | --- | --- |
| GET | `/books` | 도서 전체 목록 |
| POST | `/books` | 도서 등록 `{ "categoryId": 1, "title": "...", "description": "..." }` |
| GET | `/books/category/{categoryId}` | 카테고리별 도서 목록 |
| POST | `/rentals` | 대여 기록 생성 `{ "userId": 1, "bookId": 3 }` (반납 예정일 7일 뒤) |
| PATCH | `/rentals/{rentalId}/return` | 반납 처리 |

## SQL (2주차)

`sql/week02/`에 공통 스키마·시드, 미션 1~3 조회 쿼리, 1주차 내 ERD 확장 쿼리가 있습니다.
