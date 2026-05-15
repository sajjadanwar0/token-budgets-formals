# Week 1 Reading Guide

The goal of Week 1 is **vocabulary**, not mastery. By Day 7 you should be able to read a RustBelt proof and follow what it does, even if you couldn't write one from scratch yet. Mastery comes in Week 3 when you start writing.

For each reading below, answer the verification questions in plain text (post them back to me and I'll cross-check your understanding). Don't move to the next reading until you can answer the current one's questions.

---

## Day 1 (after `day1_setup.sh` completes)

**Action:** run `day1_exercises.v` through `coqc`. All 5 must pass. If any fail, fix the environment.

**Verification:** post the output of `coqc theories/typing/lib/day1_exercises.v`. Should be silent (no output) if all 5 prove.

---

## Day 2-3: Software Foundations Vol 1, chapters Logic + Tactics

**URL:** https://softwarefoundations.cis.upenn.edu/lf-current/Logic.html

Skim — don't do every exercise. Goal: comfort with the Coq tactic language.

**Verification questions:**
1. What's the difference between `intros H` and `destruct H`?
2. What does `induction n` produce as goals?
3. When would you use `apply` vs `rewrite`?

---

## Day 4-5: Iris tutorial

**URL:** https://iris-project.org/tutorial-pdfs/iris-lecture-notes.pdf

Read sections 1-4 (skip the rest for now). Focus:
- Section 2: The Iris proposition `iProp Σ`
- Section 3: Persistent vs ephemeral propositions
- Section 4: The `iIntros`, `iApply`, `iSplit`, `iExists` tactics

**Verification questions:**
1. What does the `Σ` (capital sigma) parameter on `iProp Σ` represent?
2. What's the difference between `P ∗ Q` (separating conjunction) and `P ∧ Q` (regular conjunction) in Iris?
3. Why does `iApply "H"` work for a hypothesis `H` but you'd need `iSpecialize` for some specialization patterns?
4. What's the meaning of `□ P` (the persistence modality)?

---

## Day 6: RustBelt's `theories/typing/own.v`

This is the foundational file. Don't read every line — focus on:

- Lines 1-50: imports and the `type` record definition
- The `Definition own_ptr` (the heart of RustBelt's ownership)
- The `own_subtype` lemma
- The `tctx_extract_own` family

**Verification questions:**
1. What are the three fields of the `type` record? (Hint: `ty_size`, `ty_own`, `ty_shr`)
2. What is `ty_own tid vl`? What do `tid` and `vl` represent?
3. What is `ty_shr κ tid l`? Why does `Budget` set this to `False`?

---

## Day 7: RustBelt's `theories/typing/lib/cell.v`

`Cell<T>` is structurally similar to `Budget`: single ownership, mutable state, conservation invariant per operation. Read it end-to-end. It's ~250 lines.

Focus: how `cell_set` types under the typing rules. This is the closest existing analogue to `Budget::spend`'s success branch.

**Verification questions:**
1. What's the type definition of `cell ty`? What does it look like as a Coq term?
2. How does `cell_set` mutate the cell while preserving the invariant?
3. What lemma does `cell_set`'s proof apply to extract the typing context for the new value?
4. (Hardest:) why does `Cell` not have a `Sync` instance?

---

## Day 7 evening: write up your understanding

Post back:
1. The output of `coqc day1_exercises.v` (should be silent)
2. Your answers to the verification questions above
3. Any specific concept that's still fuzzy

I'll then either:
- Confirm you're ready for Week 2 (read `mutex.v`, `type_context.v`, `at_borrow.v`)
- Spend a turn unblocking specific concept gaps

This is the right pace. **Resist** the urge to jump ahead and start writing `budget.v` proofs in Week 1. Without the vocabulary you'll waste days on errors that are obvious with the vocabulary.

---

## What "ready for Week 2" looks like

You should be able to do these without consulting tutorials:
- Read an Iris Hoare triple `{P} e {Q}` and explain what `P` and `Q` are
- Read `iIntros "[H1 H2]"` and know it's destructuring a `∗`
- Look at `tctx_extract_own` (in own.v) and explain what it extracts
- Sketch (in English) why `Cell` can't be `Sync`

If yes: Week 2 starts. If no: another day on whichever concept is fuzzy.
