# Codebook v1.2 — Mechanism-cluster coding for inter-rater reliability

**Purpose.** This codebook governs assignment of a *single primary
mechanism cluster* to each retained catalog row, so that two raters can
code independently and Cohen's kappa can be computed. It supersedes the
mechanism list in `codebook_v1.md` §6, which had drifted from the tags
actually used in `catalogue.csv` (see "Reconciliation" below).

---

## 0. Reconciliation note (read first)

`codebook_v1.md` §6 listed: `M-retry-loop, M-delegation-fanout,
M-context-amplification, M-reasoning-token-leak, M-cost-observability,
M-rate-limit-amplification, M-feature-gap, M-other`.

The tags actually present in `catalogue.csv` (and cited in the paper
body) are different. The canonical eight below are the top eight by
frequency in the committed catalog and are the authoritative set for
this study. `M-reasoning-token-leak`, `M-feature-gap`, and the long
tail of one-off strings (`M-call`, `M-processed`, `M-category`, …) are
regex artifacts or near-empty and are NOT clusters; they fold into the
canonical eight or into `M-other` per the rules below.

---

## 1. The eight canonical clusters (controlled vocabulary)

A rater MUST assign exactly one of these nine values
(eight clusters + one escape hatch):

| Code | One-line definition |
|---|---|
| `M-delegation-fanout` | A parent agent spawns sub-agents (or recurses) without a bounded delegation budget, so cost multiplies with fan-out depth/width. |
| `M-retry-loop` | The agent re-issues a call after an error/empty result **without changing the input**, so conversation/history grows monotonically. |
| `M-context-amplification` | Each step's input grows superlinearly with accumulated context (repo-map, RAG retrieval, compaction artifacts, summary re-injection). |
| `M-storage-amplification` | Persisted artifacts (chat history, vector memory, cache, scratch files) inflate the token bill on later calls. |
| `M-multimodal-cost-amplification` | Image/audio/video/document tokenization blows up cost in a way the caller did not anticipate. |
| `M-rate-limit-amplification` | Rate-limit retry logic re-sends increasing context, amplifying cost beyond a single call. |
| `M-cost-observability` | The framework's cost ledger silently miscounts or reports `$0.00`, so spend is real but invisible to the operator. |
| `M-budget-primitive-missing` | **Residual / default.** No specific dynamic mechanism above is the root driver; the issue is simply that no budget/cost-cap primitive exists to stop spend. |
| `M-other` | A documented mechanism that fits none of the above. **Selecting this flags a possible taxonomy gap** — log it; if >~5% of rows land here, the taxonomy is incomplete (a saturation signal). |

---

## 2. Single-primary precedence rule (the critical rule)

Many rows exhibit more than one mechanism. To force a single label,
assign the cluster of the **root cost driver**: the mechanism that, if
removed, would prevent the overrun. When two apply equally, break the
tie by this fixed precedence (highest first):

```
1. M-delegation-fanout          (structural multiplier dominates)
2. M-retry-loop
3. M-context-amplification
4. M-storage-amplification
5. M-multimodal-cost-amplification
6. M-rate-limit-amplification
7. M-cost-observability         (a contributing, not root, driver)
8. M-budget-primitive-missing   (residual: assign ONLY when none of 1–7 is the root driver)
   then M-other
```

**Why `M-budget-primitive-missing` is last.** Nearly every row in the
catalog is "budget-primitive-missing" at the *union* level — that is the
paper's invariant claim. As a *cluster* it is therefore the residual
bucket: use it only when no specific dynamic mechanism (1–7) is the root
driver. This keeps the union claim and the cluster partition distinct.

---

## 3. Coding procedure (per row)

1. Open the issue at `short_url`. Read the **issue body and the comment
   thread in full**. Do NOT code from the `notes` column or the title
   alone — the notes contain the author's own answer.
2. Identify the root cost driver (the mechanism whose removal prevents
   the overrun).
3. Assign exactly one code from §1 using the precedence rule in §2.
4. Write a one-sentence rationale naming the evidence in the thread.
5. If you select `M-other`, additionally write what new cluster it
   would imply.

---

## 4. Exemplars (anchor cases)

- `M-delegation-fanout`: CRAI-001 (CrewAI sub-agent fan-out), CDXL-001.
- `M-retry-loop`: LANG-001 (text-to-SQL retry, history grows), CCDE-001.
- `M-context-amplification`: AIDR-004 (repo-map growth).
- `M-cost-observability`: LANG-006 / LANG-007 (`$0.00` attribution despite real spend).
- `M-budget-primitive-missing` (residual): AGPT-001/002 (no cap primitive; no specific dynamic driver).

*(Replace/extend these once rater-A canonical labels are finalized; an
exemplar must not be one of the rows being scored.)*