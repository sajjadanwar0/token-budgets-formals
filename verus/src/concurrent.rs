//! Verus mechanization of concurrent split/merge/spend cap-soundness.
//! v2: fixes the three errors reported in v1.
//!   - Added lemma_seq_sum_nonneg
//!   - Added lemma_element_leq_sum
//!   - Tightened proof hints in lemma_seq_sum_push base case
//!   - Tightened proof in theorem_concurrent_spend_preserves
//!   - Tightened proof in theorem_single_root_cap_sound

#![allow(unused_imports)]

use vstd::prelude::*;

verus! {

    pub enum ConcurrentOp {
        Spend { idx: nat, amount: u64 },
        Split { idx: nat, amount: u64 },
        Merge { i: nat, j: nat },
    }

    pub open spec fn seq_sum(s: Seq<u64>) -> int
        decreases s.len()
    {
        if s.len() == 0 {
            0
        } else {
            s[0] as int + seq_sum(s.subrange(1, s.len() as int))
        }
    }

    pub struct MultiState {
        pub live: Seq<u64>,
        pub initial_total: u64,
    }

    impl MultiState {
        pub open spec fn well_formed(self) -> bool {
            &&& seq_sum(self.live) <= self.initial_total as int
            &&& self.initial_total < (1u64 << 63)
            &&& seq_sum(self.live) >= 0
        }
    }

    // ========================================================
    // Helper lemmas about seq_sum
    // ========================================================

    /// NEW: Sum of a u64 sequence is always non-negative.
    /// Trivial because each element s[i] is a u64 cast to int (>= 0),
    /// but Verus needs this stated as a lemma for chaining.
    pub proof fn lemma_seq_sum_nonneg(s: Seq<u64>)
        ensures seq_sum(s) >= 0,
        decreases s.len()
    {
        if s.len() > 0 {
            lemma_seq_sum_nonneg(s.subrange(1, s.len() as int));
            // seq_sum(s) unfolds to s[0] as int + seq_sum(tail)
            // s[0] as int >= 0 because s[0] is u64
            // seq_sum(tail) >= 0 by inductive hypothesis
        }
        // Base case: seq_sum(empty) = 0 >= 0
    }

    /// NEW: Any individual element is bounded by the sum.
    /// Used to establish that `amount <= s.live[idx] <= seq_sum(s.live)`
    /// in the spend well-formed proof.
    pub proof fn lemma_element_leq_sum(s: Seq<u64>, idx: int)
        requires 0 <= idx < s.len(),
        ensures s[idx] as int <= seq_sum(s),
        decreases s.len()
    {
        if idx == 0 {
            // seq_sum(s) = s[0] + seq_sum(tail), need s[0] <= s[0] + seq_sum(tail)
            // Equivalent to seq_sum(tail) >= 0
            lemma_seq_sum_nonneg(s.subrange(1, s.len() as int));
        } else {
            let tail = s.subrange(1, s.len() as int);
            // Index in tail at position (idx - 1) is s[idx]
            assert(tail[idx - 1] == s[idx]);
            lemma_element_leq_sum(tail, idx - 1);
            // Now: s[idx] = tail[idx-1] <= seq_sum(tail)
            // seq_sum(s) = s[0] as int + seq_sum(tail) >= 0 + s[idx] = s[idx]
            // Here s[0] as int >= 0 because s[0] is u64
        }
    }

    /// Updating one index changes the sum by exactly the delta.
    pub proof fn lemma_seq_sum_update(s: Seq<u64>, idx: int, new_val: u64)
        requires 0 <= idx < s.len(),
        ensures seq_sum(s.update(idx, new_val))
                == seq_sum(s) + new_val as int - s[idx] as int,
        decreases s.len()
    {
        if idx == 0 {
            assert(s.update(0, new_val).subrange(1, s.len() as int)
                == s.subrange(1, s.len() as int));
        } else {
            lemma_seq_sum_update(
                s.subrange(1, s.len() as int), idx - 1, new_val,
            );
            assert(s.update(idx, new_val).subrange(1, s.len() as int)
                == s.subrange(1, s.len() as int).update(idx - 1, new_val));
        }
    }

    /// FIXED: Pushing a value adds its weight to the sum.
    /// More explicit proof hints to help Verus close the unfolding chain.
    pub proof fn lemma_seq_sum_push(s: Seq<u64>, v: u64)
        ensures seq_sum(s.push(v)) == seq_sum(s) + v as int,
        decreases s.len()
    {
        let pushed = s.push(v);
        if s.len() == 0 {
            // Empty s case: pushed is the singleton [v].
            assert(s =~= Seq::<u64>::empty());
            assert(pushed.len() == 1);
            assert(pushed[0] == v);
            // The subrange (1, 1) of a length-1 sequence is empty.
            let tail = pushed.subrange(1, 1int);
            assert(tail.len() == 0);
            assert(tail =~= Seq::<u64>::empty());
            // seq_sum unfolds:
            //   seq_sum(pushed) = pushed[0] as int + seq_sum(tail)
            //                   = v as int + seq_sum(empty)
            //                   = v as int + 0
            //                   = v as int
            // seq_sum(s) = 0 (s is empty)
            // Goal: v as int == 0 + v as int ✓
            assert(seq_sum(tail) == 0);  // Explicit: seq_sum of empty
            assert(seq_sum(s) == 0);     // Explicit: seq_sum of empty
        } else {
            let n = s.len() as int;
            let tail_s = s.subrange(1, n);
            let tail_pushed = pushed.subrange(1, pushed.len() as int);
            // Tail of pushed equals push of tail.
            assert(tail_pushed =~= tail_s.push(v));
            // Recursive call.
            lemma_seq_sum_push(tail_s, v);
            // Now: seq_sum(tail_s.push(v)) == seq_sum(tail_s) + v as int
            // And: tail_pushed == tail_s.push(v)
            // So:  seq_sum(tail_pushed) == seq_sum(tail_s) + v as int
            // First elements match:
            assert(pushed[0] == s[0]);
            // Unfold seq_sum on both sides:
            //   seq_sum(s) = s[0] + seq_sum(tail_s)
            //   seq_sum(pushed) = pushed[0] + seq_sum(tail_pushed)
            //                   = s[0] + seq_sum(tail_s) + v
            //                   = seq_sum(s) + v ✓
        }
    }

    /// Removing an index subtracts that value from the sum.
    pub proof fn lemma_seq_sum_remove(s: Seq<u64>, idx: int)
        requires 0 <= idx < s.len(),
        ensures seq_sum(s.remove(idx)) == seq_sum(s) - s[idx] as int,
        decreases s.len()
    {
        if idx == 0 {
            assert(s.remove(0) == s.subrange(1, s.len() as int));
        } else {
            lemma_seq_sum_remove(s.subrange(1, s.len() as int), idx - 1);
            assert(s.remove(idx).subrange(1, s.remove(idx).len() as int)
                == s.subrange(1, s.len() as int).remove(idx - 1));
        }
    }

    // ========================================================
    // Operation semantics
    // ========================================================

    pub open spec fn apply_op(s: MultiState, op: ConcurrentOp) -> MultiState {
        match op {
            ConcurrentOp::Spend { idx, amount } => {
                if idx < s.live.len() && amount <= s.live[idx as int] {
                    MultiState {
                        live: s.live.update(
                            idx as int,
                            (s.live[idx as int] - amount) as u64,
                        ),
                        initial_total: s.initial_total,
                    }
                } else { s }
            }
            ConcurrentOp::Split { idx, amount } => {
                if idx < s.live.len() && amount <= s.live[idx as int] {
                    let remainder = (s.live[idx as int] - amount) as u64;
                    MultiState {
                        live: s.live.update(idx as int, remainder).push(amount),
                        initial_total: s.initial_total,
                    }
                } else { s }
            }
            ConcurrentOp::Merge { i, j } => {
                if i < j && j < s.live.len()
                    && (s.live[i as int] as int + s.live[j as int] as int)
                        <= s.initial_total as int
                {
                    let sum_val: u64 = (s.live[i as int] + s.live[j as int]) as u64;
                    MultiState {
                        live: s.live.update(i as int, sum_val).remove(j as int),
                        initial_total: s.initial_total,
                    }
                } else { s }
            }
        }
    }

    // ========================================================
    // Per-operation cap-soundness theorems
    // ========================================================

    /// FIXED: Spend preserves well-formedness; sum strictly decreases.
    /// Now invokes lemma_element_leq_sum to establish that
    /// seq_sum(s.live) >= amount, needed for non-negativity.
    pub proof fn theorem_concurrent_spend_preserves(
        s: MultiState, idx: nat, amount: u64,
    )
        requires
            s.well_formed(),
            idx < s.live.len(),
            amount <= s.live[idx as int],
        ensures
            apply_op(s, ConcurrentOp::Spend { idx, amount }).well_formed(),
            seq_sum(apply_op(s, ConcurrentOp::Spend { idx, amount }).live)
                == seq_sum(s.live) - amount as int,
    {
        let new_val = (s.live[idx as int] - amount) as u64;
        lemma_seq_sum_update(s.live, idx as int, new_val);
        // After update: seq_sum(updated) = seq_sum(s.live) + new_val - s.live[idx]
        //                                = seq_sum(s.live) - amount
        //
        // For well_formed we need seq_sum(updated) >= 0.
        // We have: seq_sum(s.live) >= 0 (from precondition)
        //          amount <= s.live[idx] (from precondition)
        //          s.live[idx] <= seq_sum(s.live) (by element_leq_sum)
        // So:      amount <= seq_sum(s.live), hence seq_sum(updated) >= 0.
        lemma_element_leq_sum(s.live, idx as int);
    }

    /// Split preserves well-formedness and CONSERVES the sum.
    pub proof fn theorem_concurrent_split_conserves(
        s: MultiState, idx: nat, amount: u64,
    )
        requires
            s.well_formed(),
            idx < s.live.len(),
            amount <= s.live[idx as int],
        ensures
            apply_op(s, ConcurrentOp::Split { idx, amount }).well_formed(),
            seq_sum(apply_op(s, ConcurrentOp::Split { idx, amount }).live)
                == seq_sum(s.live),
    {
        let remainder = (s.live[idx as int] - amount) as u64;
        let after_update = s.live.update(idx as int, remainder);
        lemma_seq_sum_update(s.live, idx as int, remainder);
        lemma_seq_sum_push(after_update, amount);
    }

    /// Merge preserves well-formedness and CONSERVES the sum.
    pub proof fn theorem_concurrent_merge_conserves(
        s: MultiState, i: nat, j: nat,
    )
        requires
            s.well_formed(),
            i < j,
            j < s.live.len(),
            (s.live[i as int] as int + s.live[j as int] as int)
                <= s.initial_total as int,
        ensures
            apply_op(s, ConcurrentOp::Merge { i, j }).well_formed(),
            seq_sum(apply_op(s, ConcurrentOp::Merge { i, j }).live)
                == seq_sum(s.live),
    {
        let sum_val: u64 = (s.live[i as int] + s.live[j as int]) as u64;
        lemma_seq_sum_update(s.live, i as int, sum_val);
        let after_update = s.live.update(i as int, sum_val);
        assert(after_update[j as int] == s.live[j as int]);
        lemma_seq_sum_remove(after_update, j as int);
    }

    /// General: any op preserves well-formedness.
    pub proof fn theorem_concurrent_op_preserves_wf(
        s: MultiState, op: ConcurrentOp,
    )
        requires s.well_formed(),
        ensures
            apply_op(s, op).well_formed(),
            apply_op(s, op).initial_total == s.initial_total,
    {
        match op {
            ConcurrentOp::Spend { idx, amount } => {
                if idx < s.live.len() && amount <= s.live[idx as int] {
                    theorem_concurrent_spend_preserves(s, idx, amount);
                }
            }
            ConcurrentOp::Split { idx, amount } => {
                if idx < s.live.len() && amount <= s.live[idx as int] {
                    theorem_concurrent_split_conserves(s, idx, amount);
                }
            }
            ConcurrentOp::Merge { i, j } => {
                if i < j && j < s.live.len()
                    && (s.live[i as int] as int + s.live[j as int] as int)
                        <= s.initial_total as int
                {
                    theorem_concurrent_merge_conserves(s, i, j);
                }
            }
        }
    }

    // ========================================================
    // Trace-level theorems
    // ========================================================

    pub open spec fn apply_trace(s: MultiState, ops: Seq<ConcurrentOp>) -> MultiState
        decreases ops.len()
    {
        if ops.len() == 0 {
            s
        } else {
            apply_trace(apply_op(s, ops[0]), ops.subrange(1, ops.len() as int))
        }
    }

    pub proof fn theorem_concurrent_trace_cap_sound(
        s: MultiState, ops: Seq<ConcurrentOp>,
    )
        requires s.well_formed(),
        ensures
            apply_trace(s, ops).well_formed(),
            apply_trace(s, ops).initial_total == s.initial_total,
            seq_sum(apply_trace(s, ops).live) <= s.initial_total as int,
            seq_sum(apply_trace(s, ops).live) >= 0,
        decreases ops.len()
    {
        if ops.len() > 0 {
            theorem_concurrent_op_preserves_wf(s, ops[0]);
            theorem_concurrent_trace_cap_sound(
                apply_op(s, ops[0]), ops.subrange(1, ops.len() as int),
            );
        }
    }

    /// FIXED: Specialised theorem for a single root budget.
    /// Now uses explicit step-by-step hints for seq_sum(seq![v]) == v.
    pub proof fn theorem_single_root_cap_sound(
        initial_value: u64, ops: Seq<ConcurrentOp>,
    )
        requires initial_value < (1u64 << 63),
        ensures
            ({
                let s0 = MultiState {
                    live: seq![initial_value],
                    initial_total: initial_value,
                };
                seq_sum(apply_trace(s0, ops).live) <= initial_value as int
            }),
    {
        let s0 = MultiState {
            live: seq![initial_value],
            initial_total: initial_value,
        };
        // Establish seq_sum(s0.live) == initial_value as int step by step.
        assert(s0.live.len() == 1);
        assert(s0.live[0] == initial_value);
        let tail = s0.live.subrange(1, 1int);
        assert(tail.len() == 0);
        assert(tail =~= Seq::<u64>::empty());
        // seq_sum unfolds at length-1: s0.live[0] + seq_sum(tail) = initial_value + 0
        assert(seq_sum(tail) == 0);  // explicit empty fold
        // Conclude seq_sum(s0.live) == initial_value as int
        // (Verus should now fold seq_sum given the chain above.)

        // Establish well-formedness of s0:
        //   seq_sum(s0.live) == initial_value <= initial_value = initial_total ✓
        //   initial_total < 2^63 from precondition ✓
        //   seq_sum(s0.live) == initial_value >= 0 ✓
        assert(s0.well_formed());

        theorem_concurrent_trace_cap_sound(s0, ops);
    }

}

fn main() {}
