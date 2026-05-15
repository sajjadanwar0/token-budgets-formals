(* day1_exercises.v
 *
 * Day 1 sanity exercises. Drop into your RustBelt clone at
 *   theories/typing/lib/day1_exercises.v
 * and verify each Lemma proves with the suggested tactic.
 *
 * If you can prove all 5, your environment + minimal Iris vocabulary
 * is sufficient to start Week 2 reading. If you can't, fix the gap
 * before moving on.
 *
 * Estimated time: 30-60 minutes for first-time Coq user.
 *)

From iris.proofmode Require Import proofmode.
From iris.base_logic Require Import lib.invariants.

(* ====================================================================== *)
(* Exercise 1: Pure Coq                                                    *)
(* Verify your Coq install works at all.                                   *)
(* ====================================================================== *)

Lemma ex1_pure : forall n : nat, n + 0 = n.
Proof.
  intros n.
  induction n; simpl.
  - reflexivity.
  - rewrite IHn. reflexivity.
Qed.

(* ====================================================================== *)
(* Exercise 2: Trivial Iris proposition                                    *)
(* Verify the Iris proof mode loads.                                       *)
(* ====================================================================== *)

Lemma ex2_iris_pure {Σ} : ⊢ (True : iProp Σ).
Proof. iIntros "". done. Qed.

(* ====================================================================== *)
(* Exercise 3: Conjunction in Iris                                         *)
(* The `iSplit` tactic splits a star.                                      *)
(* ====================================================================== *)

Lemma ex3_iris_conj {Σ} (P Q : iProp Σ) :
  P -∗ Q -∗ P ∗ Q.
Proof.
  iIntros "HP HQ".
  iSplitL "HP".
  - iApply "HP".
  - iApply "HQ".
Qed.

(* ====================================================================== *)
(* Exercise 4: Existential in Iris                                         *)
(* Use iExists to provide a witness.                                       *)
(* ====================================================================== *)

Lemma ex4_iris_exists {Σ} (P : nat -> iProp Σ) :
  P 42 -∗ ∃ n, P n.
Proof.
  iIntros "HP".
  iExists 42.
  iApply "HP".
Qed.

(* ====================================================================== *)
(* Exercise 5: Pure proposition lift                                       *)
(* Iris's `⌜ ... ⌝` lifts a pure Coq proposition into iProp.               *)
(* ====================================================================== *)

Lemma ex5_iris_pure_lift {Σ} :
  ⊢@{iProp Σ} ⌜0 <= 5⌝.
Proof.
  iPureIntro.
  lia.
Qed.

(* ====================================================================== *)
(* If all 5 above prove with `coqc`, you have:                             *)
(*   - working Coq                                                         *)
(*   - working Iris proof mode                                             *)
(*   - basic Iris tactics: iIntros, iApply, iSplit, iExists, iPureIntro    *)
(* These are the minimum vocabulary for Week 2 reading.                    *)
(*                                                                         *)
(* If any FAIL: do not proceed. Fix the environment first. Common issues:  *)
(*   - Wrong Iris version: should be 4.2.0+                                *)
(*   - Missing imports: add the From clauses at the top of this file       *)
(*   - Wrong opam switch: re-run `eval $(opam env --switch=rustbelt)`      *)
(* ====================================================================== *)
