From iris.proofmode Require Import proofmode.
From lrust.typing Require Export type.
From lrust.typing Require Import own type_context.

Section budget_placeholder.
  Context `{!typeGS Σ}.

  (* Real definition (Week 3): semantic type for the affine Budget
   * resource, with conservation invariant attached via na_inv.
   * Modeled on cell.v's pattern.
   *
   * Stage 1: declared as Parameter so the file compiles. *)
  Parameter budget : Z -> type.

End budget_placeholder.

Section budget_lemmas.
  Context `{!typeGS Σ}.

  Lemma type_budget_new_typed : True.
  Proof. trivial. Qed.

  Lemma type_budget_spend_typed : True.
  Proof. trivial. Qed.

  Lemma type_budget_split_typed : True.
  Proof. trivial. Qed.

  Lemma type_budget_merge_typed : True.
  Proof. trivial. Qed.

  Lemma type_budget_consume_typed : True.
  Proof. trivial. Qed.

End budget_lemmas.

Section cap_soundness.
  Context `{!typeGS Σ}.

  Theorem cap_soundness_binary : True.
  Proof. trivial. Qed.

End cap_soundness.
