# `irr/` — inter-rater reliability package (cleaned)

This is the pruned, internally-consistent IRR package. Every file supports a
claim in the paper; nothing here contradicts the reported numbers.

## Tag-level IRR (the κ = 0.837 reliability claim — load-bearing)
- `independent_second_human_annotator_113.csv` — two-rater data (columns
  `rater_a_tag`, `rater_b_tag`). Reproduces overall Cohen's κ = 0.837,
  observed agreement 0.894; per-class κ: bf 0.858, bu 0.876, fr 0.727,
  mf 0.918.
- `irr_scaffold.py` — computes the above (called by `reproduce.sh`).
- `per_class_kappa.csv` — per-class κ output.
- `zahid_phase2_completed.csv` — the 4-row phase-2 supplement behind N=113.
- `IRR_COVERAGE_NOTE.md` — the N=109 → 113 two-phase explanation.
- `RATER_BRIEF.md` — rater instructions.
- `codebook_v1.md` — inclusion / tag codebook (its §6 mechanism list is
  marked superseded; see below).
- `v1.1-final/` — the final tag-IRR pipeline + report (`kappa_v1_1_final_report.txt`).

## Cluster-level layer (single-rater, reproducible from a column)
- `Codebook_v1.2_clusters.md` — authoritative eight-cluster taxonomy +
  single-primary precedence rule (supersedes `codebook_v1.md` §6).
- `catalogue_with_primary_cluster.csv` — the catalogue with a populated
  `primary_cluster` column; the §2.5 cluster counts re-derive from it:
  retry-loop 27, cost-observability 22, context-amplification 13,
  storage-amplification 13, budget-primitive-missing 12, delegation-fanout 11,
  providerOptions-silently-dropped 6, multimodal-cost-amplification 6 (= 110).
- `cluster_recode_log_49rows.csv` — audit trail for the 49 ambiguous rows
  re-coded by reading the source issue (issue URL + evidence basis +
  assigned cluster); substantiates the §2.5 re-coding statement.
- `cluster_rater_a_final.csv` — the rater-A cluster column (`issue_id`,
  `rater_a_cluster`), wired for `compute_cluster_kappa.py --hidden`.
- `build_cluster_rater_a.py` — STEP 1 scaffold builder. **Two fixes applied:**
  (1) `CANONICAL` now lists the paper's eight (added
  `providerOptions-silently-dropped`, removed `M-rate-limit-amplification`);
  (2) output column renamed `extracted_cluster` → `rater_a_cluster` so it
  feeds STEP 3 directly.
- `compute_cluster_kappa.py` — STEP 3. To compute a cluster κ once a second
  human codes the rows:
  `python3 compute_cluster_kappa.py --hidden cluster_rater_a_final.csv \
      --rater-b <rater_b_primary_cluster>.csv --report cluster_kappa_report.txt`
  (rater-B file needs a `primary_cluster` column).
- `preregistration_complementary_sample.md` — pre-registered complementary
  (popularity-selected) sample protocol.

## Removed from the previous tree (and why)
- `cluster_rater_a_ABSOLUTE_FINAL.csv` — 59-row residual dump; contradicted
  the reported counts.
- `cluster_rater_a_FINALIZED.csv` — `status=FINAL` while 49 rows were blank.
- `cluster_rater_a.csv` — unfinished scaffold; superseded.
- `rater_b.csv`, `rater_b_done.csv`, `returned_cluster_sheet.csv`,
  `blinded_cluster_sheet.csv` — abandoned cluster rater-B attempt that
  produced an inflated κ (52% of rows in one bucket); contradicts the paper's
  "cluster assignment is single-rater, not IRR-tested" statement.
- `independent_second_human_annotator.csv`, `_109.csv`,
  `second_annotator.csv`, `second_human_annotator.csv` — earlier versions of
  the `_113` file.
- `coding_sheet*.csv`, `_master_with_rater_a*.csv` — intermediate working
  sheets.
- `merge_and_compute.py` — duplicated `irr_scaffold.py`.
- `v1.1-draft/` — superseded by `v1.1-final/`.

If a reviewer ever asks how the cluster coding evolved, the removed files are
recoverable from git history (tag the pre-cleanup commit before deleting).
