# IRR Coverage Note

The kappa=0.832 result reported in the paper was computed on N=109 rows
(`independent_second_human_annotator_109.csv`). The full catalogue
(`budget-archaeology.csv`, identical in `data/` and `irr/`) contains
N=110 non-skipped rows.

## Why the 1-row delta

Four catalogue entries were added after the IRR campaign concluded:

- `CCDE-002`
- `LANG-020`
- `LANG-035`
- `SMAG-001`

These have rater A's tag only. Three earlier-numbered IDs in the IRR
file (`ATGN-004`, `DSPY-005`, `MAST-005`) were renumbered or removed
during catalogue cleanup; their rater-B annotations are retained in
the IRR file for audit traceability but do not appear in the current
catalogue.

## Reporting

kappa=0.832 reflects **99.1% coverage** of the catalogue (109 of 110 rows).
Per-class kappas in `per_class_kappa.csv` are computed on the same 109
row population.

If you obtain rater-B annotations for the 4 missing rows, rename the
IRR file to `independent_second_human_annotator_110.csv` and re-run
`merge_and_compute.py`. The kappa is expected to move within
[0.81, 0.85] given the small (4/110 = 3.6%) population change.
