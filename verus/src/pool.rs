#![allow(unused_imports)]

use vstd::prelude::*;

verus! {

    pub struct PoolModel {
        pub initial_capacity: u64,
        pub available: u64,
    }

    impl PoolModel {
        pub open spec fn well_formed(self) -> bool {
            &&& self.available <= self.initial_capacity
            &&& self.initial_capacity < (1u64 << 63)
        }
    }

    pub enum PoolOp {
        Reserve(u64),
        Release(u64),
    }

    pub open spec fn pool_after_reserve(s: PoolModel, amount: u64) -> PoolModel {
        PoolModel {
            initial_capacity: s.initial_capacity,
            available: (s.available - amount) as u64,
        }
    }

    pub open spec fn pool_after_release(s: PoolModel, amount: u64) -> PoolModel {
        PoolModel {
            initial_capacity: s.initial_capacity,
            available: (s.available + amount) as u64,
        }
    }

    pub proof fn pool_cap_invariant(s: PoolModel)
        requires s.well_formed(),
        ensures s.available <= s.initial_capacity,
    {
    }

    pub proof fn pool_reserve_preserves_wf(s: PoolModel, amount: u64)
        requires
            s.well_formed(),
            amount <= s.available,
        ensures
            pool_after_reserve(s, amount).well_formed(),
            pool_after_reserve(s, amount).initial_capacity == s.initial_capacity,
            pool_after_reserve(s, amount).available == s.available - amount,
    {
    }

    pub proof fn pool_release_preserves_wf(s: PoolModel, amount: u64)
        requires
            s.well_formed(),
            s.available + amount <= s.initial_capacity,
        ensures
            pool_after_release(s, amount).well_formed(),
            pool_after_release(s, amount).initial_capacity == s.initial_capacity,
            pool_after_release(s, amount).available == s.available + amount,
    {
    }

    pub proof fn pool_reserve_release_identity(s: PoolModel, amount: u64)
        requires
            s.well_formed(),
            amount <= s.available,
        ensures
            pool_after_release(pool_after_reserve(s, amount), amount) == s,
    {
    }

    pub proof fn pool_reserve_monotone(s: PoolModel, amount: u64)
        requires
            s.well_formed(),
            amount <= s.available,
        ensures
            pool_after_reserve(s, amount).available <= s.available,
    {
    }

    pub open spec fn pool_after_ops(s: PoolModel, ops: Seq<PoolOp>) -> PoolModel
        decreases ops.len()
    {
        if ops.len() == 0 {
            s
        } else {
            let tail = ops.subrange(1, ops.len() as int);
            match ops[0] {
                PoolOp::Reserve(amount) => {
                    if amount <= s.available {
                        pool_after_ops(pool_after_reserve(s, amount), tail)
                    } else {
                        pool_after_ops(s, tail)
                    }
                }
                PoolOp::Release(amount) => {
                    if s.available + amount <= s.initial_capacity {
                        pool_after_ops(pool_after_release(s, amount), tail)
                    } else {
                        pool_after_ops(s, tail)
                    }
                }
            }
        }
    }

    pub proof fn pool_trace_cap_sound(s: PoolModel, ops: Seq<PoolOp>)
        requires s.well_formed(),
        ensures
            pool_after_ops(s, ops).well_formed(),
            pool_after_ops(s, ops).initial_capacity == s.initial_capacity,
        decreases ops.len()
    {
        if ops.len() > 0 {
            let tail = ops.subrange(1, ops.len() as int);
            match ops[0] {
                PoolOp::Reserve(amount) => {
                    if amount <= s.available {
                        pool_reserve_preserves_wf(s, amount);
                        pool_trace_cap_sound(pool_after_reserve(s, amount), tail);
                    } else {
                        pool_trace_cap_sound(s, tail);
                    }
                }
                PoolOp::Release(amount) => {
                    if s.available + amount <= s.initial_capacity {
                        pool_release_preserves_wf(s, amount);
                        pool_trace_cap_sound(pool_after_release(s, amount), tail);
                    } else {
                        pool_trace_cap_sound(s, tail);
                    }
                }
            }
        }
    }

    pub open spec fn sum_reserved(ops: Seq<PoolOp>) -> nat
        decreases ops.len()
    {
        if ops.len() == 0 {
            0nat
        } else {
            let tail = ops.subrange(1, ops.len() as int);
            (match ops[0] {
                PoolOp::Reserve(a) => a as nat,
                PoolOp::Release(_) => 0nat,
            }) + sum_reserved(tail)
        }
    }

    pub open spec fn sum_released(ops: Seq<PoolOp>) -> nat
        decreases ops.len()
    {
        if ops.len() == 0 {
            0nat
        } else {
            let tail = ops.subrange(1, ops.len() as int);
            (match ops[0] {
                PoolOp::Reserve(_) => 0nat,
                PoolOp::Release(a) => a as nat,
            }) + sum_released(tail)
        }
    }

    pub proof fn pool_sums_nonneg(ops: Seq<PoolOp>)
        ensures
            sum_reserved(ops) >= 0,
            sum_released(ops) >= 0,
    {
    }

    pub open spec fn balanced(ops: Seq<PoolOp>) -> bool {
        sum_reserved(ops) == sum_released(ops)
    }

    pub proof fn pool_empty_trace_balanced()
        ensures balanced(Seq::<PoolOp>::empty()),
    {
    }

}

fn main() {}

