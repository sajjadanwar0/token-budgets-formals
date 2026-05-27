# Codebook v1.1 — Token Budgets failure catalogue

Version: 1.1  
Date: 2026-05-27  
Author: Sajjad Khan  
Diff from v1.0: adds interrogative-titled-issue disambiguation rule

---

## PRE-ATTACK (BRUTAL REVIEWER VOICE)

> "Your headline κ=0.837 is computed against a codebook your own paper
> admits is broken at the fr/bu boundary (κ_fr = 0.727 is the worst of
> four classes by 0.13 absolute). You name a 'v1.1 sharpening rule' in
> §5.27.0.1 but you never executed the re-annotation. You're asking
> reviewers to accept a κ figure on a self-described broken codebook
> with a promise to fix it later."

## DISPOSITION

Codebook v1.1 is published here in full, dated 2026-05-27. Re-annotation
under v1.1 is executed before EMSE venue submission. The new κ_fr_v1.1
figure REPLACES the κ_fr=0.727 figure in the paper's headline table,
with the v1.0 baseline retained in `irr-package/v1.0/` for diff-trail.

The v1.1 rule is published BEFORE re-annotation begins so that any
reader can verify (a) the rule is not retrofitted to maximise κ on the
specific 22 cases, (b) the rule is independently applicable by any
rater. Rater B (Zahid Hussain) re-rates blinded to v1.0 labels under
the rule below.

---

## Codebook v1.0 baseline (unchanged from `codebook_v1_0.md`)

The four tags are:

- **`bf` (bug_fixed_by_framework)**: a reported budget-overrun
  incident that the framework's maintainer team accepted as a bug
  and shipped a fix for. Evidence: the GitHub issue is closed with
  a linked PR or commit; the PR/commit modifies the framework's
  budget-tracking logic; the fix is in a released version.

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
  reproduction steps.

## Codebook v1.1 — disambiguation rule (new)

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
              +-- YES --> tag = bu
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

### Rule v1.1.1: Pre-existing fix linkage

When an issue is closed with a linked PR or commit, that linkage
overrides the v1.1.0 decision tree and the tag is `bf`, regardless
of title form.

### Rule v1.1.2: Cross-issue duplicate handling

When an issue is closed as duplicate of another (`#NNNN`), the tag
of the current issue is the tag of the parent issue. If the parent
is in the catalogue, use the catalogue tag; if the parent is not in
the catalogue, apply v1.1.0 to the parent's content and use that tag.

---

## Application notes for rater B

The v1.1 rule applies ONLY to the 22 cases tagged `fr` under v1.0.
Cases tagged `bf`, `bu`, or `mf` under v1.0 are NOT re-rated under
v1.1 (those tags are unaffected by the rule). The blinded coding
sheet contains the 22 v1.0-`fr` cases with v1.0 labels stripped.

The rule v1.1.0 decision tree should be applied independently per
case without reference to the original v1.0 label. Rater B's output
is one of `{bf, bu, mf, fr}` per case, plus a one-sentence rationale.

## What the re-annotation produces

Three numbers go into the paper's headline table:

1. **κ_fr_v1.1**: Cohen's kappa on the `fr` class under v1.1.
2. **N reclassified**: how many of the 22 v1.0-`fr` cases received a
   different tag under v1.1.
3. **Overall κ_v1.1**: full-sample κ after merging the 22 v1.1
   re-rated cases with the 91 non-`fr` cases from v1.0.

Pre-committed thresholds (from paper §8.3, M6 pre-registration):

| Outcome | κ_fr_v1.1 | Paper-text action |
|---|---|---|
| (i) | ≥ 0.85 | v1.1 rule confirmed; no catalogue change |
| (ii) | 0.75 ≤ x < 0.85 | v1.1 rule confirmed; add note quantifying reclassified rows |
| (iii) | < 0.75 | v1.1 rule did NOT close the seam; substantive paper-text revision |
