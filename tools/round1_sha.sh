#!/usr/bin/env bash
# Round-1 corpus hash: compacts every FitRequest of the frozen 1.8.0 corpus (suites/round1/cases, one pretty-printed
# JSON file per case) into one JSONL line each, feeds all of them to a single `ENGINE batch` process and prints the
# sha256 of the FitStats JSONL output. This is exactly what the engine's ci/run_suites.sh does for its
# ci/round1.sha256 check; the corpus source commit is recorded in suites/round1/SOURCE.
#   tools/round1_sha.sh ENGINE
set -euo pipefail
ENGINE=$(readlink -f "$1")
BENCH=$(cd "$(dirname "$0")/.." && pwd)
for f in "$BENCH"/suites/round1/cases/*.json; do
  python3 -c "import json,sys;print(json.dumps(json.load(open(sys.argv[1]))))" "$f"
done | "$ENGINE" batch | sha256sum | cut -d' ' -f1
