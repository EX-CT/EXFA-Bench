"""Extract Pyfa's renamed-item conversions (service/conversions/*.py, GPL-3.0-or-later) and merge them
into a presets-pyfa JSON as `conversions.items {old name: current name}`.

The engine reads this section in `pyfa_data_load` (names.resolve: renamed-item conversions before the
exact-name lookup). GPL tool: test/CI data generation only, never shipped to consumers.

usage: python make_conversions.py --pyfa /path/to/pyfa --presets presets-pyfa-LGPL-GPL.json [--out out.json]
"""
import argparse
import ast
import glob
import json
import os
import subprocess

GENERATOR = "EX-CT/EXFA-Bench oracle/make_conversions.py"


def read_conversions(pyfa_dir: str) -> dict:
    """Merge every CONVERSIONS dict under service/conversions/ (same 'all' semantics as Pyfa's __init__)."""
    conv = {}
    d = os.path.join(pyfa_dir, "service", "conversions")
    for path in sorted(glob.glob(os.path.join(d, "*.py"))):
        if os.path.basename(path) == "__init__.py":
            continue
        tree = ast.parse(open(path, encoding="utf-8").read(), filename=path)
        for node in ast.walk(tree):
            if isinstance(node, ast.Assign) and getattr(node.targets[0], "id", "") == "CONVERSIONS":
                conv.update(ast.literal_eval(node.value))
    return conv


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--pyfa", required=True, help="path to a Pyfa source checkout")
    ap.add_argument("--presets", required=True, help="presets-pyfa JSON to update (read + write unless --out)")
    ap.add_argument("--out", default=None)
    a = ap.parse_args()

    conv = read_conversions(a.pyfa)
    try:
        ref = subprocess.check_output(["git", "-C", a.pyfa, "rev-parse", "HEAD"], text=True).strip()
    except Exception:
        ref = "unknown"
    doc = json.load(open(a.presets, encoding="utf-8"))
    doc.setdefault("conversions", {})["items"] = conv
    doc["conversions"]["provenance"] = {"method": "ast-extract service/conversions/*.py CONVERSIONS dicts, merged in file order (Pyfa 'all' semantics)", "pyfa_ref": ref, "license": "GPL-3.0-or-later", "generator": GENERATOR}
    doc["generator"] = f"{doc.get('generator', '?')} + {GENERATOR}"
    out = a.out or a.presets
    with open(out, "w", encoding="utf-8") as fh:
        json.dump(doc, fh, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
        fh.write("\n")
    print(f"{len(conv)} conversions -> {out}")


if __name__ == "__main__":
    main()
