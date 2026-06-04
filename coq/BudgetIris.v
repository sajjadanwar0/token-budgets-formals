From iris.proofmode Require Import proofmode.
From iris.base_logic Require Import invariants.
From iris.heap_lang Require Import lang notation proofmode.

From Top Require Import BudgetAbstract.

Set Default Proof Using "Type".

Section budget_iris.
Context `{!heapGS Σ}.

Definition budget_inv (l : loc) (v : Z) : iProp Σ :=
  l ↦ #v.

Definition budget_inv_nat (l : loc) (v : nat) : iProp Σ :=
  budget_inv l (Z.of_nat v).

Lemma budget_inv_excl l v v' :
  budget_inv l v -∗ budget_inv l v' -∗ False.
Proof.
  iIntros "H1 H2".
  iDestruct (pointsto_ne with "H1 H2") as %Hne.
  done.
Qed.

Definition spend_fn : val :=
  λ: "b" "r",
    let: "v" := !"b" in
    if: "v" < "r" then
      (* Insufficient: do not deduct. Return original pointer with
         success=false so the postcondition values line up in both
         branches (l' = l). *)
      (#false, "b")
    else
      "b" <- ("v" - "r");;
      (#true, "b").

Definition split_fn : val :=
  λ: "b" "a",
    let: "v" := !"b" in
    if: "v" < "a" then
      (* Failure: return original pointer twice as dummies. *)
      (#false, "b", "b")
    else
      "b" <- ("v" - "a");;
      let: "child" := ref #0 in
      "child" <- "a";;
      (#true, "b", "child").

Definition merge_fn : val :=
  λ: "b1" "b2",
    let: "v1" := !"b1" in
    let: "v2" := !"b2" in
    "b1" <- ("v1" + "v2");;
    "b1".
    (* In real Rust, b2 would be dropped here. heap_lang lacks
       linear typing so we model the drop implicitly by never
       referring to b2 again. *)

Definition consume_fn : val :=
  λ: "b",
    let: "v" := !"b" in
    "b" <- #0;;
    "v".

Lemma wp_spend (l : loc) (v r : Z) :
  {{{ budget_inv l v }}}
    spend_fn #l #r
  {{{ (success : bool) (l' : loc), RET (#success, #l');
      (⌜success = true⌝ ∗ ⌜(r ≤ v)%Z⌝ ∗ budget_inv l' (v - r)%Z ∗ ⌜l' = l⌝)
      ∨ (⌜success = false⌝ ∗ ⌜(v < r)%Z⌝ ∗ budget_inv l v) }}}.
Proof.
  iIntros (Φ) "Hl HΦ".
  unfold spend_fn, budget_inv.
  wp_pures.
  wp_load.
  wp_pures.
  destruct (decide (v < r)%Z) as [Hlt | Hge].
  - (* Insufficient branch *)
    rewrite bool_decide_true; [|lia].
    wp_pures.
    iApply ("HΦ" $! false l).
    iRight. iFrame "Hl". iPureIntro. split_and!; [done|lia].
  - (* Sufficient branch *)
    rewrite bool_decide_false; [|lia].
    wp_pures.
    wp_store.
    wp_pures.
    iApply ("HΦ" $! true l).
    iLeft. iFrame "Hl". iPureIntro. split_and!; [done|lia|done].
Qed.

Lemma wp_split (l : loc) (v a : Z) :
  {{{ budget_inv l v }}}
    split_fn #l #a
  {{{ (success : bool) (l' l'' : loc), RET (#success, #l', #l'');
      (⌜success = true⌝ ∗ ⌜(a ≤ v)%Z⌝ ∗ ⌜l' = l⌝ ∗
       budget_inv l' (v - a)%Z ∗ budget_inv l'' a)
      ∨ (⌜success = false⌝ ∗ ⌜(v < a)%Z⌝ ∗ budget_inv l v) }}}.
Proof.
  iIntros (Φ) "Hl HΦ".
  unfold split_fn, budget_inv.
  wp_pures.
  wp_load.
  wp_pures.
  destruct (decide (v < a)%Z) as [Hlt | Hge].
  - rewrite bool_decide_true; [|lia].
    wp_pures.
    iApply ("HΦ" $! false l l).
    iRight. iFrame "Hl". iPureIntro. split_and!; [done|lia].
  - rewrite bool_decide_false; [|lia].
    wp_pures.
    wp_store.
    wp_alloc child as "Hchild".
    wp_pures.
    wp_store.
    wp_pures.
    iApply ("HΦ" $! true l child).
    iLeft. iFrame "Hl Hchild". iPureIntro. split_and!; [done|lia|done].
Qed.

(** ** Hoare triple for merge *)

Lemma wp_merge (l1 l2 : loc) (v1 v2 : Z) :
  {{{ budget_inv l1 v1 ∗ budget_inv l2 v2 }}}
    merge_fn #l1 #l2
  {{{ RET #l1; budget_inv l1 (v1 + v2)%Z }}}.
Proof.
  iIntros (Φ) "[Hl1 Hl2] HΦ".
  unfold merge_fn, budget_inv.
  wp_pures.
  wp_load.
  wp_pures.
  wp_load.
  wp_pures.
  wp_store.
  iApply "HΦ". by iFrame.
Qed.

(** ** Hoare triple for consume *)

Lemma wp_consume (l : loc) (v : Z) :
  {{{ budget_inv l v }}}
    consume_fn #l
  {{{ RET #v; budget_inv l 0%Z }}}.
Proof.
  iIntros (Φ) "Hl HΦ".
  unfold consume_fn, budget_inv.
  wp_pures.
  wp_load.
  wp_pures.
  wp_store.
  iApply "HΦ". by iFrame.
Qed.

End budget_iris.