From iris.proofmode Require Import proofmode.
From iris.base_logic Require Import invariants.
From iris.heap_lang Require Import lang notation proofmode.

From Top Require Import BudgetAbstract.
From Top Require Import BudgetIris.
From Top Require Import BudgetIrisTypedCap.
From Top Require Import BudgetTraceRefinementPure.

Set Default Proof Using "Type".

Section budget_iris_trace_refinement.
Context `{!heapGS Σ}.

Lemma wp_spend_cap_preserves_value_bound (MAX : Z) (l : loc) (v r : Z) :
  (0 ≤ r)%Z →
  {{{ budget_inv_cap MAX l v }}}
    spend_fn #l #r
  {{{ (success : bool) (l' : loc) (v' : Z), RET (#success, #l');
      ⌜(0 ≤ v' ≤ MAX)%Z⌝ ∗
      ((⌜success = true⌝ ∗ ⌜v' = (v - r)%Z⌝ ∗ ⌜(r ≤ v)%Z⌝ ∗ ⌜l' = l⌝ ∗
        budget_inv_cap MAX l' v')
       ∨
       (⌜success = false⌝ ∗ ⌜v' = v⌝ ∗ ⌜(v < r)%Z⌝ ∗
        budget_inv_cap MAX l v))
  }}}.
Proof.
  iIntros (Hr Φ) "Hc HΦ".
  iDestruct "Hc" as "(Hl & %Hv & %HA2)".
  iApply (wp_spend with "Hl").
  iIntros "!>" (success l') "[Hsucc | Hfail]".
  - (* success: new value is v - r ∈ [0, MAX] *)
    iDestruct "Hsucc" as "(%Hs & %Hrv & Hl' & %Hl'eq)".
    iApply ("HΦ" $! success l' (v - r)%Z).
    iSplitR; [iPureIntro; lia|].
    iLeft. iFrame "Hl'". iPureIntro.
    split_and!; (assumption || lia).
  - (* failure: value unchanged, still v ∈ [0, MAX] *)
    iDestruct "Hfail" as "(%Hs & %Hvr & Hl)".
    iApply ("HΦ" $! success l' v).
    iSplitR; [iPureIntro; lia|].
    iRight. iFrame "Hl". iPureIntro.
    split_and!; (assumption || lia).
Qed.

Lemma wp_consume_cap_preserves_value_bound (MAX : Z) (l : loc) (v : Z) :
  {{{ budget_inv_cap MAX l v }}}
    consume_fn #l
  {{{ RET #v;
      ⌜(0 ≤ 0 ≤ MAX)%Z⌝ ∗ budget_inv_cap MAX l 0%Z
  }}}.
Proof.
  iIntros (Φ) "Hc HΦ".
  iDestruct "Hc" as "(Hl & %Hv & %HA2)".
  iApply (wp_consume with "Hl").
  iIntros "!> Hl".
  iApply "HΦ".
  iSplitR; [iPureIntro; lia|].
  iFrame "Hl". iPureIntro. split; [lia|assumption].
Qed.

End budget_iris_trace_refinement.