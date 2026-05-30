import argparse, csv, re, sys
from pathlib import Path

CANONICAL = [
    "M-delegation-fanout",
    "M-retry-loop",
    "M-context-amplification",
    "M-storage-amplification",
    "M-multimodal-cost-amplification",
    "providerOptions-silently-dropped",
    "M-cost-observability",
    "M-budget-primitive-missing",
]

RETAINED = re.compile(r"paper:(bf|bu|mf|fr)\b", re.I)
CANON_RE = re.compile("|".join(re.escape(c) for c in CANONICAL))
PAPER_TAG_RE = re.compile(r"paper:\w+\s*;?\s*", re.I)
ANY_M_RE = re.compile(r"\bM-[a-z][a-z-]+\b")


def strip_hints(notes: str) -> str:
    s = PAPER_TAG_RE.sub("", notes or "")
    s = ANY_M_RE.sub("[mechanism-redacted]", s)
    return s.strip(" ;\n\t")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--input", required=True, type=Path)
    ap.add_argument("--output", required=True, type=Path)
    args = ap.parse_args()
    rows = list(csv.DictReader(args.input.open(encoding="utf-8")))
    retained = [r for r in rows if RETAINED.search(r.get("notes", ""))]

    out_rows, counts = [], {"AUTO": 0, "AMBIGUOUS_MULTI": 0, "NEEDS_MANUAL": 0}
    for r in retained:
        notes = r.get("notes", "")
        found = []
        for c in CANONICAL:                       # collect canonical hits, in precedence order
            if re.search(re.escape(c), notes):
                found.append(c)
        if len(found) == 1:
            cluster, status = found[0], "AUTO"
        elif len(found) > 1:
            # apply precedence: first in CANONICAL order wins, but flag for review
            cluster, status = sorted(found, key=CANONICAL.index)[0], "AMBIGUOUS_MULTI"
        else:
            cluster, status = "", "NEEDS_MANUAL"
        counts[status] += 1
        out_rows.append({
            "issue_id": r.get("issue_id", ""),
            "framework": r.get("framework", ""),
            "title": r.get("title", ""),
            "short_url": r.get("short_url", ""),
            "rater_a_cluster": cluster,
            "status": status,
            "notes_stripped": strip_hints(notes),
        })

    with args.output.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(out_rows[0].keys()))
        w.writeheader(); w.writerows(out_rows)

    print(f"retained rows processed: {len(out_rows)}")
    print(f"  AUTO (single canonical tag found): {counts['AUTO']}")
    print(f"  AMBIGUOUS_MULTI (>1 tag; precedence applied, REVIEW): {counts['AMBIGUOUS_MULTI']}")
    print(f"  NEEDS_MANUAL (no canonical tag; YOU must assign): {counts['NEEDS_MANUAL']}")
    print(f"wrote {args.output}")
    print("\nNEXT: open the file, fill every NEEDS_MANUAL row and verify every")
    print("AMBIGUOUS_MULTI row by reading the issue at short_url, then set status=FINAL.")


if __name__ == "__main__":
    main()