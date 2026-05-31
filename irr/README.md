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
| `independent_second_human_annotator_113.csv` | the IRR data — 113 issues with `rater_a_tag`, `rater_b_tag`, `phase`, and `rater_b_notes`. Self-contained. |
| `independent_second_human_annotator_109.csv` | the Phase-1 subset (`phase == 1`), reconstructed deterministically from the 113-row file for audit traceability; recomputes to kappa = 0.832. |
| `coding_sheet_phase1_reconstructed.csv` | the blinded Phase-1 coding *instrument* (issue metadata, empty `rater_b_tag`, no rater-A tags) — the sheet the second rater filled in, reconstructed from committed data. |
| `irr_scaffold.py` | the script `reproduce.sh` (check 14) invokes: `python3 irr_scaffold.py compute --input independent_second_human_annotator_113.csv` -> prints `Pairs analyzed: 113`, `Cohen's kappa: 0.837`. |
| `compute_irr.py` | stdlib recompute of overall/per-class/confirmed kappas (convenience; same result). |
| `per_class_kappa.csv` | the pre-computed per-class / overall / confirmed-subset table. |
| `codebook_v1.md` | the labeling codebook (bf/bu/mf/fr definitions, inclusion/exclusion). |
| `RATER_BRIEF.md` | the coding instrument (instructions + category definitions) given to the second rater; see its scope note for the two-phase, tag-only Phase-1 design. |
| `IRR_COVERAGE_NOTE.md` | two-phase design, coverage, why Phase 1 carries tags but no notes, and the reconstructed-file provenance. |
| `zahid_phase2_completed.csv` | the second rater's completed Phase-2 return, with rationales (provenance). |
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
