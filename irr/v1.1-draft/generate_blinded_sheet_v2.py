#!/usr/bin/env python3

import argparse
import csv
import hashlib
import re
import sys
from datetime import datetime, timezone
from pathlib import Path


LABEL_PATTERN = re.compile(r'paper:(\w+)', re.IGNORECASE)
LABEL_STRIP_PATTERN = re.compile(r'paper:\w+\s*;?\s*', re.IGNORECASE)

def sha256_of(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()


def extract_label(notes: str) -> str:
    if not notes:
        return ""
    match = LABEL_PATTERN.search(notes)
    return match.group(1).lower() if match else ""


def strip_label(notes: str) -> str:
    if not notes:
        return ""
    cleaned = LABEL_STRIP_PATTERN.sub('', notes)
    cleaned = cleaned.lstrip(' ;\n\t')
    return cleaned.strip()


def extract_year(date_str: str) -> str:
    if not date_str:
        return ""
    return date_str[:4] if len(date_str) >= 4 else date_str


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--input", required=True, type=Path)
    ap.add_argument("--output", required=True, type=Path)
    ap.add_argument("--hidden-labels", required=True, type=Path)
    ap.add_argument("--manifest", required=True, type=Path)
    args = ap.parse_args()

    if not args.input.exists():
        print(f"ERROR: input CSV not found: {args.input}", file=sys.stderr)
        sys.exit(1)

    with args.input.open(newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        rows = list(reader)

    if rows:
        sample = rows[0]
        required_cols = {"issue_id", "framework", "date", "title", "notes"}
        missing = required_cols - set(sample.keys())
        if missing:
            print(f"ERROR: CSV missing required columns: {missing}", file=sys.stderr)
            print(f"Available columns: {list(sample.keys())}", file=sys.stderr)
            sys.exit(2)

    label_counts = {"bf": 0, "bu": 0, "mf": 0, "fr": 0, "": 0, "other": 0}
    fr_rows = []
    for r in rows:
        v1_0 = extract_label(r.get("notes", ""))
        if v1_0 in label_counts:
            label_counts[v1_0] += 1
        else:
            label_counts["other"] += 1
        if v1_0 == "fr":
            r["_v1_0_label"] = v1_0
            fr_rows.append(r)

    print(f"Label counts (parsed from `paper:XX` in notes):")
    for label, count in sorted(label_counts.items()):
        if count > 0:
            print(f"  {label or '(unlabeled)'}: {count}")
    print(f"  total: {sum(label_counts.values())}")
    print()
    print(f"Found {len(fr_rows)} rows tagged `fr` under v1.0")
    print(f"  (expected 22 from paper section 2.4 case-type breakdown)")

    if len(fr_rows) == 0:
        print("ERROR: no `fr` rows found", file=sys.stderr)
        sys.exit(3)

    if len(fr_rows) != 22:
        print(f"WARNING: expected 22 `fr` rows, found {len(fr_rows)}. "
              "Proceeding anyway; verify against paper section 2.4 before "
              "publishing v1.1 kappa.", file=sys.stderr)

    fr_rows.sort(key=lambda r: r.get("issue_id", ""))

    blinded_rows = []
    blinding_violations = []
    for r in fr_rows:
        cleaned_notes = strip_label(r.get("notes", ""))
        if re.search(r'paper:\w+', cleaned_notes, re.IGNORECASE):
            blinding_violations.append(r["issue_id"])
        blinded_rows.append({
            "id":            r.get("issue_id", ""),
            "framework":     r.get("framework", ""),
            "year":          extract_year(r.get("date", "")),
            "title":         r.get("title", ""),
            "body_excerpt":  cleaned_notes,
            "github_url":    r.get("short_url", ""),
            "v1_1_label":    "",
            "v1_1_rationale": "",
        })

    if blinding_violations:
        print(f"ERROR: blinding-validity check FAILED for "
              f"{len(blinding_violations)} rows: {blinding_violations}", file=sys.stderr)
        print("The strip_label() regex did not remove all `paper:XX` markers.",
              file=sys.stderr)
        sys.exit(4)

    print(f"Blinding-validity check PASSED: 0 `paper:XX` markers in blinded notes")

    blinded_columns = ["id", "framework", "year", "title",
                       "body_excerpt", "github_url",
                       "v1_1_label", "v1_1_rationale"]
    with args.output.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=blinded_columns)
        writer.writeheader()
        for row in blinded_rows:
            writer.writerow(row)

    with args.hidden_labels.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=["id", "v1_0_label"])
        writer.writeheader()
        for r in fr_rows:
            writer.writerow({"id": r["issue_id"], "v1_0_label": r["_v1_0_label"]})

    input_hash = sha256_of(args.input)
    output_hash = sha256_of(args.output)
    hidden_hash = sha256_of(args.hidden_labels)
    ts = datetime.now(timezone.utc).isoformat()

    manifest = f"""M6 IRR re-annotation -- manifest
================================

Generated: {ts}
Script: generate_blinded_sheet.py v2 (paper:XX-from-notes parser)

Input:
  Path: {args.input}
  SHA-256: {input_hash}
  Rows total: {len(rows)}
  Rows with paper:fr label (v1.0): {len(fr_rows)}

Output (blinded coding sheet -- given to rater B):
  Path: {args.output}
  SHA-256: {output_hash}
  Columns: {blinded_columns}
  Blinding-validity check: PASSED (0 paper:XX markers in body_excerpt)

Hidden v1.0 labels (NEVER given to rater B):
  Path: {args.hidden_labels}
  SHA-256: {hidden_hash}
  Use: input to compute_v1_1_kappa.py after rater B returns the sheet.

Pre-committed acceptance criteria (from paper section 8.3, M6):
  kappa_fr_v1.1 >= 0.85         -> v1.1 rule confirmed, no catalogue change
  0.75 <= kappa_fr_v1.1 < 0.85  -> v1.1 rule confirmed, add reclassification note
  kappa_fr_v1.1 < 0.75          -> v1.1 rule did not close seam, substantive revision

Commit this manifest to irr-package/v1.1/manifest.txt.
"""
    args.manifest.write_text(manifest)

    print()
    print(f"Wrote blinded coding sheet:  {args.output}")
    print(f"Wrote hidden v1.0 labels:    {args.hidden_labels}")
    print(f"Wrote manifest:              {args.manifest}")
    print()
    print("NEXT STEPS:")
    print(f"  1. Send {args.output} to rater B (Zahid Hussain)")
    print(f"  2. Send codebook_v1_1.md to rater B")
    print(f"  3. Rater B fills in v1_1_label and v1_1_rationale columns")
    print(f"  4. When rater B returns the sheet, run:")
    print(f"       python3 compute_v1_1_kappa.py \\")
    print(f"         --rater-b-sheet returned_sheet.csv \\")
    print(f"         --hidden-labels {args.hidden_labels} \\")
    print(f"         --report kappa_v1_1_report.txt")


if __name__ == "__main__":
    main()
