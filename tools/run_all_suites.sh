#!/usr/bin/env bash
# Run every bench suite on one engine binary and write the outputs check_no_regress.py reads.
#   tools/run_all_suites.sh ENGINE OUT [NAME]
# ENGINE: exfa binary (calc / batch / serve-stdio). OUT: output dir (created). NAME: result label (default ci).
# PRICE_RULE_CMD: optional updater command for the d22 price_rule suite (docs/22 §3.2; not an engine suite, so not in
# baselines/exfa-engine.json); SDE_PACK: optional real edp v1 pack, enables the pending d22 sde / price_inject cases.
# core / ext / ext_rpc / batch / effects / sde / price_inject run from this checkout. graphs, cap, mutated and formats
# run from the flattened snapshots in suites/<name>/ (each has a SOURCE file recording the pinned
# EX-CT/eve-dogma-bench commit it was taken from); override a snapshot with
# SUITE_GRAPHS / SUITE_CAP / SUITE_MUTATED / SUITE_FORMATS=/path.
set -euo pipefail
ENGINE=$(readlink -f "$1"); OUT=$(mkdir -p "$2" && cd "$2" && pwd); N=${3:-ci}
BENCH=$(cd "$(dirname "$0")/.." && pwd)
declare -A DIR
for s in graphs cap mutated formats; do
  var="SUITE_${s^^}"
  if [[ -n "${!var:-}" ]]; then DIR[$s]=$(readlink -f "${!var}"); continue; fi
  DIR[$s]=$BENCH/suites/$s
  [[ -d ${DIR[$s]} ]] || { echo "suites/$s missing (expected a flattened suite snapshot with a SOURCE file)"; exit 2; }
done
rc=0
step() { local name=$1; shift; echo "== $name"; "$@" > "$OUT/$name.log" 2>&1 || { echo "   (exit $? - see $OUT/$name.log; scored by check_no_regress)"; rc=1; }; }
cd "$BENCH"
step core     python3 run.py --name "$N" --cmd "$ENGINE calc" --batch-cmd "$ENGINE batch" --batch-repeat 1 --latency-n 5
rm -rf "$OUT/core"; cp -r "results/$N" "$OUT/core"; rm -rf "results/$N"
step ext      python3 ext/tools/score.py --batch-cmd "$ENGINE batch" --name "$N" --out "$OUT/ext.json"
step ext_rpc  python3 ext/tools/score_rpc.py --cmd "$ENGINE serve-stdio" --name "$N" --out "$OUT/ext_rpc.json"
step batch    python3 batch/run_batch.py --cmd "$ENGINE" --name "$N" --out "$OUT/batch.json"
step effects  python3 effects/tools/score.py --batch-cmd "$ENGINE batch" --name "$N" --out "$OUT/effects.json"
step sde      python3 d22/run_d22.py --suite sde --cmd "$ENGINE" --name "$N" --out "$OUT/sde.json"
step price_inject python3 d22/run_d22.py --suite price_inject --cmd "$ENGINE" --name "$N" --out "$OUT/price_inject.json"
if [[ -n "${PRICE_RULE_CMD:-}" ]]; then
  step price_rule python3 d22/run_d22.py --suite price_rule --rule-cmd "$PRICE_RULE_CMD" --name "$N" --out "$OUT/price_rule.json"
fi
cd "${DIR[graphs]}"
step graphs   python3 graphs/run_graphs.py --name "$N" --rpc-cmd "$ENGINE serve-stdio"
rm -rf "$OUT/graphs"; cp -r "results/graphs-$N" "$OUT/graphs"
cd "${DIR[cap]}"
step cap      python3 cap/run_cap.py --batch-cmd "$ENGINE batch" --name "$N"
cp "cap/results/$N.json" "$OUT/cap.json"
cd "${DIR[mutated]}"
step mutated  python3 mutated/run_mutated.py --name "$N" --cmd "$ENGINE calc" --batch-cmd "$ENGINE batch" --batch-repeat 1 --latency-n 5
rm -rf "$OUT/mutated"; cp -r "mutated/results/$N" "$OUT/mutated"
cd "${DIR[formats]}"
step formats  python3 tools/evaluate_formats.py --rpc "$ENGINE serve-stdio" --name "$N" --out "$OUT/formats"
python3 - "$OUT" "$BENCH" "${DIR[graphs]}" "${DIR[cap]}" "${DIR[mutated]}" "${DIR[formats]}" <<'PY'
import json, os, re, subprocess, sys
out, bench, gr, cap, mut, fmt = sys.argv[1:]
def ref(d):
    """Pinned-suite snapshots carry a SOURCE file (repo@sha); anything else resolves via git."""
    src = os.path.join(d, "SOURCE")
    if os.path.exists(src):
        m = re.search(r"@([0-9a-f]{40})", open(src).read())
        if m:
            return m.group(1)
    r = subprocess.run(["git", "-C", d, "rev-parse", "HEAD"], capture_output=True, text=True)
    return r.stdout.strip() if r.returncode == 0 else ""
roots = {"core": bench, "ext": bench, "ext_rpc": bench, "batch": bench, "effects": bench, "sde": bench, "price_inject": bench, "price_rule": bench, "graphs": gr, "cap": cap, "mutated": mut, "formats": fmt}
json.dump({"roots": roots, "refs": {k: ref(v) for k, v in roots.items()}}, open(f"{out}/roots.json", "w"), indent=1)
PY
echo "outputs in $OUT (suite runner exit codes ignored by design; the gate is check_no_regress.py)"
