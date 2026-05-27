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
VALID_LABELS = {"bf", "bu", "mf", "fr"}

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
        rows = list(csv.DictReader(f))

    if rows:
        required_cols = {"issue_id", "framework", "date", "title", "notes"}
        missing = required_cols - set(rows[0].keys())
        if missing:
            print(f"ERROR: CSV missing required columns: {missing}", file=sys.stderr)
            sys.exit(2)

    label_counts = {k: 0 for k in list(VALID_LABELS) + ["", "other"]}
    labeled_rows = []
    for r in rows:
        v1_0 = extract_label(r.get("notes", ""))
        if v1_0 in label_counts:
            label_counts[v1_0] += 1
        else:
            label_counts["other"] += 1
        if v1_0 in VALID_LABELS:
            r["_v1_0_label"] = v1_0
            labeled_rows.append(r)

    print(f"Label counts (parsed from `paper:XX` in notes):")
    for label, count in sorted(label_counts.items()):
        if count > 0:
            print(f"  {label or '(unlabeled)'}: {count}")
    print(f"  total: {sum(label_counts.values())}")
    print()
    print(f"Labeled cases (all four classes): {len(labeled_rows)}")
    print(f"  (expected 113 from paper section 2.4)")

    if len(labeled_rows) == 0:
        print("ERROR: no labeled rows found", file=sys.stderr)
        sys.exit(3)

    if len(labeled_rows) != 113:
        print(f"WARNING: expected 113 labeled rows, found {len(labeled_rows)}. "
              "Verify against paper section 2.4 before publishing.", file=sys.stderr)

    labeled_rows.sort(key=lambda r: r.get("issue_id", ""))

    blinded_rows = []
    blinding_violations = []
    for r in labeled_rows:
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
              f"{len(blinding_violations)} rows: {blinding_violations}",
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
        for r in labeled_rows:
            writer.writerow({"id": r["issue_id"], "v1_0_label": r["_v1_0_label"]})

    input_hash = sha256_of(args.input)
    output_hash = sha256_of(args.output)
    hidden_hash = sha256_of(args.hidden_labels)
    ts = datetime.now(timezone.utc).isoformat()

    by_class = {k: 0 for k in VALID_LABELS}
    for r in labeled_rows:
        by_class[r["_v1_0_label"]] += 1

    manifest = f"""M6 IRR re-annotation -- manifest (v3, full 113-case sample)
============================================================

Generated: {ts}
Script: generate_blinded_sheet_v3.py
Codebook: codebook_v1_1_final.md (rule v1.1.1 retracted)

Input:
  Path: {args.input}
  SHA-256: {input_hash}
  Rows total: {len(rows)}
  Labeled (bf/bu/mf/fr) rows: {len(labeled_rows)}
  Per-class breakdown:
    bf: {by_class['bf']}  (expected 27)
    bu: {by_class['bu']}  (expected 57)
    mf: {by_class['mf']}  (expected 7)
    fr: {by_class['fr']}  (expected 22)

Output (blinded coding sheet -- given to rater B):
  Path: {args.output}
  SHA-256: {output_hash}
  Columns: {blinded_columns}
  Blinding-validity check: PASSED (0 paper:XX markers in body_excerpt)

Hidden v1.0 labels (NEVER given to rater B):
  Path: {args.hidden_labels}
  SHA-256: {hidden_hash}

Pre-committed acceptance criteria (paper section 8.3, M6):
  kappa_fr_v1.1-final >= 0.85         -> (i) rule confirmed, replace v1.0 figure
  0.75 <= kappa_fr_v1.1-final < 0.85  -> (ii) rule confirmed, add reclassification note
  kappa_fr_v1.1-final < 0.75          -> (iii) v1.0 retained, postmortem documented

Provenance note:
  This v3 sheet supersedes the v2 (22-case fr-only) blinded sheet
  generated on 2026-05-27, which produced a mathematically degenerate
  kappa = 0.000 (rater A prevalence = 1.0 on fr-only subsample).
  The v2 attempt is preserved in artefact at irr-package/v1.1-draft/
  for transparency. The v1.1-final codebook also removes rule v1.1.1
  (PR-linkage override) identified as semantically aggressive during
  methodological review of the v2 attempt.
"""
    args.manifest.write_text(manifest)

    print()
    print(f"Wrote blinded coding sheet:  {args.output}  ({len(blinded_rows)} rows)")
    print(f"Wrote hidden v1.0 labels:    {args.hidden_labels}  ({len(labeled_rows)} rows)")
    print(f"Wrote manifest:              {args.manifest}")
    print()
    print("NEXT STEPS:")
    print(f"  1. Send {args.output} to rater B (Zahid Hussain)")
    print(f"  2. Send codebook_v1_1_final.md to rater B (NOT codebook_v1_1.md)")
    print(f"  3. Acknowledge in email that this supersedes the 22-case attempt")
    print(f"  4. Rater B fills in v1_1_label and v1_1_rationale columns (113 cases)")
    print(f"  5. Estimated rater B effort: 3-5 working days")
    print(f"  6. When rater B returns the sheet, run compute_v1_1_kappa.py")


if __name__ == "__main__":
    main()
