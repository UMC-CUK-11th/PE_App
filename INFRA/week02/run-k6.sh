#!/bin/bash
# ./run-k6.sh 1000 1500 2000 ...   단계 사이 90초 쉰다
set -euo pipefail
cd "$(dirname "$0")"; mkdir -p results
for r in "$@"; do
  echo "▶ k6 ${r} rps 시작 $(date '+%H:%M:%S')"
  docker run --rm -i -e RPS="$r" --add-host=host.docker.internal:host-gateway \
    -v "$PWD/results:/results" grafana/k6:1.3.0 run --quiet - < k6-stage.js
  echo "▶ k6 ${r} rps 종료 $(date '+%H:%M:%S')"
  sleep 90
done
