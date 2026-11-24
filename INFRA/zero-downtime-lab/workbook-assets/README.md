# 워크북 자료

UMC Infra 워크북 **2주차**에서 쓰는 설정 파일들입니다. 이 저장소의 측정 도구(1주차)와는
별개이고, 여기 같이 두는 이유는 **학생이 이미 이 저장소를 clone 하기 때문**입니다.

| 파일 | 어디서 쓰나 | 무엇 |
|---|---|---|
| **`pipelines/`** | **2주차 3.4** | **Grafana Cloud 에 등록할 수집 파이프라인 3개. 이 워크북이 쓰는 길입니다** (로그용 1개는 선택) |
| `dashboard.json` | 2주차 4.5 | Grafana 대시보드. *Dashboards → New → Import* 로 붙여넣습니다 |
| `config.alloy` | — | **[대안]** 위 파이프라인을 인스턴스 안에 직접 둔 판본. 아래를 읽고 고르세요 |

---

## 어느 쪽을 쓰나 — 먼저 읽으세요

**수집 설정을 어디에 둘 것인가**가 갈립니다. 2주차 3.1 의 주제가 바로 이 선택입니다.

| | 설정이 사는 곳 | 바꾸려면 | 워크북 |
|---|---|---|---|
| **A. `pipelines/`** (권장) | **Grafana Cloud** | 화면에서 고치면 수집기가 받아간다 | **3장이 가는 길** |
| B. `config.alloy` | 인스턴스 안의 파일 | 파일을 고치고 **인스턴스를 교체** | 탈출구 |

> ⚠️ **B 를 고르면 3.4 의 확인 단계가 통째로 실패합니다.**
> `config.alloy` 에는 `remotecfg` 블록이 **없습니다.** 그래서 Fleet Management 의
> **Inventory 에 수집기가 영영 안 뜹니다** — 3.4 는 "Inventory 에 2대가 보여야 합니다"로
> 진행 여부를 판정하는데, B 로는 그 화면이 비어 있습니다. 고장이 아니라 **다른 길**입니다.
>
> **Fleet Management 가 막혔을 때만 B 로 가세요.** 그때도 지표는 똑같이 올라갑니다.

---

## A — `pipelines/` (권장)

`pipelines/README.md` 에 등록 절차가 있습니다. 인스턴스에는 **10줄짜리 `remotecfg` 설정만**
두고(2주차 3.3), 수집 내용은 Grafana Cloud 에서 내려받습니다.

## B — `config.alloy` (대안)

EC2 인스턴스에서 내려받아 씁니다.

```bash
sudo mkdir -p /opt/alloy
sudo curl -fsSL https://raw.githubusercontent.com/UMC-11th-Workbook-Infra/zero-downtime-lab/main/workbook-assets/config.alloy \
  -o /opt/alloy/config.alloy
```

2주차 3.3 의 `docker run` 을 그대로 쓰되 **환경변수 세 개를 뺍니다.** `remotecfg` 가 없으니
설정을 받아올 일이 없고, Grafana 기본 self-monitoring 파이프라인도 안 내려옵니다.

```diff
-  -e GC_FLEET_URL -e GC_FLEET_USER -e GC_TOKEN \
-  -e GCLOUD_RW_API_KEY \
+  -e GC_TOKEN \
```

남는 것은 `GC_TOKEN` · `GC_PROM_URL` · `GC_PROM_USER` · `MYSQL_DSN` 네 개입니다.
전부 SSM Parameter Store 에서 옵니다(2주차 3.2 의 표). 로그까지 보내려면
`GC_LOKI_URL` · `GC_LOKI_USER` 를 추가로 넘기세요.

## dashboard.json

Import 할 때 데이터소스로 **Grafana Cloud 의 Prometheus** 를 고르세요.

「앱」 줄 맨 왼쪽의 **「DB 커넥션 — 연결 vs 실행」** 패널을 눈여겨보세요. 두 선의 차이는
유휴 연결 때문에도 생길 수 있어 이 패널만으로 커넥션 풀 고갈을 단정할 수 없습니다.
풀 고갈은 앱의 풀 사용량(active/max)과 대기 요청(pending)을 함께 확인하세요. 2주차 4.5 를 보세요.
