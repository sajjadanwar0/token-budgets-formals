#!/usr/bin/env python3
"""
analyze_complementary.py — compute the four PRE-REGISTERED measures from the
completed two-coder screening sheet (see preregistration.md §4).

Input: screening_sheet_blinded.csv after both coders have filled
       coder_a_include / coder_b_include (yes|no) and, for included rows,
       coder_a_cluster / coder_b_cluster (one of the eight clusters + M-other).

Outputs (printed + written to complementary_results.txt):
  1. Inclusion IRR   — Cohen's kappa on include/exclude over ALL screened issues.
  2. Cluster IRR     — Cohen's kappa on cluster among JOINTLY-included issues.
  3. Recurrence      — fraction of repos with >=1 of the eight clusters.
  4. Saturation      — M-other count / included; decision rule fires at >=10%.
  +  Screen->include rate (coarse base-rate SIGNAL only, NOT prevalence).

Stdlib only. Mirrors compute_cluster_kappa.py's kappa.
"""
import argparse, csv, collections
from pathlib import Path

def kappa(pairs):
    n = len(pairs)
    if n == 0: return float("nan"), float("nan"), 0
    po = sum(1 for a, b in pairs if a == b) / n
    ca, cb = collections.Counter(a for a, b in pairs), collections.Counter(b for a, b in pairs)
    labels = set(ca) | set(cb)
    pe = sum((ca[l]/n)*(cb[l]/n) for l in labels)
    k = (po - pe) / (1 - pe) if pe != 1 else 0.0
    return k, po, n

def norm(s): return (s or "").strip().lower()

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--sheet", type=Path, default=Path("complementary/screening_sheet_blinded.csv"))
    ap.add_argument("--repos", type=int, help="N repos in the frame (for recurrence denominator)")
    ap.add_argument("--out", type=Path, default=Path("complementary/complementary_results.txt"))
    args = ap.parse_args()
    rows = list(csv.DictReader(args.sheet.open(encoding="utf-8-sig")))

    L = []
    # 1. inclusion kappa over ALL screened
    inc = [(norm(r["coder_a_include"]), norm(r["coder_b_include"])) for r in rows
           if norm(r["coder_a_include"]) and norm(r["coder_b_include"])]
    k_inc, po_inc, n_inc = kappa(inc)
    L.append(f"1. Inclusion IRR: kappa={k_inc:.3f} (obs={po_inc:.3f}) over N={n_inc} screened issues")

    # 2. cluster kappa among JOINTLY-included
    joint = [r for r in rows if norm(r["coder_a_include"]) == "yes" and norm(r["coder_b_include"]) == "yes"]
    cl = [(r["coder_a_cluster"].strip(), r["coder_b_cluster"].strip()) for r in joint
          if r["coder_a_cluster"].strip() and r["coder_b_cluster"].strip()]
    k_cl, po_cl, n_cl = kappa(cl)
    L.append(f"2. Cluster IRR: kappa={k_cl:.3f} (obs={po_cl:.3f}) over N={n_cl} jointly-included issues")

    # 3. recurrence: repos with >=1 of the eight canonical clusters (use coder A's labels on included)
    EIGHT = {"m-retry-loop","m-cost-observability","m-context-amplification","m-storage-amplification",
             "m-budget-primitive-missing","m-delegation-fanout","providerOptions-silently-dropped".lower(),
             "m-multimodal-cost-amplification"}
    repos_with = set()
    for r in joint:
        if norm(r["coder_a_cluster"]) in EIGHT:
            repos_with.add(r["repo"])
    all_repos = {r["repo"] for r in rows}
    denom = args.repos or len(all_repos)
    L.append(f"3. Recurrence: {len(repos_with)}/{denom} repos exhibit >=1 of the eight clusters "
             f"({100*len(repos_with)/denom:.0f}%)")

    # 4. saturation: M-other share of included
    n_incl = len(joint)
    n_other = sum(1 for r in joint if norm(r["coder_a_cluster"]) == "m-other")
    share = (100*n_other/n_incl) if n_incl else 0
    verdict = "TAXONOMY INCOMPLETE — report a candidate ninth cluster" if share >= 10 else "taxonomy adequate (no saturation signal)"
    L.append(f"4. Saturation: M-other = {n_other}/{n_incl} included ({share:.0f}%) -> {verdict}")
    if n_other:
        L.append("   M-other rows (propose the new mechanism for each):")
        for r in joint:
            if norm(r["coder_a_cluster"]) == "m-other":
                L.append(f"     {r['repo']}#{r['issue_number']}  {r['url']}")

    # + screen->include rate (signal only)
    n_screened = len(rows)
    n_included_either = sum(1 for r in rows if norm(r["coder_a_include"])=="yes" or norm(r["coder_b_include"])=="yes")
    L.append(f"+  Screen->include rate (SIGNAL ONLY, not prevalence): "
             f"{n_included_either}/{n_screened} = {100*n_included_either/max(n_screened,1):.0f}%")

    out = "Pre-registered complementary-sample results\n" + "="*44 + "\n" + "\n".join(L) + "\n"
    args.out.write_text(out, encoding="utf-8")
    print(out)

if __name__ == "__main__":
    main()