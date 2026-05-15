# Closing Conjecture 1: Week-by-Week Plan

## Overall calendar budget
- **8 weeks** if you've never used Coq/Iris before (recommended assumption)
- **4 weeks** if RustBelt-experienced (does not apply to you currently)
- Add **20-30%** for Coq proof-engineering surprises (genuinely common, not pessimism)

## Skill gap to close

You currently have:
- Strong Rust ownership semantics intuition
- TLA+ / TLAPS proof experience (you've done 497 obligations on Budget already)
- Dafny experience (similar Hoare-triple style as Coq's specifications)
- No Iris / λ_Rust / RustBelt experience

The TLA+ and Dafny background helps. The Iris/RustBelt-specific concepts that take time:
- `iProp Σ`: the Iris proposition monad (similar to TLA+'s actions, but operationally)
- Ghost state and the resource algebra (no analogue in TLA+; hardest concept to grasp)
- The `tctx` typing context (no analogue in Dafny; how RustBelt threads ownership)
- ssreflect tactics (`move:`, `apply:`, `rewrite`); different style from Dafny

## Week 1: Coq + Iris foundations
**Goal:** be able to read Iris proofs and write small ones.

- Day 1-2: Software Foundations Vol 1 (Coq basics) — fast-skim, do exercises in chapters Logic and Tactics
- Day 3-4: Iris tutorial — `iris.dev/tutorial`. Work through `heap_lang_tutorial.v` end-to-end
- Day 5-7: RustBelt environment setup; first build of the lambda-rust repo; navigate the codebase

**Milestone:** can prove a small Iris Hoare triple about a simple imperative program (e.g., a counter increment) without consulting tutorials.

## Week 2: RustBelt-specific machinery
**Goal:** understand how RustBelt encodes ownership, lifetimes, and types.

- Day 1-2: read `theories/typing/own.v` carefully
- Day 3-4: read `theories/typing/lib/cell.v` end-to-end
- Day 5-6: read `theories/typing/lib/mutex.v`, focusing on `na_inv` patterns
- Day 7: read `theories/typing/type_context.v`, focusing on the `tctx_extract_*` API

**Milestone:** can explain how `Cell::set` discharges its conservation invariant in Coq, naming each lemma it invokes.

## Week 3: Budget semantic type
**Goal:** complete Section 1 of `budget.v`.

- Day 1: write `budget_inv` and `Definition budget`. Discharge the three `Next Obligation` proofs.
- Day 2: prove `budget_proper` and `budget_send`. Verify `budget` does not type-check as `Copy`.
- Day 3-4: prove `type_budget_new_typed`. Reference `theories/typing/int.v` for `int` construction patterns.
- Day 5-7: write skeleton goal statements for the remaining methods (spend, split, merge, consume, cap_soundness_binary).

**Milestone:** `budget.v` builds with the semantic type and constructor proved; per-method theorems Admitted but well-stated.

## Week 4: Spend (the central method)
**Goal:** complete Section 3 of `budget.v` — the spend lemma.

This is the largest single proof (~200 lines). Allow the full week.

- Day 1: case-split on `amount <=? v`. Establish post-conditions in both branches.
- Day 2-3: success branch. Show conservation `0 <= v - amount <= B0`. Construct the new Budget.
- Day 4-5: closure-call boundary. Use `type_call_typed` from `theories/typing/function.v` and adapt the `mutex.v` lock-release pattern to Budget's spend-and-then-call structure.
- Day 6-7: insufficient branch. Trivial conservation. Wire up `Result::Err` construction.

**Milestone:** `type_budget_spend_typed` discharged (no Admitted in the proof).

**Risk:** the closure-call boundary is the part Prusti cannot handle. RustBelt CAN handle it, but the proof will be intricate. Budget for stuck-on-this for 1-2 days; consult Iris Slack if needed (link: `iris.systems`).

## Week 5: Split, merge, consume
**Goal:** complete Section 4 of `budget.v`.

These are mechanical given `spend` is done.

- Day 1-2: `type_budget_split_typed` (~100 lines)
- Day 3-4: `type_budget_merge_typed` (~100 lines)
- Day 5: `type_budget_consume_typed` (~50 lines)
- Day 6-7: regression — re-build everything, fix any incremental breakage

**Milestone:** All per-method lemmas discharged.

## Week 6: Cap-soundness theorem
**Goal:** complete Section 5 of `budget.v`.

The proof composes the per-method lemmas by induction over evaluation traces.

- Day 1-2: state the theorem precisely. Define `total_spent sigma` as the sum of successful spend amounts in the evaluation trace.
- Day 3-5: induction over the program structure, invoking each per-method lemma.
- Day 6-7: edge cases (constructor case, intermediate states, multi-step traces).

**Milestone:** `cap_soundness_binary` discharged. **Conjecture 1 closes.**

## Week 7: Documentation + paper integration
**Goal:** the proof is written; now make it usable.

- Day 1-2: clean up the file, add comments explaining each non-trivial step.
- Day 3-4: write the paper appendix that walks through the structure (this replaces the current Appendix A's "discharge obligations" sketch with the actual proof exposition).
- Day 5-7: regression testing. Build the entire RustBelt repo with your `budget.v` included. Confirm no breakage.

**Milestone:** Paper section ready to integrate.

## Week 8: Buffer + revision
- Inevitable Coq proof-engineering surprises
- Re-write parts of the proof for clarity
- Submit to the Iris/RustBelt mailing list for peer review (the community is responsive and will catch errors)

## Risk mitigation

**Risk: stuck on the closure-call boundary in Week 4.**
*Mitigation:* RustBelt's `mutex.v` is the closest existing analogue; transcribe its lock-release pattern verbatim and adapt. If still stuck after 2 days, post on iris.dev/contact with the specific obligation that won't discharge.

**Risk: discovering a metatheoretic gap.**
*Probability:* low. The `Cell` and `Mutex` proofs in RustBelt's library establish that affine resources with conservation invariants type-check; Budget is structurally similar. If you find one, that itself is a publishable result.

**Risk: time overrun on a contract.**
*Mitigation:* publish the partially-mechanized proof as a preprint addendum to the Token Budgets paper at the 6-week mark, with the remaining 2 weeks of work documented as in-progress. Top venues accept "mechanized in ongoing work" framing if the gap is well-defined.

## Tools you'll want

- **CoqIDE** or **Proof General** (Emacs mode) for proof development
- **Coq Platform** for a stable Coq + library installation
- **GitHub Codespaces** or local Docker if you want a clean reproducible environment

## Cost

- $0 if you do this yourself
- $0 if you collaborate with an Iris-experienced researcher (the Iris community is collaborative; reach out to Ralf Jung's or Robbert Krebbers' research groups)
- $5,000-$15,000 if you pay a consultant for ~2 months of part-time mechanization work

## How this changes the paper

Once `budget.v` builds with no Admitted, the paper updates:

1. **Conjecture 1 → Theorem 2.** Promote the conjecture to a theorem with the mechanized reference.

2. **Appendix A** is replaced with a 2-3 page summary of the proof structure (the Coq file lives in the artifact, not the paper).

3. **Abstract** gains a sentence: "Cap-soundness is mechanically verified at the binary level via a RustBelt embedding (Coq, ~600 lines)."

4. **Threats to validity** loses the "trusted constructor + binary-level conjecture" caveat, replaced with just "trusted constructor."

5. **Venue prognosis shifts:** PLDI/OOPSLA/TOPLAS go from 10-20% to 35-50%. The paper becomes a top-PL-venue submission, not a top-SE-venue submission.

This is the single biggest leverage point for the paper's acceptance probability at top venues.
