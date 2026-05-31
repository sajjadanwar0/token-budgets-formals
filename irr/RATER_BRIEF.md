# Inter-rater reliability coding task

## What you're being asked to do

Independently classify each GitHub issue in the coding sheet you have been
given into exactly one of four categories. Your codings are compared against
the original rater's (Sajjad's) to establish inter-rater reliability for a
research catalog of LLM-agent budget-overrun failures.

**You are blinded**: you do NOT see how the original rater classified each
issue. Please do not seek out their classification.

> **Scope note (provenance).** This brief is the coding *instrument* — the
> instructions and category definitions handed to the second rater. The
> reliability re-annotation was run in two phases and covers the full catalog:
> Phase 1 = 109 issues (`coding_sheet_phase1_reconstructed.csv` →
> `independent_second_human_annotator_109.csv`) and Phase 2 = 4 issues added
> during later catalog construction (`zahid_phase2_completed.csv`), for a
> combined N = 113 (`independent_second_human_annotator_113.csv`). Phase 1 was
> a **tag-only** pass: the rater entered one tag per row and free-text notes
> were not requested; the per-row `rater_b_notes` field is therefore populated
> only for the 4 Phase-2 rows, which were re-rated in a separate session.

## Materials you have

1. **the coding sheet** (e.g. `coding_sheet_phase1_reconstructed.csv`) — the
   issues to code, one per row. Open in any spreadsheet program or text editor.
2. **`codebook_v1.md`** — the formal definitions of the four categories plus
   the inclusion/exclusion rules. **Read this first** (sections 2 and 3 are the
   critical ones).

## Workflow

For each row:

1. Read the codebook once, upfront.
2. Open the GitHub issue in your browser. The `short_url` column gives you
   `#NUMBER`; the `framework` column tells you which repo:
   - `langchain` → https://github.com/langchain-ai/langchain/issues/NUMBER
   - `langgraph` → https://github.com/langchain-ai/langgraph/issues/NUMBER
   - `crewai` → https://github.com/crewAIInc/crewAI/issues/NUMBER
   - `autogen` → https://github.com/microsoft/autogen/issues/NUMBER
   - other frameworks → search the repo on GitHub
3. Read the issue body, comments, and resolution status.
4. Choose ONE of the four tags:
   - `bf` = **bug_fixed_by_framework**: closed with a real maintainer-authored
     patch, merged.
   - `bu` = **bug_unfixed**: acknowledged as a real failure but not patched
     (stale-closed-by-bot, closed-as-not-planned, declined,
     user-found-workaround-only).
   - `fr` = **feature_request**: asking for a missing budget mechanism rather
     than reporting a specific bug.
   - `mf` = **maintainer_framing**: a maintainer (or core contributor)
     responds by characterizing the failure as inherent, expected, or
     by-design.
5. Type your tag into the `rater_b_tag` column for that row. Save.

## Tie-breakers

- **Both a bug report AND a feature request**: code by the dominant framing. If
  the body opens with "X is broken, here's a trace," code `bf`/`bu`. If it
  opens with "X is missing, please add Y," code `fr`.
- **A maintainer comment exists but is brief**: code `mf` only if the
  maintainer's comment is at least one full sentence and explicitly
  classifies/explains/contextualizes the failure pattern. Otherwise use
  `bf`/`bu` based on resolution status.
- **You can't tell from the issue alone**: pick the most likely category and
  note the ambiguity.

## When you're done

Save the completed sheet (with all `rater_b_tag` cells filled) and return it.
The original rater runs the comparison script and reports back Cohen's kappa.

## Why this matters

Single-rater catalogs in software-engineering research are routinely flagged as
a methodological weakness. A second independent coding gives the work a kappa
statistic that quantifies how reliable the classification scheme is. Moderate
agreement (kappa around 0.6) is a real result; perfect agreement is unrealistic
for any judgment-heavy task and is itself a sign of insufficiently challenging
categories. The disagreement-adjudication step is part of the process, not a
failure of it.
