# 5주차 — TMDB API · MVVM · Provider

노션의 Guided Practice, Required Mission, Challenge Mission 요구사항에 맞춰 기존 MovieLog 앱을 수정했습니다. 노션에 있던 다른 작성자의 트러블슈팅·완료 기록은 사용하지 않았습니다.

## 실행

1. 이 폴더(`C:\develope\umc11th\FE`)를 VS Code에서 엽니다.
2. `.env` 파일에 `TMDB_READ_ACCESS_TOKEN=발급받은문자열`을 저장합니다. `Bearer` 접두사는 넣지 않습니다.
3. `flutter pub get` 후 F5로 실행합니다. VS Code 실행 구성에는 Debug와 Release를 추가했습니다.
4. 시작 → 회원가입 → 홈으로 이동하거나 영화 탭을 선택합니다. 기존 회원가입·즐겨찾기·평점은 화면 연습용 동작이며 백엔드 저장은 이번 미션 범위가 아닙니다.

TMDB 계정의 https://www.themoviedb.org/settings/api 에서 **API Read Access Token**을 발급받습니다. API Key와는 다른 항목입니다.
`.env`는 Git에서 제외합니다. 새로 받은 프로젝트에서는 `.env.example`을 `.env`로 복사합니다. Flutter 클라이언트에 포함되는 설정 파일이므로 서버용 비밀키 저장소로 사용하지 않습니다.

## 구현 내용

- Guided Practice: Popular 응답 DTO → 앞 5개 → MovieHomeViewModel → Provider → 홈 화면. 빌드마다 API를 호출하지 않습니다. null/로드 실패 포스터는 대체 이미지를 표시합니다.
- Required Mission: Genre API의 ID·이름으로 Chip을 구성합니다. Discover를 1페이지부터 조회하고 TMDB ID로 중복 제거하여 최대 30개를 구성합니다. 빈 페이지나 마지막 페이지에 도달하면 종료합니다.
- 장르 변경은 서버의 `with_genres`로 다시 요청합니다. 전체 선택 시 이 파라미터를 생략합니다. 로딩 중에는 장르 선택과 중복 요청을 차단합니다.
- Challenge Mission: 기존 장르 BottomSheet를 재사용해 다중 선택합니다. 상태는 `List<int>?`이며 ID를 `|`로 연결하여 OR 조건으로 요청합니다.
- Pull to Refresh는 선택한 장르를 유지하고 1페이지부터 다시 로딩합니다. 빈 목록도 새로고침할 수 있습니다. Loading 중에는 제스처를 차단합니다.
- 요청 실패 시 마지막 성공 목록을 복구·유지하고 재시도/취소 Dialog를 표시합니다. 재시도는 마지막으로 선택한 장르로 최대 30개 로딩 전체를 다시 실행합니다.
- 로그는 Debug 모드에서만 출력하며 Authorization을 마스킹합니다. 응답 상태 코드와 실패 URL·오류 메시지를 기록합니다.
- 영화 카드에서 상세 화면까지 TMDB ID를 그대로 전달합니다. 영화 상세 URL로 직접 들어오면 해당 ID를 API로 조회합니다.

## 구조

- `models/tmdb_movie_dto.dart`: API 응답 DTO, Genre, 페이지 응답 및 화면 모델 변환
- `services/tmdb_client.dart`: Dio 생성, 인증, 시간 제한, 마스킹 로그
- `services/tmdb_movie_service.dart`: Popular / Discover / Genre / Detail API
- `view_models/`: 홈·목록의 상태, 중복 제거, 페이지 수집, 장르 선택, 정렬, 재시도
- `screens/`: Provider 상태를 구독하고 UI 표시
- `widgets/tmdb_poster.dart`: 네트워크 포스터와 대체 화면

앱 최상단 MultiProvider는 Dio와 Service를 공유하고 각 Route의 ChangeNotifierProvider가 ViewModel 생명주기를 관리합니다. ViewModel이 해제되면 진행 중 요청을 취소합니다.

## 이번 작업에서 실제로 확인한 트러블슈팅

### 1. 기존 장르 이름을 TMDB ID로 전환

기존 목록은 `SF` 같은 이름과 Mock 데이터의 로컬 필터를 사용했습니다. TMDB 요청은 장르 ID가 필요하므로, Genre DTO와 `List<int>?` 상태를 만들고 URL·선택 저장 값·BottomSheet를 ID 기반으로 전환했습니다. 기존에 저장된 문자열 장르는 숫자로 변환 가능한 값만 복원합니다.

검증: 장르 다중 선택, URL 반영, OR 요청, 전체 선택 시 파라미터 생략 테스트 통과.

### 2. 실제 TMDB 인증 실패와 로그 마스킹 재현

이번 작업에서 의도적으로 잘못된 테스트 토큰을 전송했습니다. 실제 TMDB 서버의 401 응답을 확인했습니다. 아래는 이 실행에서 출력된 로그 첫 줄들입니다.

```text
[TMDB] REQUEST GET https://api.themoviedb.org/3/movie/popular?language=ko-KR&page=1 Authorization: Bearer ***
[TMDB] ERROR 401 https://api.themoviedb.org/3/movie/popular?language=ko-KR&page=1 This exception was thrown because the response has a status code of 401 and RequestOptions.validateStatus was configured to throw for this status code.
```

검증: 실제 토큰 문자열 미노출 확인. 자동 테스트에서는 성공·실패 모두의 마스킹 및 로그 비활성화도 확인했습니다. `kDebugMode` 조건은 Release에서 로그 출력을 차단합니다.

재현 명령: `flutter test tool/tmdb_failure_probe.dart --reporter expanded`

### 3. 실패 시 기존 성공 목록 보존

새 장르 요청이나 새로고침이 실패하면 API에서 일부 받아온 결과로 목록을 바꾸지 않도록 전체 요청 완료 시에만 성공 목록을 교체했습니다. 실패 시 이전 성공 목록을 복구하고 Dialog에서 재시도 여부를 받습니다.

검증: 첫 요청 실패, 기존 목록 유지, Dialog 취소, 재시도 성공, 마지막 장르 유지, 로딩 중 중복 요청 차단 테스트 통과. 네트워크를 실제로 끄는 기기 조작은 아직 수행하지 않았습니다.

## 검증 상태

- 자동 테스트: 원본 경로 C:\develope\umc11th\FE에서 29개 통과.
- 실제 서버 잘못된 토큰 요청: 401 확인, 마스킹 확인. git check-ignore FE/.env로 Git 제외 확인.
- 실제 유효 토큰 검증 통과: Popular 5개, Genre 19개, Discover 중복 없는 30개. 다중 장르 with_genres=12|28 및 전체 선택 재조회까지 모두 HTTP 200 확인.
- 정적 분석: No issues found. Release 웹 빌드: 성공. 토큰 설정 후 최종 빌드 재검증도 성공(80.4초).
- 기기 네트워크를 끈 상태의 Dialog 수동 확인: 미실행. 같은 실패/회복 상태 전이는 자동 테스트로 확인했습니다.

유효한 토큰을 저장한 뒤 실행할 실제 API 검증 명령:

```text
flutter test tool/tmdb_live_probe.dart --reporter expanded
```

실제 기기 확인 순서: 영화 목록 성공 → 네트워크 끄기 → 아래로 당겨 새로고침 → 기존 목록과 재시도 Dialog 확인 → 네트워크 켜기 → 재시도 → 최신 목록 교체 확인.

공식 참고: https://developer.themoviedb.org/reference/discover-movie , https://developer.themoviedb.org/docs/authentication-application



## 실제 앱 화면 확인

2026-10-27 로컬 웹 앱에서 TMDB 포스터·제목과 홈 인기 영화 5개가 표시되는 것을 확인했습니다. 영화 탭에서 장르 BottomSheet의 액션·모험을 함께 선택하고 확인했으며, URL에 genre=28&genre=12가 반영되고 선택 개수 2와 두 Chip의 선택 상태 및 필터된 목록이 표시됨을 확인했습니다. 요청 중에는 Chip이 비활성화되며 완료 후 다시 활성화됩니다. 이후 전체 목록으로 복원했습니다.
