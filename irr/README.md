# Inter-rater reliability (IRR) package — Token Budgets catalog

Self-contained package for the human two-rater reliability of the catalog's
four-class incident scheme, plus the exploratory cluster-assignment IRR.
Everything needed to reproduce the reported kappas is here; no external files
required.

## Headline result (four-class scheme — validated)
- **Overall Cohen's kappa = 0.8374** (four classes bf/bu/mf/fr, n = 113,
  observed agreement 0.894) — "almost perfect" (Landis–Koch).
- **Per-class** (one-vs-rest): bf 0.858, bu 0.876, mf 0.918, fr 0.727. The
  `fr` (feature-request) boundary is the codebook's weakest seam.
- **Confirmed subset = 0.9427** — this is the **bf-vs-bu** agreement among the
  **79** incidents *both* raters mark confirmed (observed 0.975). It is a
  DIFFERENT measure from the overall 0.8374, at a narrower scope. Cite each with
  its scope; they are not in conflict.

## Reproduce (four-class)
```
python3 compute_irr.py
```
Reads `independent_second_human_annotator_113.csv` (which contains both raters'
tags) and prints the overall, per-class, and confirmed-subset (n = 79) kappas
above. `reproduce.sh` check 14 invokes `irr_scaffold.py compute` on the same
file and prints `Pairs analyzed: 113`, `Cohen's kappa: 0.837`.

## Files (four-class IRR)
| File | What it is |
|---|---|
| `catalogue.csv` | the full corrected catalog (110 retained + triaged rows) with the `label` (rater-A authoritative tag) and `primary_cluster` columns. Ground truth for all counts; needed for catalog-level and cluster computations. |
| `independent_second_human_annotator_113.csv` | the IRR data — 113 issues with `rater_a_tag`, `rater_b_tag`, `phase`, and `rater_b_notes`. Self-contained. |
| `independent_second_human_annotator_109.csv` | the Phase-1 subset (`phase == 1`), reconstructed deterministically from the 113-row file for audit traceability; recomputes to kappa = 0.832. |
| `cluster_coding_sheet_BLINDED.csv` | the blinded cluster-coding *instrument* (issue metadata, empty `rater_b_cluster`, no rater-A cluster) — the sheet the cluster rater filled in. |
| `irr_scaffold.py` | the script `reproduce.sh` (check 14) invokes: `python3 irr_scaffold.py compute --input independent_second_human_annotator_113.csv`. |
| `compute_irr.py` | stdlib recompute of overall / per-class / confirmed-subset (n = 79) kappas. |
| `per_class_kappa.csv` | the pre-computed per-class / overall / confirmed-subset table. |
| `codebook_v1.md` | the four-class labeling codebook (bf/bu/mf/fr definitions, inclusion/exclusion). |
| `RATER_BRIEF.md` | the coding instrument given to the second rater; see its scope note for the two-phase, tag-only Phase-1 design. |
| `IRR_COVERAGE_NOTE.md` | two-phase design, coverage, why Phase 1 carries tags but no notes, and the reconstructed-file provenance. |
| `zahid_cluster_coded_sheet.csv` | the cluster rater's completed blind return (provenance for the frozen cluster-B file). |
| `zahid_phase2_completed.csv` | the second rater's completed four-class Phase-2 return, with rationales (provenance). |
| `irr-disagreements.md` | the 12 rater-pair disagreements in the N=113 four-class sample, with rater A's catalogue `label` as the adjudicated resolution. |

## Label scheme (four-class)
- `bf` — confirmed budget failure (incident occurred)
- `bu` — budget-unbounded condition (no cap; overrun possible/observed)
- `mf` — missing feature acknowledged by maintainers
- `fr` — feature request (no incident)

## Cluster-assignment IRR (exploratory)

The paper's eight mechanism *clusters* are an exploratory, descriptive layer on
top of the four-class scheme. A second rater independently coded all 110 rows
blind, against the sharpened cluster codebook (`cluster/cluster_codebook_v2.md`),
from the GitHub issue threads. Result:

- **Overall cluster-assignment Cohen's kappa = 0.4440** (8 clusters, N = 110,
  95% CI [0.34, 0.55], observed agreement 0.527) — moderate; the eight-way
  partition is **not** treated as a validated taxonomy.
- **Reliably identified mechanisms**: cost-observability (kappa = 0.78) and
  multimodal-cost-amplification (kappa = 0.65). The remaining boundaries
  overlap, largely because real incidents combine mechanisms (e.g. a
  "disable retry on timeout" request whose ignored `max_retries` option makes it
  at once a retry-loop and a dropped-provider-option case).

The paper reports this as exploratory (§2.5, limitations); the four-class scheme
above (kappa = 0.837) is the IRR-validated labeling.

### Reproduce (cluster, exploratory)
```
cd cluster
python3 compute_cluster_kappa.py cluster_irr_rater_a_frozen.csv cluster_irr_rater_b_frozen.csv
```
`reproduce.sh` (check 14b) runs exactly this against the two frozen independent
codings and confirms kappa = 0.4440. The codings are frozen snapshots of the two
raters' **original** independent labels — *not* the live `catalogue.csv`, whose
`primary_cluster` column may be revised by later adjudication. Recomputing
against a corrected catalogue would yield a different number and would not be the
reported reliability.

### Files in `cluster/`
| File | What it is |
|---|---|
| `cluster_irr_rater_a_frozen.csv` | rater A's original cluster labels (`issue_id`, `primary_cluster`), frozen at IRR time. |
| `cluster_irr_rater_b_frozen.csv` | rater B's blind cluster labels (`issue_id`, `rater_b_cluster`). |
| `compute_cluster_kappa.py` | stdlib Cohen's kappa + bootstrap CI + per-cluster kappa + confusion matrix. |
| `cluster_codebook_v2.md` | the sharpened cluster codebook the second rater coded against. |

## Scope note
The four-class incident-classification IRR (kappa = 0.837) is the validated
reliability result. The eight-cluster IRR (kappa = 0.44) is exploratory and is
reported as such in the paper. No complementary-sample / popularity-frame
material is included here.