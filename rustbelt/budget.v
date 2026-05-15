(* budget.v — STAGE 1: minimal compiling stub
 *
 * All real content (semantic type definition + per-method proofs) is
 * replaced with Parameter declarations as Day-1 placeholders. The
 * structure of the file is preserved; the actual definitions and
 * proofs will be filled in during Week 3 onward, after reading
 * theories/typing/lib/cell.v and theories/typing/lib/mutex/mutex.v.
 *
 * The file's purpose at this stage is to verify the Coq + Iris +
 * RustBelt environment is correctly configured by importing the
 * relevant lambda-rust modules and accepting them.
 *
 * Status: COMPILES with placeholder declarations. Conjecture 1 is
 * NOT closed by this file as currently written; that work begins
 * in Week 3.
 *)

From iris.proofmode Require Import proofmode.
From lrust.typing Require Export type.
From lrust.typing Require Import own type_context.

(* ====================================================================== *)
(* SECTION 1: Semantic-type placeholder                                    *)
(* ====================================================================== *)

Section budget_placeholder.
  Context `{!typeGS Σ}.

  (* Real definition (Week 3): semantic type for the affine Budget
   * resource, with conservation invariant attached via na_inv.
   * Modeled on cell.v's pattern.
   *
   * Stage 1: declared as Parameter so the file compiles. *)
  Parameter budget : Z -> type.

End budget_placeholder.

(* ====================================================================== *)
(* SECTION 2: Per-method typing lemmas (statements only)                   *)
(* ====================================================================== *)

Section budget_lemmas.
  Context `{!typeGS Σ}.

  (* Real statement (Week 3): the constructor produces a budget B0
   * from a u64 with value B0. *)
  Lemma type_budget_new_typed : True.
  Proof. trivial. Qed.

  (* Real statement (Week 4): spend's typing rule. The central
   * lemma; ~200 lines of Coq when discharged. *)
  Lemma type_budget_spend_typed : True.
  Proof. trivial. Qed.

  Lemma type_budget_split_typed : True.
  Proof. trivial. Qed.

  Lemma type_budget_merge_typed : True.
  Proof. trivial. Qed.

  Lemma type_budget_consume_typed : True.
  Proof. trivial. Qed.

End budget_lemmas.

(* ====================================================================== *)
(* SECTION 3: Cap-soundness theorem (Conjecture 1)                         *)
(* ====================================================================== *)

Section cap_soundness.
  Context `{!typeGS Σ}.

  (* Real statement (Week 6): cap-soundness at the binary level.
   * Closes Conjecture 1 of the Token Budgets paper. *)
  Theorem cap_soundness_binary : True.
  Proof. trivial. Qed.

End cap_soundness.

(* ====================================================================== *)
(* PROOF OBLIGATIONS THAT REMAIN (filled in Weeks 3-7):                    *)
(*                                                                         *)
(*   Week 3:                                                               *)
(*     - Replace `Parameter budget` with real Program Definition           *)
(*     - Discharge type-record obligations                                 *)
(*     - Replace type_budget_new_typed with real signature + proof         *)
(*                                                                         *)
(*   Week 4:                                                               *)
(*     - type_budget_spend_typed (THE central proof, ~200 lines)           *)
(*                                                                         *)
(*   Week 5:                                                               *)
(*     - type_budget_split_typed, _merge_typed, _consume_typed             *)
(*                                                                         *)
(*   Week 6:                                                               *)
(*     - cap_soundness_binary (composes the above by induction)            *)
(* ====================================================================== *)
