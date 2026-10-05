# oracle/ — Pyfa reference tooling (GPL-3.0-or-later)

Everything in this directory imports, reads, or is generated from **Pyfa** (pyfa / eos), so it is distributed
under **GPL-3.0-or-later** (see `LICENSE` in this directory; `LICENSE.GPL-3.0` is the same text). The rest of the
EXFA-Bench repository is LGPL-3.0-or-later. These are test-time tools only: they are never compiled into or linked
with the EXFA-Engine (`exfa-core`) library or any consumer.

Other repositories consume only the **outputs** of these tools — the committed expectation data
(`expected/`, `effects/expected/`, `ext/expected/`, `oracle/fuzz/expected_diffs.json`, `data/pyfa-data-drift.json`,
`reports/`) — which are facts measured from Pyfa's behaviour, not Pyfa code.

| Path | Content |
|---|---|
| `pyfa_oracle.py` | runs Pyfa's eos engine headless as a black box; produces `expected/` values |
| `state_oracle.py`, `pyfa_lookup.py`, `pyfa_eft_export.py` | state / lookup / EFT-export oracles for the pending + ext/rpc suites |
| `fuzz/` | differential fuzz tools (`compare.py`, `drift.py`, `gen_legal.py`, …) + the data-drift allowlist `expected_diffs.json` |
| `tools/pyfa_effects.py` | effect-handler inventory vs SDE modifierInfo → `reports/pyfa-effects-coverage.md` |
| `tools/pyfa_drift.py` | Pyfa `eve.db` vs dataset attribute/effect drift → `data/pyfa-data-drift.json` |
| `tools/engine-effect-names.json` | committed snapshot of the engine's hand-written effect names |
| `data/pyfa-data-drift.{json,md}` | known Pyfa-vs-SDE data differences (canonical; migrated from EX-CT/eve-sde-pipeline `docs/` @ 83ba879) |
| `reports/pyfa-effects-coverage.md` | generated coverage report (from EX-CT/eve-sde-pipeline `reports/` @ 83ba879) |
| `tests/test_pyfa_drift.py` | drift-file schema check + drift-vs-dataset check (needs a dataset; `EXFA_DATASET` or `EXFA_DATASET_DIR`) |
