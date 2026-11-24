#!/bin/bash
# 한계 측정 한 단계 실행 (워크북 6.1)
#   ./run-stage.sh 200        → 200 rps 로 40초
#   ./run-stage.sh 400 60     → 400 rps 로 60초
#
# 1) 이 단계 전용 회원을 새로 만든다  ((회원, 영화) 유니크 제약 때문에 단계마다 새 회원)
# 2) 로그인해 accessToken 을 받는다   (토큰은 화면에 찍지 않는다)
# 3) 한 건을 손으로 보내 201 을 확인한다
# 4) 부하 측정 랩에 시나리오를 보내고, 끝나면 결과를 results/ 에 저장한다
set -euo pipefail
cd "$(dirname "$0")"

RPS="${1:?사용법: ./run-stage.sh <rps> [초]}"
DURATION="${2:-40}"
API="${API:-http://localhost:8080}"
LAB="${LAB:-http://localhost:9376}"
TARGET_FROM_LAB="${TARGET_FROM_LAB:-http://host.docker.internal:8080}"

STAMP=$(date +%s)
EMAIL="lab-${RPS}-${STAMP}@test.local"
NICK="l${RPS}$((STAMP % 100000))"
PASS='LabTest1234!'   # 측정 전용 테스트 계정 비밀번호

echo "▶ ${RPS} rps · ${DURATION}s — 전용 회원 생성 (${EMAIL})"
curl -sf -X POST "$API/v8/members" -H 'Content-Type: application/json' \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASS\",\"nickname\":\"${NICK:0:12}\"}" > /dev/null

TOK=$(curl -sf -X POST "$API/v8/auth/login" -H 'Content-Type: application/json' \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASS\"}" \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["result"]["accessToken"])')

CODE=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$API/v8/movie-records" \
  -H 'Content-Type: application/json' -H "Authorization: Bearer $TOK" \
  -d '{"movieId": 999999, "score": 5, "comment": "t", "addToFavorites": true}')
echo "▶ 수동 1건: [$CODE]"
[ "$CODE" = "201" ] || { echo "201 이 아니면 부하를 걸지 않습니다."; exit 1; }

SCENARIO=$(python3 - "$RPS" "$DURATION" "$TARGET_FROM_LAB" "$TOK" <<'PY'
import json,sys
rps,dur,url,tok=int(sys.argv[1]),int(sys.argv[2]),sys.argv[3],sys.argv[4]
print(json.dumps({
 "name": f"한계 측정 {rps}rps",
 "target": {"url": f"{url}/v8/movie-records","method":"POST",
   "headers":{"Content-Type":"application/json","Authorization":f"Bearer {tok}"},
   "body":"{\"movieId\": {{counter}}, \"score\": 5, \"comment\": \"lab\", \"addToFavorites\": true}",
   "timeoutMs":5000},
 "success":{"statusCodes":[200,201]},
 "load":{"rps":rps,"durationSec":dur},
 "analysis":{"slowThresholdMs":1000,"baselineSec":8,"minConsecutiveFailures":3}}))
PY
)
RUN=$(curl -sf -X POST "$LAB/api/runs" -H 'Content-Type: application/json' -d "$SCENARIO" \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["runId"])')
echo "▶ 측정 시작 $(date '+%H:%M:%S') (runId ${RUN:0:8}) — 랩 화면: $LAB"

while :; do
  sleep 3
  S=$(curl -sf "$LAB/api/runs/$RUN" | python3 -c 'import sys,json;print(json.load(sys.stdin)["status"])')
  [ "$S" = "running" ] || break
done
echo "▶ 측정 종료 $(date '+%H:%M:%S') ($S)"

mkdir -p results
curl -sf "$LAB/api/runs/$RUN/export.json" \
  | python3 -c 'import sys,json;d=json.load(sys.stdin);d["scenario"]["target"]["headers"]["Authorization"]="Bearer <redacted>";json.dump(d,sys.stdout,ensure_ascii=False)' \
  > "results/${RPS}rps.json"

python3 - "results/${RPS}rps.json" "$DURATION" <<'PY'
import json,sys
d=json.load(open(sys.argv[1])); s=d["summary"]; t=s["totals"]; p=s["percentiles"] or {}
dur=int(sys.argv[2])
def ms(v): return "-" if v is None else f"{v:,.0f}ms"
print(f"  보냄 {t['sent']:,}  성공 {t['success']:,}  실패 {t['failure']:,} {t['byType']}  dropped {t['dropped']:,}")
print(f"  처리량 {t['success']/dur:,.1f}/s   p50 {ms(p.get('p50'))}   p95 {ms(p.get('p95'))}   p99 {ms(p.get('p99'))}")
PY
