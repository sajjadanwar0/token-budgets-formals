#!/usr/bin/env python3
"""
compute_cluster_kappa.py  --  STEP 3 of the cluster-IRR pipeline.

Computes, for the 8-cluster mechanism taxonomy:
  - overall multiclass Cohen's kappa (rater A vs rater B),
  - per-cluster one-vs-rest kappa,
  - observed agreement,
  - a full confusion matrix (shows WHICH boundaries are soft).

Stdlib only (no sklearn), mirroring compute_v1_1_kappa.py.

Usage:
  python3 compute_cluster_kappa.py \
      --hidden hidden_cluster_labels.csv \
      --rater-b returned_cluster_sheet.csv \
      --report cluster_kappa_report.txt
"""
import argparse, csv
from collections import Counter, defaultdict
from pathlib import Path


def cohen_kappa(a, b):
    """Multiclass Cohen's kappa from paired label lists a, b."""
    n = len(a)
    labels = sorted(set(a) | set(b))
    po = sum(1 for x, y in zip(a, b) if x == y) / n
    ca, cb = Counter(a), Counter(b)
    pe = sum((ca[l] / n) * (cb[l] / n) for l in labels)
    kappa = (po - pe) / (1 - pe) if pe != 1 else 0.0
    return kappa, po, pe


def one_vs_rest(a, b, label):
    aa = [1 if x == label else 0 for x in a]
    bb = [1 if x == label else 0 for x in b]
    return cohen_kappa(aa, bb)


def _reader(path: Path):
    """DictReader that tolerates stray comment lines / BOM."""
    lines = [ln for ln in path.read_text(encoding="utf-8-sig").splitlines()
             if not ln.lstrip().startswith("#")]
    return csv.DictReader(lines)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--hidden", required=True, type=Path)
    ap.add_argument("--rater-b", required=True, type=Path)
    ap.add_argument("--report", required=True, type=Path)
    args = ap.parse_args()

    ha = {r["issue_id"]: r["rater_a_cluster"].strip()
          for r in _reader(args.hidden)}
    hb = {r["issue_id"]: r["primary_cluster"].strip()
          for r in _reader(args.rater_b)
          if r.get("primary_cluster", "").strip()}

    ids = sorted(set(ha) & set(hb))
    missing = sorted(set(ha) - set(hb))
    a = [ha[i] for i in ids]
    b = [hb[i] for i in ids]

    kappa, po, pe = cohen_kappa(a, b)
    labels = sorted(set(a) | set(b))

    lines = []
    lines.append("Cluster-taxonomy IRR — RESULT REPORT")
    lines.append("=" * 44)
    lines.append(f"N paired rows scored: {len(ids)}")
    if missing:
        lines.append(f"WARNING: {len(missing)} rows in rater-A not coded by "
                     f"rater-B (excluded): {', '.join(missing)}")
    lines.append("")
    lines.append(f"Overall multiclass Cohen's kappa: {kappa:.4f}")
    lines.append(f"Observed agreement: {po:.4f}   Expected (chance): {pe:.4f}")
    lk = ("almost_perfect" if kappa > .8 else "substantial" if kappa > .6
    else "moderate" if kappa > .4 else "fair" if kappa > .2 else "slight/none")
    lines.append(f"Landis-Koch band: {lk}")
    lines.append("")
    lines.append("Per-cluster one-vs-rest kappa:")
    for l in labels:
        k, _, _ = one_vs_rest(a, b, l)
        na, nb = a.count(l), b.count(l)
        lines.append(f"  {l:<34} kappa={k:6.3f}  (A n={na}, B n={nb})")
    lines.append("")
    lines.append("Confusion matrix (rows = rater A, cols = rater B):")
    cm = defaultdict(lambda: defaultdict(int))
    for x, y in zip(a, b):
        cm[x][y] += 1
    short = {l: l.replace("M-", "")[:10] for l in labels}
    header = "A\\B".ljust(14) + "".join(short[l].ljust(12) for l in labels)
    lines.append(header)
    for x in labels:
        row = short[x].ljust(14) + "".join(str(cm[x][y]).ljust(12) for y in labels)
        lines.append(row)
    lines.append("")
    lines.append("INTERPRETATION GUIDANCE: report whatever kappa results. For a")
    lines.append("mechanism taxonomy with soft boundaries, moderate-to-substantial")
    lines.append("(0.4-0.7) is normal and defensible WHEN reported with this")
    lines.append("confusion matrix and a note on the confused pairs. Do NOT re-code")
    lines.append("to inflate. A high M-other count signals taxonomy incompleteness.")

    report = "\n".join(lines) + "\n"
    args.report.write_text(report, encoding="utf-8")
    print(report)


if __name__ == "__main__":
    main()