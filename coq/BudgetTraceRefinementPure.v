From Coq Require Import ZArith Lia List Bool.
Import ListNotations.
Open Scope Z_scope.

Definition uc := Z.

Definition op_spend (r : Z) : Z -> option Z :=
  fun v => if Z.leb 0 r then
             if Z.leb r v then Some (v - r)%Z else None
           else None.

Definition op_consume : Z -> option Z := fun _ => Some 0%Z.

Fixpoint trace_value_sequence
    (initial : Z) (ops : list (Z -> option Z)) : list Z :=
  match ops with
  | [] => [initial]
  | op :: rest =>
      initial :: (match op initial with
                  | Some next => trace_value_sequence next rest
                  | None => []
                  end)
  end.

Definition trace_cap_safe (MAX : Z) (trace : list Z) : Prop :=
  Forall (fun v => (0 <= v <= MAX)%Z) trace.

Theorem trace_refinement_cap_soundness
    (MAX : Z) (v0 : Z) (ops : list (Z -> option Z)) :
  (0 <= MAX)%Z ->
  (0 <= v0 <= MAX)%Z ->
  (forall (v : Z) (op : Z -> option Z) (v' : Z),
     In op ops ->
     (0 <= v <= MAX)%Z ->
     op v = Some v' ->
     (0 <= v' <= MAX)%Z) ->
  trace_cap_safe MAX (trace_value_sequence v0 ops).
Proof.
  intros HM Hv0 Hop_preserves.
  revert v0 Hv0.
  induction ops as [|op rest IH]; intros v0 Hv0.
  - unfold trace_cap_safe, trace_value_sequence.
    constructor; [assumption | constructor].
  - unfold trace_cap_safe in *. simpl.
    destruct (op v0) as [v1|] eqn:Hop1.
    + constructor; [assumption|].
      apply IH.
      * intros v op' v' Hin Hv Hop'.
        apply (Hop_preserves v op' v');
          [right; assumption | assumption | assumption].
      * apply (Hop_preserves v0 op v1);
          [left; reflexivity | assumption | assumption].
    + constructor; [assumption | constructor].
Qed.

Lemma op_spend_preserves (MAX r : Z) :
  (0 <= MAX)%Z ->
  (0 <= r)%Z ->
  forall v v',
    (0 <= v <= MAX)%Z ->
    op_spend r v = Some v' ->
    (0 <= v' <= MAX)%Z.
Proof.
  intros HM Hr v v' Hv Hop.
  unfold op_spend in Hop.
  destruct (Z.leb 0 r) eqn:H0r; [|discriminate].
  destruct (Z.leb r v) eqn:Hrv; [|discriminate].
  inversion Hop; subst v'.
  apply Z.leb_le in Hrv. apply Z.leb_le in H0r.
  lia.
Qed.

Lemma op_consume_preserves (MAX : Z) :
  (0 <= MAX)%Z ->
  forall v v',
    (0 <= v <= MAX)%Z ->
    op_consume v = Some v' ->
    (0 <= v' <= MAX)%Z.
Proof.
  intros HM v v' _ Hop.
  unfold op_consume in Hop.
  inversion Hop; subst v'. lia.
Qed.

Theorem trace_refinement_for_spend_consume
    (MAX : Z) (v0 : Z) (rs : list Z) :
  (0 <= MAX)%Z ->
  (0 <= v0 <= MAX)%Z ->
  (forall r, In r rs -> (0 <= r)%Z) ->
  trace_cap_safe MAX (trace_value_sequence v0 (map op_spend rs)).
Proof.
  intros HM Hv0 Hrs.
  apply trace_refinement_cap_soundness; [assumption | assumption |].
  intros v op v' Hin Hv Hop.
  rewrite in_map_iff in Hin.
  destruct Hin as [r [Heq Hin_r]]. subst op.
  pose proof (Hrs r Hin_r) as Hr_nn.
  apply (op_spend_preserves MAX r HM Hr_nn v v' Hv Hop).
Qed.
