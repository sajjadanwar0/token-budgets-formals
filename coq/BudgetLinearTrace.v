From Coq Require Import Arith Lia List Bool.
Import ListNotations.

From Top Require Import BudgetAbstract.

Definition budget_id := nat.
Definition linear_state := list (budget_id * nat).

Inductive op : Type :=
| OpSpend   : budget_id -> nat -> op
| OpSplit   : budget_id -> budget_id -> nat -> op
| OpMerge   : budget_id -> budget_id -> op
| OpConsume : budget_id -> op.

Definition sum_of (s : linear_state) : nat :=
  fold_right (fun bv acc => snd bv + acc) 0 s.

Fixpoint lookup (b : budget_id) (s : linear_state) : option nat :=
  match s with
  | [] => None
  | (b', v) :: rest =>
      if Nat.eqb b b' then Some v else lookup b rest
  end.

Fixpoint update (b : budget_id) (v : nat) (s : linear_state) : linear_state :=
  match s with
  | [] => []
  | (b', v') :: rest =>
      if Nat.eqb b b' then (b', v) :: rest else (b', v') :: update b v rest
  end.

Fixpoint remove_id (b : budget_id) (s : linear_state) : linear_state :=
  match s with
  | [] => []
  | (b', v') :: rest =>
      if Nat.eqb b b' then rest else (b', v') :: remove_id b rest
  end.

Definition fresh (b : budget_id) (s : linear_state) : Prop :=
  lookup b s = None.

Definition exec_op (s : linear_state) (o : op) : option linear_state :=
  match o with
  | OpSpend b r =>
      match lookup b s with
      | Some v => if Nat.leb r v then Some (update b (v - r) s) else None
      | None => None
      end
  | OpSplit b b' a =>
      if Nat.eqb b b' then None
      else
        match lookup b s with
        | Some v =>
            if Nat.leb a v then
              match lookup b' s with
              | Some _ => None
              | None => Some ((b', a) :: update b (v - a) s)
              end
            else None
        | None => None
        end
  | OpMerge b1 b2 =>
      if Nat.eqb b1 b2 then None
      else
        match lookup b1 s, lookup b2 s with
        | Some v1, Some v2 => Some (update b1 (v1 + v2) (remove_id b2 s))
        | _, _ => None
        end
  | OpConsume b =>
      match lookup b s with
      | Some _ => Some (remove_id b s)
      | None => None
      end
  end.

Fixpoint exec_trace (s : linear_state) (ops : list op) : option linear_state :=
  match ops with
  | [] => Some s
  | o :: rest =>
      match exec_op s o with
      | Some s' => exec_trace s' rest
      | None => None
      end
  end.

Fixpoint charged_of (s : linear_state) (ops : list op) : nat :=
  match ops with
  | [] => 0
  | OpSpend b r :: rest =>
      match lookup b s with
      | Some v => if Nat.leb r v then
                    r + charged_of (update b (v - r) s) rest
                  else 0
      | None => 0
      end
  | OpSplit b b' a :: rest =>
      if Nat.eqb b b' then 0
      else
        match lookup b s with
        | Some v =>
            if Nat.leb a v then
              match lookup b' s with
              | Some _ => 0
              | None => charged_of ((b', a) :: update b (v - a) s) rest
              end
            else 0
        | None => 0
        end
  | OpMerge b1 b2 :: rest =>
      if Nat.eqb b1 b2 then 0
      else
        match lookup b1 s, lookup b2 s with
        | Some v1, Some v2 => charged_of (update b1 (v1 + v2) (remove_id b2 s)) rest
        | _, _ => 0
        end
  | OpConsume b :: rest =>
      match lookup b s with
      | Some v => v + charged_of (remove_id b s) rest
      | None => 0
      end
  end.

Lemma lookup_in : forall b v s,
    lookup b s = Some v -> In (b, v) s.
Proof.
  intros b v s. induction s as [|[b' v'] rest IH]; simpl; intros H.
  - discriminate.
  - destruct (Nat.eqb b b') eqn:E.
    + apply Nat.eqb_eq in E. subst. inversion H; subst. left; reflexivity.
    + right. apply IH; assumption.
Qed.

Lemma lookup_le_sum : forall b v s,
    lookup b s = Some v -> v <= sum_of s.
Proof.
  intros b v s. induction s as [|[b' v'] rest IH]; simpl; intros H.
  - discriminate.
  - destruct (Nat.eqb b b') eqn:E.
    + apply Nat.eqb_eq in E; subst. inversion H; subst. lia.
    + apply IH in H. lia.
Qed.

Lemma two_lookup_sum_le :
  forall b1 v1 b2 v2 s,
    b1 <> b2 ->
    lookup b1 s = Some v1 ->
    lookup b2 s = Some v2 ->
    v1 + v2 <= sum_of s.
Proof.
  intros b1 v1 b2 v2 s. revert v1 v2.
  induction s as [|[b' v'] rest IH]; intros v1 v2 Hneq H1 H2; simpl in *.
  - discriminate.
  - destruct (Nat.eqb b1 b') eqn:E1.
    + apply Nat.eqb_eq in E1. subst.
      inversion H1; subst.
      destruct (Nat.eqb b2 b') eqn:E2.
      * apply Nat.eqb_eq in E2. subst. contradiction.
      * pose proof (lookup_le_sum b2 v2 rest H2). lia.
    + destruct (Nat.eqb b2 b') eqn:E2.
      * apply Nat.eqb_eq in E2. subst.
        inversion H2; subst.
        pose proof (lookup_le_sum b1 v1 rest H1). lia.
      * pose proof (IH v1 v2 Hneq H1 H2). lia.
Qed.

Lemma update_sum : forall b v_old v_new s,
    lookup b s = Some v_old ->
    sum_of (update b v_new s) = sum_of s - v_old + v_new.
Proof.
  intros b v_old v_new s. induction s as [|[b' v'] rest IH]; simpl; intros H.
  - discriminate.
  - destruct (Nat.eqb b b') eqn:E.
    + apply Nat.eqb_eq in E. subst. inversion H; subst.
      simpl. lia.
    + simpl.
      assert (sum_of (update b v_new rest) = sum_of rest - v_old + v_new) by (apply IH; auto).
      pose proof (lookup_le_sum b v_old rest H) as Hle.
      lia.
Qed.

Lemma remove_id_sum : forall b v s,
    lookup b s = Some v ->
    sum_of (remove_id b s) = sum_of s - v.
Proof.
  intros b v s. induction s as [|[b' v'] rest IH]; simpl; intros H.
  - discriminate.
  - destruct (Nat.eqb b b') eqn:E.
    + apply Nat.eqb_eq in E. subst. inversion H; subst. lia.
    + simpl.
      assert (sum_of (remove_id b rest) = sum_of rest - v) by (apply IH; auto).
      pose proof (lookup_le_sum b v rest H) as Hle.
      lia.
Qed.

Lemma exec_op_sum_charged : forall s o s' ops,
    exec_op s o = Some s' ->
    sum_of s + charged_of s' ops = sum_of s' + charged_of s (o :: ops).
Proof.
  intros s [b r | b b' a | b1 b2 | b] s' ops H.
  -
    cbn in H.
    destruct (lookup b s) as [v|] eqn:Hb; [|discriminate].
    destruct (Nat.leb r v) eqn:Hle_b; [|discriminate].
    inversion H; subst.
    cbn. rewrite Hb, Hle_b.
    apply Nat.leb_le in Hle_b.
    pose proof (lookup_le_sum b v s Hb) as Hsub.
    rewrite (update_sum b v (v - r) s Hb).
    lia.
  -
    cbn in H.
    destruct (Nat.eqb b b') eqn:Heq; [discriminate|].
    destruct (lookup b s) as [v|] eqn:Hb; [|discriminate].
    destruct (Nat.leb a v) eqn:Hle_b; [|discriminate].
    destruct (lookup b' s) eqn:Hb'; [discriminate|].
    inversion H; subst.
    cbn. rewrite Heq, Hb, Hle_b, Hb'.
    apply Nat.leb_le in Hle_b.
    pose proof (lookup_le_sum b v s Hb) as Hsub.
    fold (sum_of (update b (v - a) s)).
    rewrite (update_sum b v (v - a) s Hb).
    cbn. lia.
  -
    cbn in H.
    destruct (Nat.eqb b1 b2) eqn:Heq; [discriminate|].
    destruct (lookup b1 s) as [v1|] eqn:Hb1; [|discriminate].
    destruct (lookup b2 s) as [v2|] eqn:Hb2; [|discriminate].
    inversion H; subst.
    cbn. rewrite Heq, Hb1, Hb2.
    assert (Hlook: lookup b1 (remove_id b2 s) = Some v1).
    { clear -Hb1 Heq.
      induction s as [|[b' v'] rest IH]; cbn in *; [discriminate|].
      destruct (Nat.eqb b2 b') eqn:Eb2.
      - apply Nat.eqb_eq in Eb2. subst.
        destruct (Nat.eqb b1 b') eqn:Eb1.
        + apply Nat.eqb_eq in Eb1. subst.
          pose proof (Nat.eqb_refl b') as Hrefl.
          congruence.
        + exact Hb1.
      - cbn. destruct (Nat.eqb b1 b') eqn:Eb1.
        + exact Hb1.
        + apply IH; assumption.  }
    rewrite (update_sum b1 v1 (v1 + v2) (remove_id b2 s) Hlook).
    pose proof (lookup_le_sum b1 v1 s Hb1) as Hsub1.
    pose proof (lookup_le_sum b2 v2 s Hb2) as Hsub2.
    assert (Hneq : b1 <> b2) by (intro Habs; subst; rewrite Nat.eqb_refl in Heq; discriminate).
    pose proof (two_lookup_sum_le b1 v1 b2 v2 s Hneq Hb1 Hb2) as Hsum_both.
    rewrite (remove_id_sum b2 v2 s Hb2).
    lia.
  -
    cbn in H.
    destruct (lookup b s) as [v|] eqn:Hb; [|discriminate].
    inversion H; subst.
    cbn. rewrite Hb.
    rewrite (remove_id_sum b v s Hb).
    pose proof (lookup_le_sum b v s Hb) as Hsub.
    lia.
Qed.

Lemma exec_trace_sum_charged : forall ops s s',
    exec_trace s ops = Some s' ->
    sum_of s = sum_of s' + charged_of s ops.
Proof.
  induction ops as [|o rest IH]; intros s s' H.
  - cbn in *. inversion H; subst. lia.
  - cbn in H.
    destruct (exec_op s o) as [s_mid|] eqn:Hop; [|discriminate].
    pose proof (exec_op_sum_charged _ _ _ rest Hop) as Hstep.
    apply IH in H.

    lia.
Qed.

Definition initial_linear_state (B0 : nat) : linear_state := [(0, B0)].

Theorem linear_trace_cap_soundness :
  forall B0 ops s_final,
    exec_trace (initial_linear_state B0) ops = Some s_final ->
    charged_of (initial_linear_state B0) ops <= B0.
Proof.
  intros B0 ops s_final H.
  pose proof (exec_trace_sum_charged _ _ _ H) as Hsum.
  unfold initial_linear_state in *. cbn in Hsum.

  lia.
Qed.

Definition abstract_state_of (B0 : nat) (s : linear_state) (charged : nat) : state :=
  {| liveSum := sum_of s;
     outstandingReceipts := 0;
     outstandingRefunds := 0;
     totalCharged := charged;
     totalUnrecoverable := 0;
     totalReleased := B0 - sum_of s - charged |}.

Lemma abstract_state_initial : forall B0,
  abstract_state_of B0 (initial_linear_state B0) 0 = initial B0.
Proof.
  intros B0. unfold abstract_state_of, initial_linear_state, initial.
  cbn. f_equal; lia.
Qed.

Print Assumptions linear_trace_cap_soundness.
