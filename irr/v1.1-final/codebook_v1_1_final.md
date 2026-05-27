# Codebook v1.1-final — Token Budgets failure catalogue

Version: 1.1-final
Date: 2026-05-28 (revised from v1.1-draft after methodological review)
Author: Sajjad Khan
Diff from v1.0: adds interrogative-titled-issue disambiguation rule
Diff from v1.1-draft: retracts rule v1.1.1 (PR-linkage override) on
  semantic grounds (see "Correction notice" below)

---

## CORRECTION NOTICE (transparent provenance)

The v1.1-draft codebook published earlier on 2026-05-27 included a
rule v1.1.1 ("when an issue is closed with a linked PR or commit,
that linkage overrides the v1.1.0 decision tree and the tag is bf").
This rule was applied by rater B to a 22-case fr-only subsample and
produced 10 fr->bf reclassifications.

Subsequent methodological review identified rule v1.1.1 as
semantically aggressive: it conflated "feature request shipped via
PR" (which is still a feature-request thread that happened to
result in code) with "bug fix shipped" (which requires the original
report to frame the issue as a bug, not a request). The two are
distinct under v1.0's intent: bf requires the original issue to be
ACCEPTED AS A BUG by maintainers, not merely closed with a PR.

The v1.1-final codebook published here removes rule v1.1.1. The
v1.1-draft attempt is retained in artefact commit history at
irr-package/v1.1-draft/ for transparency, with the relevant
rater B work-product (returned_sheet.csv with 22 cases) preserved
as a draft attempt that does not contribute to the published
kappa figure.

---

## Codebook v1.0 baseline (unchanged from `codebook_v1_0.md`)

The four tags are:

- **`bf` (bug_fixed_by_framework)**: a reported budget-overrun
  incident that the framework's maintainer team accepted as a bug
  and shipped a fix for. Evidence required:
  (a) the original issue describes a bug (failure incident, error,
      broken behavior), NOT a feature request
  (b) the issue is closed with a linked PR or commit
  (c) the PR/commit modifies the framework's budget-tracking logic
  (d) the fix is in a released version

- **`bu` (bug_unfixed)**: a reported budget-overrun incident that
  the framework's maintainer team accepted as a real bug but has
  not yet shipped a fix for. Evidence: the issue is open or closed
  as wont-fix/duplicate/stale; the maintainer comment acknowledges
  the bug; no released fix exists.

- **`mf` (maintainer_framing)**: an issue thread where the framework
  maintainer (not the original reporter) responded that the budget
  primitive is structurally absent or known-broken, and either
  accepted the limitation as 'working as intended' or scheduled it
  as a future-release issue. Evidence: maintainer comment that
  explicitly names the cluster-1 budget-primitive-missing condition.

- **`fr` (feature_request)**: an issue opened by a user requesting a
  budget primitive that does not exist in the framework, without a
  specific overrun-incident report attached. Evidence: title or body
  phrases the issue as a request ("can you add", "feature request",
  "would be nice to have"); no specific cost figures or
  reproduction steps. A subsequent PR that ships the requested
  feature does NOT change the tag from fr to bf (the original
  framing as a request is preserved).

## Codebook v1.1-final — disambiguation rules

### Rule v1.1.0: Interrogative-titled-issue disambiguation

When an issue title is interrogative (begins with "Can we", "Can you",
"How do I", "How can we", "Is there a way", "Why does", "Why is",
"Does", "Will", "Should", or any question mark in the first 60
characters of the title), apply the following decision tree:

```
START
  |
  v
Is the issue body purely a feature-discovery question?
(e.g. "Where do I find the cost-per-token option?",
"Is there a way to limit cost?", with no incident
described)
  |
  +-- YES --> tag = fr
  |
  +-- NO --> Does the body document a specific incident
              with at least ONE of:
              - dollar amount lost
              - token-count amplification factor
              - reproduction steps that produce overrun
              - quoted error message / stack trace
              - measured time-to-overrun
              ?
              |
              +-- YES --> tag = bu  (if no fix shipped)
              |              OR bf  (if fix shipped AND
              |                      original framed as bug)
              |
              +-- NO --> Does the body contain a maintainer
                          comment that names the
                          budget-primitive-missing condition
                          for this framework?
                          |
                          +-- YES --> tag = mf
                          |
                          +-- NO --> tag = fr
END
```

### Rule v1.1.1: Cross-issue duplicate handling
(formerly rule v1.1.2 in v1.1-draft; v1.1.1 PR-linkage rule retracted)

When an issue is closed as duplicate of another (`#NNNN`), the tag
of the current issue is the tag of the parent issue. If the parent
is in the catalogue, use the catalogue tag; if the parent is not in
the catalogue, apply v1.1.0 to the parent's content and use that tag.

---

## Application notes for rater B

The v1.1-final rule applies to ALL 113 labeled cases in the IRR
sample (issues with `paper:XX` tags in the source CSV's notes field;
unlabeled rows are excluded as before).

For each case, rater B should:
1. Read the issue title and body (provided in body_excerpt column)
2. Apply rule v1.1.0 (interrogative disambiguation) if applicable
3. Apply rule v1.1.1 (duplicate handling) if applicable
4. Otherwise apply the v1.0 baseline tag definitions
5. Output one of `{bf, bu, mf, fr}` per case
6. Add a one-sentence rationale per case

The rater works BLINDED to the v1.0 labels. The blinded coding
sheet contains all 113 cases; the v1.0 labels are held in a
separate file and used only for kappa computation AFTER rater B
returns the sheet.

## What the re-annotation produces

Three numbers go into the paper's headline table:

1. **kappa_fr_v1.1-final**: Cohen's kappa, one-vs-rest on `fr`,
   computed on the full 113-case sample.
2. **N reclassified**: cases where rater A (v1.0) and rater B (v1.1)
   assigned different tags (any pair direction).
3. **Overall kappa_v1.1-final**: full-sample Cohen's kappa across
   all four classes.

Pre-committed thresholds (from paper §8.3, M6; identical to v1.1-draft):

| Outcome | kappa_fr_v1.1-final | Paper-text action |
|---|---|---|
| (i) | >= 0.85 | v1.1-final rule confirmed; replace v1.0 kappa_fr in headline table |
| (ii) | 0.75 <= x < 0.85 | v1.1-final rule confirmed; add note quantifying reclassified rows |
| (iii) | < 0.75 | v1.1-final rule did NOT close seam; v1.0 baseline retained, postmortem documented |

The threshold semantics are unchanged from v1.1-draft. The
underlying codebook is corrected to remove a rule identified as
semantically incorrect on grounds independent of any specific
kappa outcome (the rule conflates request-framing with bug-fix
semantics, which is a logical issue regardless of empirical result).
