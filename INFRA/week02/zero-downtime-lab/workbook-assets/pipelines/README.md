# Fleet Management 파이프라인

2주차 3.4 에서 Grafana Cloud 에 등록할 수집 파이프라인 정의입니다.

## 쓰는 법

**Connections → Fleet Management → Remote configuration → Create configuration pipeline**

1. **Select configuration** — `Alloy` + `Custom configuration` → Next
2. **Define configuration** — 이름을 넣고 아래 파일 내용을 붙여넣은 뒤
   **`Test configuration pipeline`** 으로 검증 → Next
3. **Assign matching attributes** — 어느 수집기에 적용할지 고른다

| 파일 | 파이프라인 이름 | 하는 일 |
|---|---|---|
| `01-host-metrics.alloy` | `umc_host_metrics` | CPU·메모리·디스크 |
| `02-mysql-metrics.alloy` | `umc_mysql_metrics` | RDS 지표 |
| `03-app-metrics.alloy` | `umc_app_metrics` | 앱이 직접 내는 지표 (2주차 4.3 이후 동작). **Node.js·Spring Boot 양쪽을 지원합니다 — 아래 환경변수** |

**워크북이 등록하는 것은 위 셋입니다.**

| (선택) | | |
|---|---|---|
| `04-app-logs.alloy` | `umc_app_logs` | 앱 stdout → Loki. 2주차는 로그를 붙이지 않습니다(5.2). 선택 미션으로 직접 해볼 때 쓰세요 |

> **이름 규칙이 있습니다.** 영문자·숫자·밑줄만 되고 **숫자로 시작할 수 없습니다.**
> 한글이나 하이픈을 넣으면 거절당합니다.

> **`Test configuration pipeline` 을 먼저 통과해야 저장 버튼이 열립니다.**
> 네 파일 모두 통과하는 것을 확인했습니다 (`Syntax Valid` · `Configuration No issues`).
> 로그 파이프라인을 쓰려면 `GC_LOKI_URL` · `GC_LOKI_USER` 도 SSM 에 넣고 넘겨야 합니다.

## 인스턴스에서 넘겨야 하는 환경변수

파이프라인은 `sys.env()` 로 값을 읽습니다. **인스턴스의 `docker run` 에서 넘어와야 합니다.**

| 변수 | 쓰는 파이프라인 |
|---|---|
| `GC_PROM_URL` · `GC_PROM_USER` | 01, 02, 03 |
| `GC_LOKI_URL` · `GC_LOKI_USER` | 04 |
| `APP_METRICS_ADDR` · `APP_METRICS_PATH` | 03 — **안 넘기면 Node.js 기본값** |

### 앱 프레임워크별 — `03-app-metrics.alloy`

파일을 고치지 않고 환경변수로 가릅니다. **안 넘기면 Node.js 로 동작합니다.**

| | `APP_METRICS_ADDR` | `APP_METRICS_PATH` |
|---|---|---|
| **Node.js** (NestJS) | `127.0.0.1:3000` (기본값) | `/metrics` (기본값) |
| **Spring Boot** | `127.0.0.1:8080` | `/actuator/prometheus` |

Spring Boot 는 Actuator 가 `/actuator/prometheus` 로 노출하고 기본 포트가 8080 입니다.
**둘 중 하나만 틀려도 증상이 같습니다** — `up{job="app"}` 이 0 에서 안 올라옵니다.

> **실측 확인.** `grafana/alloy:v1.20.1` 로 돌려 스크랩 요청이 실제로 가는 경로를 확인했습니다 —
> 환경변수를 주면 `/actuator/prometheus`, 안 주면 `/metrics` 로 갑니다.
> 파이프라인 다섯 개 전부 `alloy validate` 통과.
| `GC_TOKEN` | 전부 |
| `MYSQL_DSN` | 02 |

> ⚠️ **파이프라인에 값을 직접 박지 마세요.** 파이프라인 정의는 Grafana Cloud 에 저장되고
> 화면에서 그대로 보입니다. **비밀값은 인스턴스 쪽 SSM 에 두고 환경변수로 넘깁니다.**
