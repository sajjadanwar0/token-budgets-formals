from __future__ import annotations
import argparse
import csv
import json
import random
import re
import sys
from collections import Counter, defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional, Tuple

CATALOG_PATH = Path("catalogue.csv")
DEFAULT_SAMPLE_SIZE = 109
TAG_CLASSES = ["bf", "bu", "fr", "mf"]
TAG_LONG = {
    "bf": "bug_fixed_by_framework",
    "bu": "bug_unfixed",
    "fr": "feature_request",
    "mf": "maintainer_framing",
}

@dataclass
class CatalogRow:
    issue_id: str
    framework: str
    date: str
    short_url: str
    title: str
    notes: str
    tag: Optional[str]


def extract_tag(notes: str) -> Optional[str]:
    if notes.startswith("SKIPPED"):
        return None
    m = re.match(r"^paper:(bf|bu|fr|mf)\b", notes)
    if m:
        return m.group(1)
    return None


def load_catalog(path: Path) -> List[CatalogRow]:
    rows: List[CatalogRow] = []
    with path.open() as f:
        for r in csv.DictReader(f):
            tag = extract_tag(r.get("notes", ""))
            rows.append(CatalogRow(
                issue_id=r.get("issue_id", ""),
                framework=r.get("framework", ""),
                date=r.get("date", ""),
                short_url=r.get("short_url", ""),
                title=r.get("title", ""),
                notes=r.get("notes", ""),
                tag=tag,
            ))
    return rows


def stratified_sample(
    rows: List[CatalogRow],
    n: int,
    seed: int = 42,
) -> List[CatalogRow]:
    retained = [r for r in rows if r.tag is not None]
    if n > len(retained):
        raise ValueError(f"sample size {n} exceeds retained catalog ({len(retained)})")

    by_class: Dict[str, List[CatalogRow]] = defaultdict(list)
    for r in retained:
        by_class[r.tag].append(r)

    total = len(retained)
    rng = random.Random(seed)
    sample: List[CatalogRow] = []
    fractional_remainders: List[Tuple[float, str]] = []
    used_per_class: Dict[str, int] = {}

    for cls in TAG_CLASSES:
        class_rows = by_class.get(cls, [])
        proportional = (len(class_rows) / total) * n
        whole = int(proportional)
        used_per_class[cls] = whole
        if whole > 0:
            sample.extend(rng.sample(class_rows, whole))
        fractional_remainders.append((proportional - whole, cls))

    fractional_remainders.sort(reverse=True)

    while len(sample) < n:
        for _, cls in fractional_remainders:
            if len(sample) >= n:
                break
            class_rows = by_class.get(cls, [])
            existing = {r.issue_id for r in sample if r.tag == cls}
            remaining = [r for r in class_rows if r.issue_id not in existing]
            if remaining:
                pick = rng.choice(remaining)
                sample.append(pick)
                used_per_class[cls] = used_per_class.get(cls, 0) + 1
        if all(used_per_class.get(c, 0) >= len(by_class.get(c, [])) for c in TAG_CLASSES):
            break

    return sample


def write_coding_sheet(sample: List[CatalogRow], output: Path, blind: bool = False) -> None:
    with output.open("w", newline="") as f:
        w = csv.writer(f)
        w.writerow([
            "issue_id", "framework", "date", "short_url", "title",
            "notes_redacted", "rater_a_tag", "rater_b_tag",
        ])
        for r in sample:
            if blind:
                redacted = ""
            else:
                redacted = re.sub(
                    r"^paper:(bf|bu|fr|mf)\b[;.,\s]*",
                    "",
                    r.notes,
                )
            w.writerow([
                r.issue_id, r.framework, r.date, r.short_url, r.title,
                redacted, r.tag, "",
            ])

def cohen_kappa(
    rater_a: List[str],
    rater_b: List[str],
    classes: List[str],
) -> Tuple[float, Dict[str, float]]:
    n = len(rater_a)
    assert n == len(rater_b)

    observed_agree = sum(1 for a, b in zip(rater_a, rater_b) if a == b)
    p_o = observed_agree / n
    a_count = Counter(rater_a)
    b_count = Counter(rater_b)
    p_e = sum(
        (a_count[c] / n) * (b_count[c] / n)
        for c in classes
    )

    if p_e == 1.0:
        # All raters always agree on one class; kappa undefined
        kappa = 1.0 if p_o == 1.0 else 0.0
    else:
        kappa = (p_o - p_e) / (1 - p_e)

    # Per-class agreement (sensitivity for each tag)
    per_class: Dict[str, float] = {}
    for c in classes:
        a_n = sum(1 for a in rater_a if a == c)
        agree_in_c = sum(
            1 for a, b in zip(rater_a, rater_b) if a == c and b == c
        )
        per_class[c] = agree_in_c / a_n if a_n > 0 else float("nan")

    return kappa, per_class


def bootstrap_kappa_ci(
    rater_a: List[str],
    rater_b: List[str],
    classes: List[str],
    n_bootstrap: int = 2000,
    seed: int = 42,
) -> Tuple[float, float]:
    """Bootstrap a 95% CI on Cohen's kappa."""
    rng = random.Random(seed)
    n = len(rater_a)
    boots: List[float] = []
    for _ in range(n_bootstrap):
        idx = [rng.randrange(n) for _ in range(n)]
        a_boot = [rater_a[i] for i in idx]
        b_boot = [rater_b[i] for i in idx]
        try:
            k, _ = cohen_kappa(a_boot, b_boot, classes)
            boots.append(k)
        except Exception:
            continue
    boots.sort()
    if len(boots) < 100:
        return float("nan"), float("nan")
    lo = boots[int(0.025 * len(boots))]
    hi = boots[int(0.975 * len(boots))]
    return lo, hi


def cmd_sample(args: argparse.Namespace) -> int:
    rows = load_catalog(args.catalog)
    sample = stratified_sample(rows, args.n, seed=args.seed)
    write_coding_sheet(sample, args.output, blind=args.blind)

    # Distribution check
    seen = Counter(r.tag for r in sample)
    print(f"Stratified sample of N={args.n} rows written to {args.output}")
    if args.blind:
        print(f"Mode: BLIND (notes_redacted column is empty; rater B reads "
              f"GitHub URL directly)")
    else:
        print(f"Mode: standard (leading paper: tag stripped, evidence preserved)")
    print(f"Distribution by tag (rater A original):")
    for tag in TAG_CLASSES:
        n = seen.get(tag, 0)
        print(f"  {TAG_LONG[tag]:<24}: {n}")
    print()
    print(f"Instructions for rater B:")
    print(f"  1. Open {args.output} (do NOT look at the rater_a_tag column)")
    if args.blind:
        print(f"  2. For each row, visit short_url in a browser and read the "
              f"full GitHub")
        print(f"     issue (~3 min/row, ~90 min total for N=30)")
    else:
        print(f"  2. For each row, read notes_redacted and the GitHub URL "
              f"(short_url)")
        print(f"     Note: notes_redacted contains rater A's evidence summary "
              f"with the")
        print(f"     tag stripped; this gives shared context but means "
              f"agreement is partly")
        print(f"     primed by rater A's framing. For stricter IRR use --blind.")
    print(f"  3. Code the row with one of: bf, bu, fr, mf")
    print(f"     bf = bug_fixed_by_framework")
    print(f"     bu = bug_unfixed (declined or never addressed)")
    print(f"     fr = feature_request (asking for the missing mechanism)")
    print(f"     mf = maintainer_framing (project maintainer characterizing")
    print(f"          the broader pattern)")
    print(f"  4. Fill in the rater_b_tag column. Save as a new file.")
    print(f"  5. Hand the completed file back; run `irr_scaffold.py compute`.")
    return 0


def cmd_compute(args: argparse.Namespace) -> int:
    rows: List[Dict[str, str]] = []
    with args.input.open() as f:
        for r in csv.DictReader(f):
            rows.append(r)

    a_tags = [r["rater_a_tag"].strip() for r in rows]
    b_tags = [r["rater_b_tag"].strip() for r in rows]

    blanks = sum(1 for b in b_tags if not b)
    if blanks > 0:
        sys.stderr.write(f"WARNING: {blanks} rows have an empty rater_b_tag\n")

    # Drop rows where either is blank or invalid
    paired: List[Tuple[str, str]] = []
    for a, b in zip(a_tags, b_tags):
        if a in TAG_CLASSES and b in TAG_CLASSES:
            paired.append((a, b))

    if not paired:
        sys.stderr.write("ERROR: no valid coded pairs in input\n")
        return 1

    a, b = zip(*paired)
    kappa, per_class = cohen_kappa(list(a), list(b), TAG_CLASSES)
    ci_lo, ci_hi = bootstrap_kappa_ci(list(a), list(b), TAG_CLASSES)

    n = len(paired)
    p_o = sum(1 for ai, bi in zip(a, b) if ai == bi) / n

    if args.json:
        print(json.dumps({
            "n_pairs": n,
            "observed_agreement": p_o,
            "cohen_kappa": kappa,
            "kappa_ci_95": [ci_lo, ci_hi],
            "per_class_agreement": per_class,
        }, indent=2))
        return 0

    print(f"Inter-rater reliability summary")
    print(f"=" * 60)
    print(f"Pairs analyzed:          {n}")
    print(f"Observed agreement:      {p_o:.3f}")
    print(f"Cohen's kappa:           {kappa:.3f}")
    print(f"  Bootstrap 95% CI:      [{ci_lo:.3f}, {ci_hi:.3f}]")
    print()

    # Landis & Koch (1977) interpretation, with the standard caveats:
    if kappa < 0:
        interp = "less than chance agreement"
    elif kappa < 0.20:
        interp = "slight"
    elif kappa < 0.40:
        interp = "fair"
    elif kappa < 0.60:
        interp = "moderate"
    elif kappa < 0.80:
        interp = "substantial"
    else:
        interp = "almost perfect"
    print(f"Landis-Koch interpretation: {interp}")
    print(f"  (commonly criticised as overly generous; report kappa value")
    print(f"   directly rather than relying on the descriptive label)")
    print()

    print(f"Per-class agreement rate (rater A's coding as reference):")
    for tag in TAG_CLASSES:
        rate = per_class.get(tag, float("nan"))
        print(f"  {TAG_LONG[tag]:<24}: {rate:.3f}")

    return 0


def cmd_disagreements(args: argparse.Namespace) -> int:
    rows: List[Dict[str, str]] = []
    with args.input.open() as f:
        for r in csv.DictReader(f):
            rows.append(r)

    disagreements = [
        r for r in rows
        if r["rater_a_tag"].strip() != r["rater_b_tag"].strip()
        and r["rater_b_tag"].strip()
    ]

    print(f"Found {len(disagreements)} disagreements out of {len(rows)} rows.")
    print()
    for r in disagreements:
        print(f"--- {r['issue_id']} ({r['framework']}, {r['date']}) ---")
        print(f"  URL: {r['short_url']}")
        print(f"  Title: {r['title']}")
        print(f"  Rater A: {r['rater_a_tag']}    Rater B: {r['rater_b_tag']}")
        print(f"  Evidence:")
        for line in r['notes_redacted'].split('\n'):
            print(f"    {line}")
        print()
    return 0


def main() -> int:
    p = argparse.ArgumentParser(
        description="Inter-rater reliability scaffold for the failure catalog."
    )
    sub = p.add_subparsers(dest="cmd", required=True)

    p_sample = sub.add_parser("sample", help="Generate a stratified random "
                              "sample for second-rater coding")
    p_sample.add_argument("--n", type=int, default=DEFAULT_SAMPLE_SIZE,
                          help=f"Sample size (default {DEFAULT_SAMPLE_SIZE})")
    p_sample.add_argument("--seed", type=int, default=42,
                          help="Random seed for reproducibility")
    p_sample.add_argument("--catalog", type=Path, default=CATALOG_PATH,
                          help=f"Path to catalogue.csv "
                               f"(default {CATALOG_PATH})")
    p_sample.add_argument("--output", type=Path, default=Path("coding_sheet.csv"),
                          help="Output path for the coding sheet")
    p_sample.add_argument("--blind", action="store_true",
                          help="Strip notes_redacted entirely; rater B "
                               "reads GitHub URLs directly. Stronger IRR "
                               "but takes ~3 min/row.")
    p_sample.set_defaults(func=cmd_sample)

    p_compute = sub.add_parser("compute", help="Compute kappa from a "
                               "completed coding sheet")
    p_compute.add_argument("--input", type=Path, required=True,
                           help="Coding sheet with both rater columns filled")
    p_compute.add_argument("--json", action="store_true",
                           help="Emit JSON summary")
    p_compute.set_defaults(func=cmd_compute)

    p_dis = sub.add_parser("disagreements", help="List rows where the "
                           "two raters disagreed")
    p_dis.add_argument("--input", type=Path, required=True)
    p_dis.set_defaults(func=cmd_disagreements)

    args = p.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
