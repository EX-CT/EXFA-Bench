# EXFA-Bench — EXFA · 精密装配助理 契约测试与 Pyfa 对照

Shared contract test & benchmark suites for the EXFA fitting engine (EX-CT). Any engine implementing the
FitRequest → FitStats contract (see [CONTRACT.md](CONTRACT.md), owned by
[EX-CT/EXFA-Engine](https://github.com/EX-CT/EXFA-Engine/tree/main/contract)) can be scored on **correctness against
the Pyfa oracle** (per stat, with tolerance), **speed** and **determinism**.

```
cases/       core corpus: 339 FitRequest JSON files (fully resolved type ids, no EFT needed)
expected/    expected values per case, produced by the Pyfa oracle (+ known_divergences.json)
expected_extra/ informational checks outside accuracy scoring (eft_export.jsonl: Pyfa exportEft texts)
run.py       the core runner / scorer -> results/<name>/scorecard.{json,md} + failures.json
effects/     per-effect suite: 2 378 Pyfa micro-fits, full attribute dump (effects/README.md)
ext/         stats-ext / heat / fleet.buffs / overrides suite, incl. rpc + unit cases (ext/README.md)
batch/       batch API + price-layer suite (batch/README.md, docs/23)
d22/         SDE version/provenance + price_inject suites; price_rule tests the updater, not the engine
pending/     draft cases not yet merged into the corpus (state/, exct/)
inventory/   suites.yaml + tests.yaml for tools/check_inventory.py (docs/19 item -> tests gate)
oracle/      Pyfa oracle + migrated Pyfa data tools — GPL-3.0-or-later, see oracle/README.md
suites/      flattened snapshots of the pinned suite trees (each has a SOURCE file naming its
             EX-CT/eve-dogma-bench commit): graphs/ (graphs-v0.3), cap/, mutated/, formats/, round1/
baselines/   no-regression baselines: exfa-engine.json (engine), web.json (eve-fit-web browser engine)
tools/       run_all_suites.sh, check_no_regress.py (the gate), round1_sha.sh, metrics.py,
             make_expected.py, check_inventory.py, ci_gate.py, ci_graph_corpus.py, ci_invariants.py,
             check_eft_export.py, check_module_state.py, apply_na.py, mcp_batch.py (eve-fit-mcp adapter)
```

## Running all suites on an engine

```bash
# engine: the exfa binary (calc / batch / serve-stdio); the dataset is compiled in
export EXFA_DATASET=/path/dataset-3569502-r5.json.gz   # batch/price_inject reference resolver needs it
tools/run_all_suites.sh /path/to/exfa out ci
python3 tools/check_no_regress.py --baseline baselines/exfa-engine.json --run-dir out
```

`run_all_suites.sh` writes one result file/dir per suite plus `roots.json` (which suite tree each ran from).
Suite scores are compared against `baselines/exfa-engine.json` by `check_no_regress.py` — the baseline can only go
up (`baselines/README.md` for the rules; `SDE_PACK=/path/*.edp` enables the pending d22 pack cases,
`PRICE_RULE_CMD=` runs the price-updater suite). The graphs, cap, mutated and formats snapshots under `suites/`
can be overridden with `SUITE_GRAPHS` / `SUITE_CAP` / `SUITE_MUTATED` / `SUITE_FORMATS`.

## Round-1 byte-identity hash

```bash
tools/round1_sha.sh /path/to/exfa    # -> sha256 of the frozen 1.8.0 corpus batch output
```

Compacts `suites/round1/cases/*.json` into JSONL and runs one `ENGINE batch`, exactly like the engine's
`ci/run_suites.sh` `ci/round1.sha256` check (currently `2667a6fb…`).

## Dataset

All suites target SDE build **3569502**: `dataset-3569502-r5.json.gz`, a release asset of
[EX-CT/eve-sde-pipeline](https://github.com/EX-CT/eve-sde-pipeline/releases/tag/sde-3569502-r5).

```bash
gh release download sde-3569502-r5 -R EX-CT/eve-sde-pipeline --pattern 'dataset-*.json.gz' -D data/
```

Expected values come from Pyfa (eos, Pyfa client data build 3532181) via `oracle/pyfa_oracle.py`;
`expected/known_divergences.json` lists metrics excluded because Pyfa's data is older than the SDE or because Pyfa
disagrees with CCP's own modifiers. Known Pyfa-vs-SDE data drift: `oracle/data/pyfa-data-drift.{json,md}`.

## Provenance

Migrated from [EX-CT/eve-dogma-bench](https://github.com/EX-CT/eve-dogma-bench) `pending-1.11` @ `01e6724`
(bench 1.10.0 + pending 1.11 suites). This is a fresh repository — no git history. The `suites/` snapshots are
verbatim `git archive`s of the pinned bench commits recorded in each `suites/<name>/SOURCE` (graphs `db81b8c` /
tag graphs-v0.3, cap `d80cc38`, mutated `4533dde`, formats `7c716e7`, round1 `3da9671` = the frozen 1.8.0 corpus).
The A–K variant-scoring harness of the old repo (`bench.py`, `variants.yaml`, `tools/evaluate.py`, `results*/`)
and the shelved `optimizer/` WIP are not part of this repo. Historical scores and release notes remain in
CHANGELOG.md.

## License

Suites, runners, tools and case data: **LGPL-3.0-or-later** (`LICENSE`). `oracle/` is **GPL-3.0-or-later**
(`oracle/LICENSE`): it imports and reads Pyfa. Other repositories only consume its committed expectation data.
EVE Online data © CCP hf.
