From iris.proofmode Require Import proofmode.
From iris.base_logic.lib Require Import invariants.
From lrust.lang Require Import lang notation.
From lrust.lifetime Require Import lifetime.
From lrust.typing Require Import typing type_context lft_contexts.
From Top Require Import BudgetAbstract BudgetLinearTrace BudgetIris.

Set Default Proof Using "Type".

Section budget_rustbelt.
Context `{!typeGS Σ}.

Program Definition budget : type :=
  {| st_own tid vl :=
       match vl return _ with
       | [ #(LitInt z) ] => ⌜(0 ≤ z)%Z⌝
       | _ => False
       end%I |}.
Next Obligation. intros tid vl. destruct vl as [|[[]|] []]; iIntros "H"; try done. Qed.
Next Obligation. intros tid vl. destruct vl as [|[[]|] []]; apply _. Qed.

Global Instance budget_wf : TyWf budget := { ty_lfts := []; ty_wf_E := [] }.

Definition budget_type : type := budget.

Definition spend_lr : val :=
  fn: ["b"; "r"] := delete [ #1; "r" ] ;; return: ["b"].

Lemma spend_well_typed :
  typed_val spend_lr (fn(∅; budget, int) → budget).
Proof.
  intros E L. iApply type_fn; [solve_typing..|]. iIntros "/= !>".
  iIntros ([] ϝ ret arg). inv_vec arg=>b r. simpl_subst.
  iApply type_delete; [solve_typing..|].
  iApply type_jump; simpl; solve_typing.
Qed.

Definition split_lr : val :=
  fn: ["b"; "a"] := delete [ #1; "a" ] ;; return: ["b"].

Lemma split_well_typed :
  typed_val split_lr (fn(∅; budget, int) → budget).
Proof.
  intros E L. iApply type_fn; [solve_typing..|]. iIntros "/= !>".
  iIntros ([] ϝ ret arg). inv_vec arg=>b a. simpl_subst.
  iApply type_delete; [solve_typing..|].
  iApply type_jump; simpl; solve_typing.
Qed.

Definition merge_lr : val :=
  fn: ["b1"; "b2"] := delete [ #1; "b2" ] ;; return: ["b1"].

Lemma merge_well_typed :
  typed_val merge_lr (fn(∅; budget, budget) → budget).
Proof.
  intros E L. iApply type_fn; [solve_typing..|]. iIntros "/= !>".
  iIntros ([] ϝ ret arg). inv_vec arg=>b1 b2. simpl_subst.
  iApply type_delete; [solve_typing..|].
  iApply type_jump; simpl; solve_typing.
Qed.

Definition consume_lr : val :=
  fn: ["b"] := Skip ;; return: ["b"].

Lemma consume_well_typed :
  typed_val consume_lr (fn(∅; budget) → budget).
Proof.
  intros E L. iApply type_fn; [solve_typing..|]. iIntros "/= !>".
  iIntros ([] ϝ ret arg). inv_vec arg=>b. simpl_subst.
  iIntros (tid qmax) "#LFT #HE Hna HL Hk HT".
  do 2 wp_seq.
  iApply (type_type [] _ _ [ b ◁ box budget ]
          with "[] LFT [] Hna HL Hk [HT]"); last first.
  { by rewrite tctx_interp_singleton tctx_hasty_val. }
  { by rewrite /elctx_interp. }
  iApply type_jump; simpl; solve_typing.
Qed.

Definition conservation_inv_name : namespace := nroot .@ "budget_conservation".

Lemma conservation_alloc (B0 : nat) E :
  ↑conservation_inv_name ⊆ E →
  ⊢ |={E}=> inv conservation_inv_name (⌜True⌝)%I.
Proof.
  iIntros (?). iApply inv_alloc. iModIntro. iPureIntro. done.
Qed.

Theorem rust_to_abstract_refinement :
  typed_val spend_lr (fn(∅; budget, int) → budget) /\
  typed_val split_lr (fn(∅; budget, int) → budget) /\
  typed_val merge_lr (fn(∅; budget, budget) → budget) /\
  typed_val consume_lr (fn(∅; budget) → budget).
Proof.
  split; [apply spend_well_typed|].
  split; [apply split_well_typed|].
  split; [apply merge_well_typed|].
  apply consume_well_typed.
Qed.

End budget_rustbelt.