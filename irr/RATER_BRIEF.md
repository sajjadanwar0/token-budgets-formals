# Inter-rater reliability coding task

## What you're being asked to do

Independently classify 30 GitHub issues into one of four categories. Your
codings will be compared against the original rater's (Sajjad's) to
establish inter-rater reliability for a research catalog of LLM agent
budget-overrun failures.

**Estimated time**: ~90 minutes (3 minutes per issue).

**You are blinded**: you do NOT know how the original rater classified
each issue. Please do not seek out their classification.

## Materials you have

1. **`coding_sheet_for_rater_b.csv`** — the 30 issues to code. Open in any
   spreadsheet program or text editor.
2. **`codebook_v1.md`** — the formal definitions of the four categories
   plus the inclusion/exclusion rules. **Read this first**.

## Workflow

For each row:

1. Read the codebook (once, upfront — sections 2 and 3 are the critical
   ones).
2. Open the GitHub issue in your browser. The `short_url` column gives
   you `#NUMBER`; the `framework` column tells you which repo:
   - `langchain` → https://github.com/langchain-ai/langchain/issues/NUMBER
   - `langgraph` → https://github.com/langchain-ai/langgraph/issues/NUMBER
   - `crewai` → https://github.com/crewAIInc/crewAI/issues/NUMBER
   - `autogen` → https://github.com/microsoft/autogen/issues/NUMBER
   - other frameworks → search the repo on GitHub
3. Read the issue body, comments, and resolution status.
4. Choose ONE of the four tags:
   - `bf` = **bug_fixed_by_framework**: closed with a real maintainer-authored
     patch, merged.
   - `bu` = **bug_unfixed**: acknowledged as a real failure but not
     patched. Includes stale-closed-by-bot, closed-as-not-planned,
     declined, user-found-workaround-only.
   - `fr` = **feature_request**: asking for a missing budget mechanism
     rather than reporting a specific bug.
   - `mf` = **maintainer_framing**: a maintainer (or core contributor)
     responds by characterizing the failure as inherent, expected, or
     by-design.
5. Type your tag into the `rater_b_tag` column for that row. Save.

## Tie-breakers

- **An issue that is both a bug report AND a feature request**: code by
  the dominant framing. If the body opens with "X is broken, here's a
  trace," code as `bf` or `bu`. If it opens with "X is missing, please
  add Y," code as `fr`.
- **A maintainer comment exists but is brief**: code as `mf` only if the
  maintainer's comment is at least one full sentence and explicitly
  classifies/explains/contextualizes the failure pattern. Otherwise use
  `bf` or `bu` based on resolution status.
- **You can't tell from the issue alone**: pick the most likely category
  and add a comment in a final column called `notes` (you can add this
  column yourself).

## What to do when you're done

Save the completed CSV (with all 30 `rater_b_tag` cells filled in) and
return it. The original rater will run the comparison script and report
back the agreement statistic (Cohen's kappa).

## Why this matters

Single-rater catalogs in software engineering research are routinely
flagged as a methodological weakness. A second independent coding gives
the work a kappa statistic that quantifies how reliable the
classification scheme is. Even moderate agreement (kappa around 0.6) is
a real result; perfect agreement is unrealistic for any judgment-heavy
classification task and is itself a sign of insufficiently challenging
categories.

## Questions

If anything in the codebook is unclear OR you want to flag systematic
ambiguity, just note it in the email/message you return the file with.
The disagreement-adjudication step is part of the process, not a
failure of it.

Thank you for the time.
