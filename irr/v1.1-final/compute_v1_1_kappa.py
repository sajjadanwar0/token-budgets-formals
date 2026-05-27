#!/usr/bin/env python3
import argparse
import csv
import hashlib
import sys
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

def cohens_kappa(rater_a: list, rater_b: list) -> float:
    assert len(rater_a) == len(rater_b), "rater lists must be same length"
    n = len(rater_a)
    if n == 0:
        return float("nan")

    p_o = sum(1 for a, b in zip(rater_a, rater_b) if a == b) / n

    labels = set(rater_a) | set(rater_b)
    p_e = 0.0
    for label in labels:
        p_a = rater_a.count(label) / n
        p_b = rater_b.count(label) / n
        p_e += p_a * p_b

    if p_e == 1.0:
        return 1.0 if p_o == 1.0 else float("nan")
    return (p_o - p_e) / (1.0 - p_e)


def one_vs_rest_kappa(rater_a: list, rater_b: list, target_label: str) -> tuple:
    binary_a = [1 if x == target_label else 0 for x in rater_a]
    binary_b = [1 if x == target_label else 0 for x in rater_b]
    kappa = cohens_kappa(binary_a, binary_b)
    n_positive = sum(1 for a, b in zip(binary_a, binary_b) if a == 1 or b == 1)
    return kappa, n_positive


def sha256_of(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--rater-b-sheet", required=True, type=Path,
                    help="Returned coding sheet with v1_1_label filled in")
    ap.add_argument("--hidden-labels", required=True, type=Path,
                    help="v1.0 labels file produced by generate_blinded_sheet.py")
    ap.add_argument("--report", required=True, type=Path,
                    help="Output report path")
    args = ap.parse_args()

    with args.rater_b_sheet.open(newline="", encoding="utf-8") as f:
        rater_b_rows = list(csv.DictReader(f))

    with args.hidden_labels.open(newline="", encoding="utf-8") as f:
        v1_0_map = {r["id"]: r["v1_0_label"] for r in csv.DictReader(f)}

    missing = [r["id"] for r in rater_b_rows if not r.get("v1_1_label", "").strip()]
    if missing:
        print(f"ERROR: {len(missing)} rows missing v1_1_label: {missing[:5]}",
              file=sys.stderr)
        sys.exit(1)

    unmatched = [r["id"] for r in rater_b_rows if r["id"] not in v1_0_map]
    if unmatched:
        print(f"ERROR: {len(unmatched)} ids in rater B sheet have no v1.0 entry: "
              f"{unmatched[:5]}", file=sys.stderr)
        sys.exit(2)

    rater_a = []
    rater_b = []
    rows_changed = []

    for row in rater_b_rows:
        rid = row["id"]
        v1_0 = v1_0_map[rid].strip().lower()
        v1_1 = row["v1_1_label"].strip().lower()

        if v1_1 not in {"bf", "bu", "mf", "fr"}:
            print(f"ERROR: row {rid} has invalid v1_1_label '{v1_1}' "
                  f"(must be one of bf/bu/mf/fr)", file=sys.stderr)
            sys.exit(3)

        rater_a.append(v1_0)
        rater_b.append(v1_1)
        if v1_0 != v1_1:
            rows_changed.append({"id": rid, "v1_0": v1_0, "v1_1": v1_1,
                                 "rationale": row.get("v1_1_rationale", "")})

    kappa_fr, n_fr_pairs = one_vs_rest_kappa(rater_a, rater_b, "fr")
    kappa_overall_22 = cohens_kappa(rater_a, rater_b)

    label_counts_v1_0 = Counter(rater_a)
    label_counts_v1_1 = Counter(rater_b)

    if kappa_fr >= 0.85:
        decision = "(i) RULE CONFIRMED"
        action = ("v1.1 rule confirmed. No catalogue change. "
                  "Paper headline κ_fr updates to v1.1 figure; "
                  "v1.0 baseline retained in irr-package/v1.0/.")
    elif kappa_fr >= 0.75:
        decision = "(ii) RULE CONFIRMED WITH NOTE"
        action = (f"v1.1 rule confirmed. Add paper-text note quantifying "
                  f"{len(rows_changed)} reclassified rows. "
                  f"Paper headline κ_fr updates to v1.1 figure.")
    else:
        decision = "(iii) SUBSTANTIVE REVISION REQUIRED"
        action = ("v1.1 rule did NOT close the seam. Substantive paper-text "
                  "revision required: identify which fr cases remain "
                  "disputed and why; update §5.27.0.1 and §8.3 accordingly.")

    ts = datetime.now(timezone.utc).isoformat()
    rater_b_hash = sha256_of(args.rater_b_sheet)
    hidden_hash = sha256_of(args.hidden_labels)

    lines = [
        "M6 IRR re-annotation under Codebook v1.1 — RESULT REPORT",
        "=" * 60,
        "",
        f"Generated: {ts}",
        f"Script: compute_v1_1_kappa.py",
        "",
        "INPUTS",
        f"  Rater B returned sheet: {args.rater_b_sheet}",
        f"    SHA-256: {rater_b_hash}",
        f"  Hidden v1.0 labels:     {args.hidden_labels}",
        f"    SHA-256: {hidden_hash}",
        "",
        "SAMPLE",
        f"  N pairs: {len(rater_a)}",
        f"  v1.0 label distribution: {dict(label_counts_v1_0)}",
        f"  v1.1 label distribution: {dict(label_counts_v1_1)}",
        "",
        "RESULTS",
        f"  κ_fr_v1.1 (one-vs-rest on `fr`): {kappa_fr:.4f}",
        f"    (n positive pairs: {n_fr_pairs})",
        f"  κ_overall on the 22 cases:        {kappa_overall_22:.4f}",
        f"  Rows changed (v1.0 fr → v1.1 other): {len(rows_changed)}",
        "",
        "PRE-COMMITTED DECISION (from paper §8.3, M6):",
        f"  κ_fr_v1.1 >= 0.85         → (i) RULE CONFIRMED",
        f"  0.75 <= κ_fr_v1.1 < 0.85  → (ii) RULE CONFIRMED WITH NOTE",
        f"  κ_fr_v1.1 < 0.75          → (iii) SUBSTANTIVE REVISION REQUIRED",
        "",
        f"OUTCOME: {decision}",
        "",
        "ACTION:",
        f"  {action}",
        "",
        "RECLASSIFIED ROWS (v1.0 fr → v1.1 other):",
    ]
    if rows_changed:
        for r in rows_changed:
            lines.append(f"  {r['id']}: v1.0={r['v1_0']} → v1.1={r['v1_1']}")
            if r.get("rationale"):
                lines.append(f"    rationale: {r['rationale']}")
    else:
        lines.append("  (none — all 22 v1.0 fr cases also tagged fr under v1.1)")
    lines.append("")
    lines.append("REPRODUCIBILITY:")
    lines.append("  Anyone with the rater B sheet and the hidden labels file")
    lines.append("  can re-run this script and verify the kappa values and")
    lines.append("  decision string match. The decision rule is mechanical;")
    lines.append("  no author judgement enters.")
    lines.append("")
    lines.append("Commit this report to irr-package/v1.1/kappa_v1_1_report.txt")

    report_text = "\n".join(lines) + "\n"
    args.report.write_text(report_text)

    print(report_text)
    print(f"Wrote report to {args.report}")

    if decision.startswith("(i)"):
        sys.exit(0)
    elif decision.startswith("(ii)"):
        sys.exit(0)
    else:
        sys.exit(10)

if __name__ == "__main__":
    main()
