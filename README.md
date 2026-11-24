# PE_App

UMC CUK 11th PE_App 미션 저장소입니다.

## 프로젝트 구조

```text
PE_App/
├── FE/                  # Flutter 기반 프론트엔드
├── BE/                  # Spring Boot 기반 백엔드
│   ├── book-rental/        # 도서 대여 서비스
│   └── movie/              # 영화 서비스
└── INFRA/               # Docker·Grafana·k6 기반 인프라
```

프론트엔드는 `FE/`, 백엔드는 `BE/`, 인프라는 `INFRA/`에서 각각 작업합니다. Git 브랜치 생성,
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
export JWT_SECRET='32바이트_이상의_충분히_긴_비밀키'
export JWT_ACCESS_EXPIRATION=3600
./gradlew bootRun
```

## 인프라 실행

Docker Desktop과 Grafana Cloud 스택을 준비한 뒤 실행합니다.

```bash
cd INFRA
cp .env.example .env
# .env에 Grafana Cloud, MySQL, 애플리케이션 지표 정보를 입력
docker compose up -d --build
```

`.env`의 `GC_PROM_URL`, `GC_PROM_USER`, `GC_TOKEN`, `MYSQL_DSN`, `APP_METRICS_ADDR`는
실행 환경에 맞춰 설정합니다.

- 측정 화면: `http://localhost:9376`
- Alloy 상태: `http://localhost:12345`
- Grafana 대시보드: `INFRA/dashboard.json`

영화 백엔드를 실행한 상태에서 부하를 측정합니다.

```bash
# 내장 측정 랩: 200 RPS, 40초
./run-stage.sh 200 40

# k6 고부하 단계: 800, 1200 RPS
./run-k6.sh 800 1200
```

측정 결과는 `INFRA/results/`에 저장됩니다. `.env`, `backend.env`,
토큰과 기타 민감 정보는 커밋하지 않습니다.
