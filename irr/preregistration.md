# Pre-registration: systematic complementary sample

**Status:** PRE-REGISTERED. Commit this file with a timestamp BEFORE any
mining or coding begins. Its purpose is to answer the "convenience
sample / selection on the dependent variable" threat by drawing from a
frame whose selection criterion is **independent of whether the failure
occurred**.

**Date registered:** __________  **Commit SHA:** __________

---

## 1. Why this sample exists

The main 110-row catalog was found by searching failure keywords
("budget", "cost", "infinite loop", …) — selection conditioned on the
outcome. This complementary sample fixes the frame on *popularity*, not
*has-a-cost-bug*, so we can ask: do the eight mechanism clusters recur
outside the keyword-selected frame, and does any **ninth** mechanism
appear (saturation)?

We claim **recurrence** and **saturation**. We do **NOT** claim
prevalence.

## 2. Sampling frame (fixed a priori)

- **Population:** GitHub repositories under topic `llm-agent` OR
  `ai-agent` OR `agent-framework`.
- **Selection:** the top **N = 40** by star count as observed on a
  single fixed date **D = __________**, retrieved via the GitHub search
  API query string `__________` (record the exact query and the raw
  result list as `frame_snapshot_D.json`).
- **Exclusions:** the 21 sub-projects already in the main catalog
  (list them); non-English primary docs; archived/read-only repos;
  repos with <__ issues. Record every exclusion with a reason.
- Freeze the resulting repo list as `complementary_frame.csv` before
  reading any issues.

## 3. Per-repo screening procedure (fixed a priori)

For each repo in the frame, in list order:

1. Pull the **M = 30** most-commented issues (state/open+closed),
   regardless of content, via a fixed API call (record the call).
2. For each issue, two coders independently apply the **same Section-2
   inclusion criteria** as the main catalog (budget-overrun incident or
   budget-primitive-missing condition with evidence).
3. For each **included** issue, both coders assign one primary cluster
   from `codebook_v1.2_clusters.md` (the eight + `M-other`).

The procedure is mechanical: no "search until a failure is found."
Every screened issue gets an include/exclude decision recorded.

## 4. Measures and analysis (fixed a priori)

- **Inter-rater reliability on inclusion:** Cohen's κ on the
  include/exclude decision over all screened issues.
- **Inter-rater reliability on cluster:** Cohen's κ on cluster among
  jointly-included issues (reuse `compute_cluster_kappa.py`).
- **Recurrence:** fraction of the N repos exhibiting ≥1 of the eight
  clusters.
- **Saturation:** count of included issues assigned `M-other`; for each,
  the proposed new mechanism. **Decision rule:** if `M-other` ≥ 10% of
  included issues, the taxonomy is declared incomplete and a candidate
  ninth cluster is reported (not silently merged).
- **Screen→include rate:** included / screened, reported as a coarse
  base-rate *signal only*, explicitly NOT a prevalence estimate.

## 5. What gets reported in the paper

One paragraph in §2 (methodology) and one threats sentence:
"A pre-registered complementary sample of N=40 popularity-selected
repositories (frame independent of failure), double-coded
(κ_include=__, κ_cluster=__), finds the mechanism clusters recur in
__/40 repositories and surfaces [no new mechanism / a candidate
M-________ cluster], supporting [completeness / a bounded revision of]
the taxonomy. We report recurrence and saturation, not prevalence."

## 6. Deviations log

Record any deviation from this protocol here, with date and reason.
Deviations do not invalidate the study; concealing them would.