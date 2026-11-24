// 한계 측정 — 랩(최대 1,000 rps)으로 부족한 구간을 k6 로 이어서 잰다.
//   docker run --rm -i -e RPS=1200 -v "$PWD/results:/results" grafana/k6:1.3.0 run - < k6-stage.js
import http from 'k6/http';
import { check } from 'k6';
import exec from 'k6/execution';

const API = __ENV.API || 'http://host.docker.internal:8080';
const RPS = Number(__ENV.RPS || 1000);
const DURATION = __ENV.DURATION || '40s';

function durationSeconds(value) {
  const unitSeconds = { ms: 0.001, s: 1, m: 60, h: 3600 };
  const token = /(\d+(?:\.\d+)?)(ms|s|m|h)/g;
  let total = 0;
  let consumed = 0;
  let match;
  while ((match = token.exec(value)) !== null) {
    if (match.index !== consumed) throw new Error(`지원하지 않는 DURATION 형식: ${value}`);
    total += Number(match[1]) * unitSeconds[match[2]];
    consumed = token.lastIndex;
  }
  if (consumed !== value.length || total <= 0) throw new Error(`지원하지 않는 DURATION 형식: ${value}`);
  return total;
}

export const options = {
  discardResponseBodies: true,
  scenarios: {
    limit: {
      executor: 'constant-arrival-rate',
      rate: RPS,
      timeUnit: '1s',
      duration: DURATION,
      preAllocatedVUs: Math.max(200, RPS),
      maxVUs: RPS * 6,
    },
  },
  summaryTrendStats: ['avg', 'med', 'p(95)', 'p(99)', 'max'],
};

// 단계마다 전용 회원을 새로 만든다 ((회원, 영화) 유니크 제약)
export function setup() {
  const stamp = Date.now();
  const email = `k6-${RPS}-${stamp}@test.local`;
  const password = 'LabTest1234!';
  const json = { headers: { 'Content-Type': 'application/json' }, responseType: 'text' };
  http.post(`${API}/v8/members`, JSON.stringify({ email, password, nickname: `k${RPS}${stamp % 10000}`.slice(0, 12) }), json);
  const login = http.post(`${API}/v8/auth/login`, JSON.stringify({ email, password }), json);
  const token = login.json('result.accessToken');
  const first = http.post(`${API}/v8/movie-records`,
    JSON.stringify({ movieId: 999999, score: 5, comment: 't', addToFavorites: true }),
    { headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` } });
  if (first.status !== 201) throw new Error(`수동 1건이 ${first.status} — 부하를 걸지 않습니다`);
  return { token };
}

export default function (data) {
  // scenario 전체에서 겹치지 않는 일련번호 → movieId
  const movieId = exec.scenario.iterationInTest + 1;
  const res = http.post(`${API}/v8/movie-records`,
    JSON.stringify({ movieId, score: 5, comment: 'lab', addToFavorites: true }),
    { headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${data.token}` }, timeout: '5s' });
  check(res, { '201': (r) => r.status === 201 });
}


export function handleSummary(d) {
  const m = d.metrics;
  const fail = m.checks ? m.checks.values.fails : 0;
  const out = {
    rps: RPS,
    requests: m.http_reqs.values.count,
    throughput: m.http_reqs.values.rate,
    ok: m.checks ? m.checks.values.passes : 0,
    failed: fail,
    dropped: m.dropped_iterations ? m.dropped_iterations.values.count : 0,
    p50: m.http_req_duration.values.med,
    p95: m.http_req_duration.values['p(95)'],
    p99: m.http_req_duration.values['p(99)'],
  };
  const line = `  ${RPS} rps  처리량 ${(out.ok / durationSeconds(DURATION)).toFixed(1)}/s  p50 ${out.p50.toFixed(0)}ms  p95 ${out.p95.toFixed(0)}ms  p99 ${out.p99.toFixed(0)}ms  실패 ${out.failed}  dropped ${out.dropped}\n`;
  return { stdout: line, [`/results/k6-${RPS}rps.json`]: JSON.stringify(out) };
}
