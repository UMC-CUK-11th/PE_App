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
flutter pub get
flutter run
```

`MOVIE_API_BASE_URL`은 실행 환경에 맞춰 설정합니다.

- iOS 시뮬레이터: `http://localhost:8080`
- Android 에뮬레이터: `http://10.0.2.2:8080`
- 실물 기기: Mac과 같은 Wi-Fi에서 Mac의 LAN IP 사용
- Flutter Web: 백엔드의 `CORS_ALLOWED_ORIGIN`과 같은 origin으로 실행

## 백엔드 실행

두 프로젝트는 서로 다른 터미널에서 독립적으로 실행합니다.
MySQL Workbench에서 데이터베이스가 없다면 먼저 생성합니다.

```sql
CREATE DATABASE IF NOT EXISTS umc11th_book_rental
    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS umc11th_movie
    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

```bash
# 도서 대여 프로젝트
cd BE/book-rental
export DB_URL=jdbc:mysql://localhost:3306/umc11th_book_rental
export DB_USERNAME=root
export DB_PASSWORD='실제_MySQL_비밀번호'
./gradlew bootRun
```

```bash
# 영화 프로젝트
cd BE/movie
export DB_URL=jdbc:mysql://localhost:3306/umc11th_movie
export DB_USERNAME=root
export DB_PASSWORD='실제_MySQL_비밀번호'
export CORS_ALLOWED_ORIGIN=http://localhost:5173
./gradlew bootRun
```
