#!/usr/bin/env python3
"""
After rater B returns coding_sheet_for_rater_b.csv with the rater_b_tag
column filled in, run this script to:
  1. Merge rater B's tags back with rater A's master file
  2. Run irr_scaffold.py compute to get Cohen's kappa + 95% CI
  3. Run irr_scaffold.py disagreements to get the items to adjudicate

Usage:
    python3 merge_and_compute.py path/to/rater_b_completed.csv
"""
import csv
import subprocess
import sys
from pathlib import Path

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 merge_and_compute.py rater_b_completed.csv")
        sys.exit(1)

    rater_b_file = Path(sys.argv[1])
    master_file = Path("_master_with_rater_a.csv")

    if not rater_b_file.exists():
        print(f"ERROR: {rater_b_file} not found")
        sys.exit(1)
    if not master_file.exists():
        print(f"ERROR: {master_file} not found (should be in IRR package)")
        sys.exit(1)

    # Load both
    with rater_b_file.open() as f:
        rater_b_rows = {r["issue_id"]: r["rater_b_tag"].strip() for r in csv.DictReader(f)}
    with master_file.open() as f:
        master = list(csv.DictReader(f))

    # Merge
    for r in master:
        r["rater_b_tag"] = rater_b_rows.get(r["issue_id"], "")

    out_file = Path("coding_sheet_completed.csv")
    fieldnames = ["issue_id", "framework", "date", "short_url", "title",
                  "notes_redacted", "rater_a_tag", "rater_b_tag"]
    with out_file.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fieldnames)
        w.writeheader()
        for r in master:
            w.writerow({k: r.get(k, "") for k in fieldnames})

    n_filled = sum(1 for r in master if r["rater_b_tag"])
    print(f"Merged: {n_filled}/{len(master)} rows have rater_b_tag")
    print(f"Wrote {out_file}")
    print()
    print("Now running irr_scaffold.py compute...")
    print("=" * 60)
    subprocess.run(["python3", "irr_scaffold.py", "compute",
                    "--input", str(out_file)], check=False)
    print()
    print("=" * 60)
    print("Disagreements (for adjudication):")
    print("=" * 60)
    subprocess.run(["python3", "irr_scaffold.py", "disagreements",
                    "--input", str(out_file)], check=False)

if __name__ == "__main__":
    main()
