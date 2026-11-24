#!/bin/bash
# backend.env 를 읽어 BE/movie 를 실행합니다.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
set -a; source "$HERE/backend.env"; set +a
cd "$HERE/../BE/movie"
exec ./gradlew bootRun
