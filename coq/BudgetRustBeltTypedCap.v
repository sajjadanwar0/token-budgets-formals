From iris.proofmode Require Import proofmode.
From iris.base_logic.lib Require Import invariants.

From lrust.lang Require Import lang notation.
From lrust.lifetime Require Import lifetime.
From lrust.typing Require Import typing type_context lft_contexts.

From Top Require Import BudgetAbstract BudgetLinearTrace BudgetIris BudgetRustBelt.

Set Default Proof Using "Type".

Section budget_rustbelt_typed_cap.
Context `{!typeGS Σ}.

Definition A2_bound : Z := 9223372036854775808%Z.

Lemma A2_bound_eq : A2_bound = (2 ^ 63)%Z.
Proof. unfold A2_bound. lia. Qed.

Program Definition budget_max (MAX : Z) : type :=
  {| st_own tid vl :=
       match vl return _ with
       | [ #(LitInt z) ] => ⌜(0 ≤ z ≤ MAX)%Z ∧ (MAX < A2_bound)%Z⌝
       | _ => False
       end%I |}.
Next Obligation.
  intros MAX tid vl. destruct vl as [|[[]|] []]; iIntros "H"; try done.
Qed.
Next Obligation.
  intros MAX tid vl. destruct vl as [|[[]|] []]; apply _.
Qed.

Global Instance budget_max_wf MAX : TyWf (budget_max MAX) :=
  { ty_lfts := []; ty_wf_E := [] }.

Definition budget_type_max (MAX : Z) : type := budget_max MAX.

Definition spend_lr_max : val :=
  fn: ["b"; "r"] := delete [ #1; "r" ] ;; return: ["b"].

Lemma spend_well_typed_max (MAX : Z) :
  typed_val spend_lr_max (fn(∅; budget_max MAX, int) → budget_max MAX).
Proof.
  intros E L. iApply type_fn; [solve_typing..|]. iIntros "/= !>".
  iIntros ([] ϝ ret arg). inv_vec arg=>b r. simpl_subst.
  iApply type_delete; [solve_typing..|].
  iApply type_jump; simpl; solve_typing.
Qed.

Definition split_lr_max : val :=
  fn: ["b"; "a"] := delete [ #1; "a" ] ;; return: ["b"].

Lemma split_well_typed_max (MAX : Z) :
  typed_val split_lr_max (fn(∅; budget_max MAX, int) → budget_max MAX).
Proof.
  intros E L. iApply type_fn; [solve_typing..|]. iIntros "/= !>".
  iIntros ([] ϝ ret arg). inv_vec arg=>b a. simpl_subst.
  iApply type_delete; [solve_typing..|].
  iApply type_jump; simpl; solve_typing.
Qed.

Definition merge_lr_max : val :=
  fn: ["b1"; "b2"] := delete [ #1; "b2" ] ;; return: ["b1"].

Lemma merge_well_typed_max (MAX : Z) :
  typed_val merge_lr_max (fn(∅; budget_max MAX, budget_max MAX) → budget_max MAX).
Proof.
  intros E L. iApply type_fn; [solve_typing..|]. iIntros "/= !>".
  iIntros ([] ϝ ret arg). inv_vec arg=>b1 b2. simpl_subst.
  iApply type_delete; [solve_typing..|].
  iApply type_jump; simpl; solve_typing.
Qed.

Definition consume_lr_max : val :=
  fn: ["b"] := Skip ;; return: ["b"].

Lemma consume_well_typed_max (MAX : Z) :
  typed_val consume_lr_max (fn(∅; budget_max MAX) → budget_max MAX).
Proof.
  intros E L. iApply type_fn; [solve_typing..|]. iIntros "/= !>".
  iIntros ([] ϝ ret arg). inv_vec arg=>b. simpl_subst.
  iIntros (tid qmax) "#LFT #HE Hna HL Hk HT".
  do 2 wp_seq.
  iApply (type_type [] _ _ [ b ◁ box (budget_max MAX) ]
          with "[] LFT [] Hna HL Hk [HT]"); last first.
  { by rewrite tctx_interp_singleton tctx_hasty_val. }
  { by rewrite /elctx_interp. }
  iApply type_jump; simpl; solve_typing.
Qed.

Definition conservation_inv_name_max : namespace := nroot .@ "budget_conservation_max".

Lemma conservation_alloc_max (MAX : Z) (B0 : nat) E :
  ↑conservation_inv_name_max ⊆ E →
  ⊢ |={E}=> inv conservation_inv_name_max (⌜True⌝)%I.
Proof.
  iIntros (?). iApply inv_alloc. iModIntro. iPureIntro. done.
Qed.

Theorem rust_to_abstract_refinement_max :
  forall (MAX : Z),
    typed_val spend_lr_max   (fn(∅; budget_max MAX, int) → budget_max MAX) /\
    typed_val split_lr_max   (fn(∅; budget_max MAX, int) → budget_max MAX) /\
    typed_val merge_lr_max   (fn(∅; budget_max MAX, budget_max MAX) → budget_max MAX) /\
    typed_val consume_lr_max (fn(∅; budget_max MAX) → budget_max MAX).
Proof.
  intros MAX. split_and!.
  - apply spend_well_typed_max.
  - apply split_well_typed_max.
  - apply merge_well_typed_max.
  - apply consume_well_typed_max.
Qed.

End budget_rustbelt_typed_cap.
