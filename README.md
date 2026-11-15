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

## 실행
TMDB Read Access Token을 `FE/.env`에 넣은 뒤 실행합니다. `.env`는 Git에 올라가지 않습니다.
```bash
cd FE
cp .env.example .env   # TMDB_ACCESS_TOKEN= 뒤에 본인 Token 입력
flutter pub get
flutter run
```

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
