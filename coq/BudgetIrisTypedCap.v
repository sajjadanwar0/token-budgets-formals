From iris.proofmode Require Import proofmode.
From iris.base_logic Require Import invariants.
From iris.heap_lang Require Import lang notation proofmode.

From Top Require Import BudgetAbstract BudgetIris.

Set Default Proof Using "Type".

Section budget_iris_typed_cap.
Context `{!heapGS Σ}.

Definition A2_bound : Z := 9223372036854775808%Z.

Lemma A2_bound_eq : A2_bound = (2 ^ 63)%Z.
Proof. unfold A2_bound. lia. Qed.

Definition budget_inv_cap (MAX : Z) (l : loc) (v : Z) : iProp Σ :=
  (budget_inv l v ∗ ⌜(0 ≤ v ≤ MAX)%Z⌝ ∗ ⌜(MAX < A2_bound)%Z⌝)%I.

Lemma budget_inv_cap_excl MAX l v v' :
  budget_inv_cap MAX l v -∗ budget_inv_cap MAX l v' -∗ False.
Proof.
  iIntros "Hc1 Hc2".
  iDestruct "Hc1" as "(Hl1 & _ & _)".
  iDestruct "Hc2" as "(Hl2 & _ & _)".
  iApply (budget_inv_excl with "Hl1 Hl2").
Qed.

Lemma wp_spend_cap (MAX : Z) (l : loc) (v r : Z) :
  (0 ≤ r)%Z →
  {{{ budget_inv_cap MAX l v }}}
    spend_fn #l #r
  {{{ (success : bool) (l' : loc), RET (#success, #l');
      (⌜success = true⌝ ∗ ⌜(r ≤ v)%Z⌝ ∗ ⌜l' = l⌝ ∗
       budget_inv_cap MAX l' (v - r)%Z)
      ∨
      (⌜success = false⌝ ∗ ⌜(v < r)%Z⌝ ∗ budget_inv_cap MAX l v) }}}.
Proof.
  iIntros (Hr Φ) "Hc HΦ".
  iDestruct "Hc" as "(Hl & %Hv & %HA2)".
  iApply (wp_spend with "Hl").
  iIntros "!>" (success l') "[Hsucc | Hfail]".
  -
    iDestruct "Hsucc" as "(%Hs & %Hrv & Hl' & %Hl'eq)".
    iApply ("HΦ" $! success l').
    iLeft. iFrame "Hl'". iPureIntro.
    split_and!; (assumption || lia).
  -
    iDestruct "Hfail" as "(%Hs & %Hvr & Hl)".
    iApply ("HΦ" $! success l').
    iRight. iFrame "Hl". iPureIntro.
    split_and!; (assumption || lia).
Qed.

Lemma wp_split_cap (MAX : Z) (l : loc) (v a : Z) :
  (0 ≤ a)%Z →
  {{{ budget_inv_cap MAX l v }}}
    split_fn #l #a
  {{{ (success : bool) (l' l'' : loc), RET (#success, #l', #l'');
      (⌜success = true⌝ ∗ ⌜(a ≤ v)%Z⌝ ∗ ⌜l' = l⌝ ∗
       budget_inv_cap MAX l' (v - a)%Z ∗ budget_inv_cap MAX l'' a)
      ∨
      (⌜success = false⌝ ∗ ⌜(v < a)%Z⌝ ∗ budget_inv_cap MAX l v) }}}.
Proof.
  iIntros (Ha Φ) "Hc HΦ".
  iDestruct "Hc" as "(Hl & %Hv & %HA2)".
  iApply (wp_split with "Hl").
  iIntros "!>" (success l' l'') "[Hsucc | Hfail]".
  - iDestruct "Hsucc" as "(%Hs & %Hav & %Hl'eq & Hl' & Hl'')".
    iApply ("HΦ" $! success l' l'').
    iLeft. iFrame "Hl' Hl''". iPureIntro.
    split_and!; (assumption || lia).
  - iDestruct "Hfail" as "(%Hs & %Hva & Hl)".
    iApply ("HΦ" $! success l' l'').
    iRight. iFrame "Hl". iPureIntro.
    split_and!; (assumption || lia).
Qed.

Lemma wp_merge_cap (MAX : Z) (l1 l2 : loc) (v1 v2 : Z) :
  (v1 + v2 ≤ MAX)%Z →
  {{{ budget_inv_cap MAX l1 v1 ∗ budget_inv_cap MAX l2 v2 }}}
    merge_fn #l1 #l2
  {{{ RET #l1; budget_inv_cap MAX l1 (v1 + v2)%Z }}}.
Proof.
  iIntros (Hsum Φ) "[Hc1 Hc2] HΦ".
  iDestruct "Hc1" as "(Hl1 & %Hv1 & %HA2)".
  iDestruct "Hc2" as "(Hl2 & %Hv2 & _)".
  iApply (wp_merge with "[$Hl1 $Hl2]").
  iIntros "!> Hl".
  iApply "HΦ".
  iFrame "Hl". iPureIntro.
  split_and!; (assumption || lia).
Qed.

Lemma wp_consume_cap (MAX : Z) (l : loc) (v : Z) :
  {{{ budget_inv_cap MAX l v }}}
    consume_fn #l
  {{{ RET #v; budget_inv_cap MAX l 0%Z }}}.
Proof.
  iIntros (Φ) "Hc HΦ".
  iDestruct "Hc" as "(Hl & %Hv & %HA2)".
  iApply (wp_consume with "Hl").
  iIntros "!> Hl".
  iApply "HΦ".
  iFrame "Hl". iPureIntro.
  split_and!; (assumption || lia).
Qed.

Theorem budget_iris_typed_cap_closed (MAX : Z) :
  (forall l v r, (0 ≤ r)%Z →
     {{{ budget_inv_cap MAX l v }}} spend_fn #l #r
     {{{ (success : bool) (l' : loc), RET (#success, #l');
         (⌜success = true⌝ ∗ ⌜(r ≤ v)%Z⌝ ∗ ⌜l' = l⌝ ∗
          budget_inv_cap MAX l' (v - r)%Z)
         ∨ (⌜success = false⌝ ∗ ⌜(v < r)%Z⌝ ∗ budget_inv_cap MAX l v) }}}) /\
  (forall l v a, (0 ≤ a)%Z →
     {{{ budget_inv_cap MAX l v }}} split_fn #l #a
     {{{ (success : bool) (l' l'' : loc), RET (#success, #l', #l'');
         (⌜success = true⌝ ∗ ⌜(a ≤ v)%Z⌝ ∗ ⌜l' = l⌝ ∗
          budget_inv_cap MAX l' (v - a)%Z ∗ budget_inv_cap MAX l'' a)
         ∨ (⌜success = false⌝ ∗ ⌜(v < a)%Z⌝ ∗ budget_inv_cap MAX l v) }}}) /\
  (forall l1 l2 v1 v2, (v1 + v2 ≤ MAX)%Z →
     {{{ budget_inv_cap MAX l1 v1 ∗ budget_inv_cap MAX l2 v2 }}}
       merge_fn #l1 #l2
     {{{ RET #l1; budget_inv_cap MAX l1 (v1 + v2)%Z }}}) /\
  (forall l v,
     {{{ budget_inv_cap MAX l v }}} consume_fn #l
     {{{ RET #v; budget_inv_cap MAX l 0%Z }}}).
Proof.
  split_and!.
  - intros. apply wp_spend_cap; assumption.
  - intros. apply wp_split_cap; assumption.
  - intros. apply wp_merge_cap; assumption.
  - intros. apply wp_consume_cap.
Qed.

End budget_iris_typed_cap.
