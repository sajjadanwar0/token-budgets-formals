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

    pub proof fn lemma_seq_sum_nonneg(s: Seq<u64>)
        ensures seq_sum(s) >= 0,
        decreases s.len()
    {
        if s.len() > 0 {
            lemma_seq_sum_nonneg(s.subrange(1, s.len() as int));
        }
    }

    pub proof fn lemma_element_leq_sum(s: Seq<u64>, idx: int)
        requires 0 <= idx < s.len(),
        ensures s[idx] as int <= seq_sum(s),
        decreases s.len()
    {
        if idx == 0 {
            lemma_seq_sum_nonneg(s.subrange(1, s.len() as int));
        } else {
            let tail = s.subrange(1, s.len() as int);
            assert(tail[idx - 1] == s[idx]);
            lemma_element_leq_sum(tail, idx - 1);
        }
    }

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

    pub proof fn lemma_seq_sum_push(s: Seq<u64>, v: u64)
        ensures seq_sum(s.push(v)) == seq_sum(s) + v as int,
        decreases s.len()
    {
        let pushed = s.push(v);
        if s.len() == 0 {
            assert(s =~= Seq::<u64>::empty());
            assert(pushed.len() == 1);
            assert(pushed[0] == v);
            let tail = pushed.subrange(1, 1int);
            assert(tail.len() == 0);
            assert(tail =~= Seq::<u64>::empty());
            assert(seq_sum(tail) == 0);
            assert(seq_sum(s) == 0);
        } else {
            let n = s.len() as int;
            let tail_s = s.subrange(1, n);
            let tail_pushed = pushed.subrange(1, pushed.len() as int);
            assert(tail_pushed =~= tail_s.push(v));
            lemma_seq_sum_push(tail_s, v);
            assert(pushed[0] == s[0]);
        }
    }

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
                        live: s.live.update(i as int, sum_val as u64).remove(j as int)
,
                        initial_total: s.initial_total,
                    }
                } else { s }
            }
        }
    }

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
        lemma_element_leq_sum(s.live, idx as int);
    }

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

        assert(s0.live.len() == 1);
        assert(s0.live[0] == initial_value);
        let tail = s0.live.subrange(1, 1int);
        assert(tail.len() == 0);
        assert(tail =~= Seq::<u64>::empty());

        assert(seq_sum(tail) == 0);
        assert(s0.well_formed());

        theorem_concurrent_trace_cap_sound(s0, ops);
    }
}

fn main() {}