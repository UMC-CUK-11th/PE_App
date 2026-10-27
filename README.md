# PE_App

UMC CUK 11th PE_App 미션 저장소입니다.

## 프로젝트 구조

```text
PE_App/
├── FE/                  # Flutter 프론트엔드
└── BE/
    ├── book-rental/     # 도서 대여 백엔드
    └── movie/           # 영화 백엔드
```

프론트엔드는 `FE/`, 백엔드는 `BE/`에서 각각 작업합니다. Git 브랜치 생성,
커밋, Push 등의 작업은 저장소 최상위 디렉터리를 기준으로 진행합니다.

## 프론트엔드 실행

```bash
cd FE
cp .env.example .env
# .env에 실제 TMDB_ACCESS_TOKEN과 실행 환경의 API 주소를 입력합니다.
flutter pub get
flutter run
```

## 백엔드 실행

```bash
# 도서 대여 프로젝트
cd BE/book-rental
./gradlew bootRun

# 영화 프로젝트
cd BE/movie
./gradlew bootRun
```

각 백엔드 프로젝트는 독립적인 Gradle 프로젝트이므로 해당 프로젝트 디렉터리에서 실행합니다.
