# 7주차 · 로그인한 사용자를 구분하기

Java 21, Spring Boot, MySQL. [기존 DB 초기 설치 절차](README.md#실행)를 사용합니다.

## 실행

PowerShell에서 서명키를 환경 변수에 넣은 뒤 실행합니다. 새 키를 만들면 이전 키로 발급한 토큰은 유효하지 않습니다. 같은 키를 계속 사용하려면 로컬의 안전한 설정에 보관합니다.

```powershell
$env:JWT_SECRET = [Convert]::ToBase64String([System.Security.Cryptography.RandomNumberGenerator]::GetBytes(32))
$env:JWT_ACCESS_EXPIRATION = '3600'
.\gradlew.bat bootRun
```

서명키는 32바이트를 Base64로 인코딩한 값이고 유효기간 단위는 초입니다. 포트는 3036입니다. 기존 DB 설정은 `DB_PASSWORD` 또는 Git에서 제외된 `application-local.yaml`을 사용합니다.

## API

| 요청 | 입력 | 성공 |
| --- | --- | --- |
| POST /auth/login | email, password | 200, nickname과 accessToken |
| GET /members/me | Bearer 토큰 | 200, email·nickname·createdAt |
| PATCH /members/me | Bearer 토큰과 nickname | 200, 수정된 회원 정보 |
| POST /ratings | Bearer 토큰과 movieId·score·comment | 201, 생성된 평점 |
| PATCH /ratings/{ratingId} | Bearer 토큰과 score·comment | 200, 수정된 평점 |
| DELETE /ratings/{ratingId} | Bearer 토큰 | 200, result는 null |

새 API의 성공과 오류는 `isSuccess`, `code`, `message`, `result`를 사용합니다. 회원가입과 공개 조회의 응답 형식은 기존과 같습니다. v7의 평점 PATCH는 값 전체를 교체하므로 코멘트를 생략하면 기존 후기는 null이 됩니다. 6주차의 회원 ID 기반 평점 쓰기 경로는 제거했습니다.

## 구현 과정

1. 가입 때 저장한 bcrypt 해시를 로그인 요청과 비교합니다. 이메일이 없거나 비밀번호가 틀리면 같은 응답을 사용합니다.
2. JJWT로 HS256 토큰을 만들고, 서버에서 서명·발급자·만료를 확인합니다. 토큰에는 주체인 회원 ID를 담습니다.
3. MVC 인터셉터가 검증한 회원 ID를 요청 속성에 보관합니다. `@LoginMember`와 인자 리졸버가 컨트롤러 인자로 전달합니다.
4. 평점 수정과 삭제에서는 저장된 소유자의 ID를 토큰에서 읽은 ID와 비교합니다. 닉네임과 평점의 중복은 DB 제약으로도 차단합니다.

| 코드 | 의미 |
| --- | --- |
| AUTH401_1 | 이메일 또는 비밀번호 불일치 |
| AUTH401_2 | 토큰 누락 |
| AUTH401_3 | 유효하지 않거나 위조된 토큰 |
| AUTH401_4 | 토큰 만료 |
| MEMBER404_1 / MEMBER409_1 | 회원 없음 / 닉네임 중복 |
| RATING404_1 / RATING403_1 / RATING409_1 | 평점 없음 / 소유권 거부 / 중복 평점 |

## 검증

- `.\gradlew.bat test --no-daemon`으로 H2에서 회귀 테스트와 인증 테스트를 실행합니다.
- 실제 HTTP 확인은 임시 H2 서버에서 두 회원을 가입시켜 로그인, 평점 등록·중복·본인 수정·타인 수정·인증 없는 수정·없는 평점 삭제·본인 삭제를 순서대로 실행했습니다.
- 선택 과제는 토큰 수명을 60초로 설정해 같은 토큰의 만료 전 200과 만료 후 `AUTH401_4`를 비교했습니다. `@LoginMember` 적용 전에는 컨트롤러가 요청 속성에서 ID를 읽어야 했고, 적용 후에는 `@LoginMember Long memberId`로 선언합니다.

FE 7주차 실습은 외부 워크북 v6을 사용합니다. 이 프로젝트의 새 JWT API는 BE 실습용입니다. [v7 Swagger](https://workbook.devnoco.com/docs/v7-json)
