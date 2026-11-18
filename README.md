# PE_App
UMC CUK 11th PE_App

## 폴더 구조
```
PE_App/
├── FE/   # MovieLog Flutter 앱
└── BE/   # 백엔드 (준비 중)
```

## MovieLog
UMC 11기 PE(Mobile) 파트 Flutter 워크북 미션 앱입니다.

| 주차 | 브랜치 | 내용 |
|---|---|---|
| 0주차 | `feature/week-0` | 초기 세팅 및 영화 기록 시작 화면 |
| 1주차 | `feature/week-1` | UI 기초와 Material 3 · 내 프로필 화면 |
| 2주차 | `week02` | 레이아웃과 사용자 입력 · 회원가입 Form |
| 3주차 | `week03` | 화면 전환과 사용자 인터랙션 · GoRouter |
| 4주차 | `week04` | 비동기 영화 목록 상태 · 장르 저장 |
| 5주차 | `week05` | TMDB 영화 API와 MVVM·Provider |
| 6주차 | `week06` | 중복 확인 연동·내가 등록한 평점 / 회원가입·평점 저장 API |
| 7주차 | `week07` | 회원가입 POST·평점 등록/수정/삭제(v6 CRUD)·다중 삭제 |
| 8주차 | `week08` | JWT 로그인·세션 복원·v7 토큰 기반 평점·내 정보 수정 / BE 즐겨찾기·영화 기록 트랜잭션 |
| 9주차 | `week09` | v8 즐겨찾기 연동·내 즐겨찾기·영화 목록 페이지네이션(무한 스크롤)·영화 검색 / BE 테스트하고 다듬기 |

## 실행
TMDB Read Access Token을 `FE/.env`에 넣은 뒤 실행합니다. `.env`는 Git에 올라가지 않습니다.
```bash
cd FE
cp .env.example .env   # TMDB_ACCESS_TOKEN= 뒤에 본인 Token 입력
flutter pub get
flutter run
```

워크북 백엔드(`https://workbook.devnoco.com`)의 v8 API를 기본으로 호출합니다. accessToken은 `flutter_secure_storage`에만 저장하고, 보호 API(`/v8/members/me`, `/v8/ratings`, `/v8/favorites`, `/v8/movie-records`)에만 Bearer를 붙입니다. 로컬 백엔드를 쓰려면 `.env`에 `MOVIELOG_API_BASE_URL`을 지정합니다.

요청 실패 재현: `flutter run --dart-define=TMDB_ACCESS_TOKEN=invalid` (401 로그 확인)

## 5주차 구조
```
FE/lib/
├── app/          # MultiProvider로 TmdbMovieService 공유
├── core/         # TMDB Config(.env)·Dio Client·로깅 Interceptor(Token 마스킹)
├── data/         # TMDB DTO·TmdbMovieService·장르 저장소
├── view_models/  # MovieHomeViewModel(인기 5개), MovieListViewModel(Discover 최대 30개·장르)
├── screens/      # View: 상태 표시와 입력 전달만 담당
└── widgets/      # TmdbPosterImage(poster null·로드 실패 placeholder)
```
