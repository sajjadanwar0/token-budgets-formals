# Cluster codebook v2 — 8 mechanism clusters (sharpened)

**Why v2.** A first coding round showed agreement was high for most clusters but
broke on three boundaries: (1) retry-loop vs delegation-fanout, (2) over-use of
budget-primitive-missing as a catch-all, and (3) storage-amplification vs
providerOptions-silently-dropped. v2 keeps the same eight clusters but adds a
deterministic decision procedure (§2) and three boundary clinics (§3) that make
those distinctions explicit. The definitions were sharpened to resolve genuine
under-specification — not to favour any prior answer.

**Read first.** Code each issue by reading the actual GitHub thread, then apply
§2 top-to-bottom; the first rule that matches is the cluster. Use §3 when you
are torn between two clusters. **All examples below are illustrative inventions,
not catalog rows** — they teach the boundary; they are not answers to any row.

You assign **exactly one** cluster per row: the *primary/root* cost mechanism —
the one that, if removed, stops the overrun.

---

## 1. The eight clusters (one defining feature each)

| Cluster | The one thing that defines it |
|---|---|
| `M-retry-loop` | A **single** agent/chain **repeats** calls (retry, recursion, re-plan, loop). |
| `M-delegation-fanout` | **Multiple** agents/sub-agents/delegated tasks consume budget **in aggregate**. |
| `M-context-amplification` | The **prompt/context sent each call** grows (in-flight window). |
| `M-storage-amplification` | **Persisted/accumulated state** (memory, logs, saved history) grows across calls. |
| `M-multimodal-cost-amplification` | A **non-text modality** (image/base64/audio/video) drives the tokens. |
| `providerOptions-silently-dropped` | A **specific user-set config/provider option is ignored/dropped** as the root cause. |
| `M-cost-observability` | Cost is **invisible or mis-accounted** — you cannot see/track/compute spend. |
| `M-budget-primitive-missing` | **No cap/limit capability exists at all** — and no active mechanism above applies (RESIDUAL). |

---

## 2. Decision procedure (apply in order; first match wins)

For each issue, ask in this order and stop at the first YES:

1. **Multimodal?** Is the token blow-up driven by a non-text input (image,
   base64, audio, video)? → `M-multimodal-cost-amplification`.
2. **Fan-out?** Is the cost driven by *more than one* agent / sub-agent /
   delegated task consuming budget together? → `M-delegation-fanout`.
3. **Loop?** Is the cost driven by *one* agent/chain repeating calls
   (retry, recursion, re-planning, stuck loop)? → `M-retry-loop`.
4. **Growing in-flight context?** Is the cost driven by the *prompt sent each
   call* getting bigger (accumulated turns, context-window overflow)? →
   `M-context-amplification`.
5. **Growing stored state?** Is the cost driven by *persisted* state (a memory
   store, log, saved history, vector store) growing and being re-read/re-billed
   across calls? → `M-storage-amplification`.
6. **Dropped option?** Is the root cause a *specific config/provider option the
   user set that the framework silently ignored*? → `providerOptions-silently-dropped`.
7. **Can't see spend?** Is the incident fundamentally that cost is *not visible
   or wrongly computed* (missing usage in callbacks, no cost logging)? →
   `M-cost-observability`.
8. **Nothing above fits?** Then the incident is fundamentally that *no budget/cap
   capability exists* (typically a feature request for a limit), with no active
   mechanism above. → `M-budget-primitive-missing`.

Rule 8 is the **residual / last resort**. If any of rules 1–7 matched, do NOT
use budget-primitive-missing — see Clinic B.

---

## 3. Boundary clinics

### Clinic A — retry-loop (one repeats) vs delegation-fanout (many run)

**Discriminator:** *Count the actors.* If the budget is burned by **one** agent
or chain going around again and again, it is **retry-loop**. If it is burned by
**several** agents / sub-agents / delegated tasks each spending, it is
**delegation-fanout**.

- DON'T code an incident as delegation-fanout just because the framework is a
  multi-agent one (CrewAI, AutoGen, a "crew"/"swarm"). A *single* agent looping
  inside a multi-agent framework is still **retry-loop**.
- DON'T code as retry-loop just because sub-agents each happen to retry. If the
  cost scales with the *number of sub-agents/branches*, it is **delegation-fanout**.

*Illustrative:* "One planner agent keeps re-calling the model because a tool
keeps failing, until the recursion limit" → retry-loop (one actor, repeating).
"A supervisor spawns 12 worker agents in parallel and their combined calls blow
the budget" → delegation-fanout (many actors, in aggregate).

### Clinic B — when NOT to use budget-primitive-missing

Almost every incident in this catalog "would have been prevented by a budget
cap." That is the catalog's whole premise — so *lacking a cap is not a
distinguishing feature.* Use `M-budget-primitive-missing` **only** when, after
rules 1–7, there is **no active runtime mechanism** and the incident *is* the
absence of the capability (e.g., a clean feature request: "please add a
per-session spend limit," with no loop/context/fan-out/etc. described).

- DON'T choose budget-primitive-missing because "if there were a cap this
  wouldn't have happened." That is true of nearly every row; code the **active
  mechanism** instead.
- DO choose it when the thread describes no active driver — only that the
  framework has no way to set or enforce a limit.

*Illustrative:* "Agent loops on a failing query until \$200 is spent" →
retry-loop (active mechanism), NOT budget-primitive-missing — even though a cap
would have helped. "Open issue: 'There is no option anywhere to cap total cost
per run; can we add one?'" with no specific failure described → budget-primitive-missing.

### Clinic C — storage-amplification vs providerOptions-silently-dropped (and vs context)

These three describe different roots:

- **context-amplification** = the *current request's context window* grows.
- **storage-amplification** = a *persisted store* (memory/log/history/vector DB)
  grows across calls and is re-read or re-billed.
- **providerOptions-silently-dropped** = a *user-set option/config was ignored*
  by the framework, and that is the root cause.

**Root-cause rule for dual cases.** Some incidents involve a dropped option that
*then* causes a storage/embedding cost. Code the **root**, not the symptom:

- If the thread is fundamentally "I set option X and the framework didn't honour
  it, so cost went wrong" → `providerOptions-silently-dropped` (the cost is the
  downstream symptom).
- If the thread is fundamentally "stored/accumulated state grew and cost scaled,"
  with no specific ignored option → `M-storage-amplification`.
- If after reading the thread both genuinely apply equally, pick the one the
  reporter treats as the bug, and **record the runner-up in your note**. Do not
  agonise — flagging the tie is what we want.

*Illustrative:* "Each turn re-sends the whole growing transcript, hitting max
context" → context-amplification (in-flight window). "The conversation memory
store keeps every message forever and re-embeds all of it on each query" →
storage-amplification (persisted, re-read). "I passed `dimensions: 256` in
providerOptions but the framework ignored it and embedded at 1536, tripling
cost" → providerOptions-silently-dropped (a set option was dropped; the cost is
the symptom).

---

## 4. Genuine ambiguity

If two clusters still fit equally after §2 and §3, choose the one that comes
**first in the §2 order**, and write `TIE: <other cluster> — <one-line reason>`
in `rater_b_note`. These flags are used later to identify genuinely borderline
incidents and to report them honestly; they are not failures.

If an issue is unreachable, enter `INACCESSIBLE` and move on.

---

## 5. Output

One cluster per row in `rater_b_cluster` (copy the exact string from §1). Optional
`rater_b_note` for ties/uncertainty. **One coder, one code per row** — no A/B/C,
no majority, no "correct", no second-guessing against anyone else's labels. Code
independently from the issues; that independence is the whole point.