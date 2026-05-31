# Inter-rater reliability (IRR) package — Token Budgets catalog

Self-contained package for the human two-rater reliability of the catalog's
four-class incident scheme. Everything needed to reproduce the reported kappa
is here; no external files required.

## Headline result
- **Overall Cohen's kappa = 0.8374** (four classes bf/bu/mf/fr, n = 113,
  observed agreement 0.894) — "almost perfect" (Landis–Koch).
- **Per-class** (one-vs-rest): bf 0.858, bu 0.876, mf 0.918, fr 0.727. The
  `fr` (feature-request) boundary is the codebook's weakest seam.
- **Confirmed subset = 0.9427** — this is the **bf-vs-bu** agreement among the
  79 incidents *both* raters mark confirmed (observed 0.975). It is a DIFFERENT
  measure from the overall 0.8374, at a narrower scope. Cite each with its
  scope; they are not in conflict.

## Reproduce
```
python3 compute_irr.py
```
Reads `independent_second_human_annotator_113.csv` (which contains both raters'
tags) and prints the overall, per-class, and confirmed-subset kappas above.

## Files
| File | What it is |
|---|---|
| `catalogue.csv` | the full corrected catalog (167 rows = 110 retained + 57 triaged) with the `label` (rater-A authoritative tag) and `primary_cluster` columns. Ground truth for all counts; needed for catalog-level and cluster computations. |
| `independent_second_human_annotator_113.csv` | the IRR data — 113 issues with `rater_a_tag` and `rater_b_tag`. Self-contained. |
| `irr_scaffold.py` | the script `reproduce.sh` (check 14) invokes: `python3 irr_scaffold.py compute --input independent_second_human_annotator_113.csv` -> prints `Pairs analyzed: 113`, `Cohen's kappa: 0.837`. |
| `compute_irr.py` | stdlib recompute of overall/per-class/confirmed kappas (convenience; same result). |
| `per_class_kappa.csv` | the pre-computed per-class / overall / confirmed-subset table. |
| `codebook_v1.md` | the labeling codebook (bf/bu/mf/fr definitions, inclusion/exclusion). |
| `RATER_BRIEF.md` | instructions given to the independent second rater. |
| `IRR_COVERAGE_NOTE.md` | which rows were double-coded and why (coverage). |
| `zahid_phase2_completed.csv` | the second rater's completed phase-2 return (provenance). |
| `v1.1-final/` | the codebook-v1.1 boundary-sharpening reclassification (the pre-registered fr/bu sensitivity analysis referenced in the paper). |

## Label scheme
- `bf` — confirmed budget failure (incident occurred)
- `bu` — budget-unbounded condition (no cap; overrun possible/observed)
- `mf` — missing feature acknowledged by maintainers
- `fr` — feature request (no incident)

## Scope note
This package covers the **incident-classification IRR only**. The eight
mechanism *clusters* in the paper are a separate, single-rater analytic layer
(stated as a limitation in the paper) and are NOT part of this reliability
result. No complementary-sample / popularity-frame material is included here.
