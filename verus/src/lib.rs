#![allow(unused)]
mod pool;
pub use pool::*;
mod concurrent;
pub use concurrent::*;
use vstd::prelude::*;


verus! {

pub enum BudgetError {
    InsufficientFunds,
    ExceedsMax,
    Overflow,
}

pub struct Budget {
    pub micro_cents: u64,
    pub max: u64,
}

impl Budget {
    pub open spec fn well_formed(&self) -> bool {
        self.micro_cents <= self.max && self.max < (1u64 << 63)
    }

    pub open spec fn value(&self) -> int {
        self.micro_cents as int
    }
}

impl Budget {
    pub fn new(micro_cents: u64, max: u64) -> (result: Result<Self, BudgetError>)
        ensures
            match result {
                Ok(b) => b.well_formed() && b.micro_cents == micro_cents && b.max == max
                    && max < (1u64 << 63) && micro_cents <= max,
                Err(_) => micro_cents > max || max >= (1u64 << 63),
            },
    {
        if max >= (1u64 << 63) { return Err(BudgetError::ExceedsMax); }
        if micro_cents > max { return Err(BudgetError::ExceedsMax); }
        Ok(Budget { micro_cents, max })
    }

    pub fn spend(self, amount: u64) -> (result: Result<Budget, BudgetError>)
        requires self.well_formed(),
        ensures
            match result {
                Ok(b) => b.well_formed() && b.max == self.max
                    && amount <= self.micro_cents
                    && b.micro_cents == self.micro_cents - amount,
                Err(BudgetError::InsufficientFunds) => amount > self.micro_cents,
                Err(_) => false,
            },
    {
        if amount > self.micro_cents { return Err(BudgetError::InsufficientFunds); }
        Ok(Budget { micro_cents: self.micro_cents - amount, max: self.max })
    }

    pub fn split(self, amount: u64) -> (result: Result<(Budget, Budget), BudgetError>)
        requires self.well_formed(),
        ensures
            match result {
                Ok((taken, rem)) => taken.well_formed() && rem.well_formed()
                    && taken.max == self.max && rem.max == self.max
                    && amount <= self.micro_cents
                    && taken.micro_cents == amount
                    && rem.micro_cents == self.micro_cents - amount,
                Err(BudgetError::InsufficientFunds) => amount > self.micro_cents,
                Err(_) => false,
            },
    {
        if amount > self.micro_cents { return Err(BudgetError::InsufficientFunds); }
        let remainder = self.micro_cents - amount;
        Ok((Budget { micro_cents: amount, max: self.max },
            Budget { micro_cents: remainder, max: self.max }))
    }

    pub fn merge(self, other: Budget) -> (result: Result<Budget, BudgetError>)
        requires self.well_formed(), other.well_formed(), self.max == other.max,
        ensures
            match result {
                Ok(b) => b.well_formed() && b.max == self.max
                    && self.micro_cents + other.micro_cents <= self.max
                    && b.micro_cents == self.micro_cents + other.micro_cents,
                Err(BudgetError::ExceedsMax) =>
                    self.micro_cents + other.micro_cents > self.max,
                Err(_) => false,
            },
    {
        let headroom = self.max - self.micro_cents;
        if other.micro_cents > headroom { return Err(BudgetError::ExceedsMax); }
        let sum = self.micro_cents + other.micro_cents;
        Ok(Budget { micro_cents: sum, max: self.max })
    }

    pub fn consume(self) -> (result: u64)
        requires self.well_formed(),
        ensures result == self.micro_cents,
    { self.micro_cents }
}

pub struct Receipt { pub reserved: u64, pub max: u64 }
impl Receipt {
    pub open spec fn well_formed(&self) -> bool {
        self.reserved <= self.max && self.max < (1u64 << 63)
    }
}

pub struct Refund { pub amount: u64, pub max: u64 }
impl Refund {
    pub open spec fn well_formed(&self) -> bool {
        self.amount <= self.max && self.max < (1u64 << 63)
    }
}

impl Budget {
    pub fn spend_with_receipt(self, reserved: u64) -> (result: Result<(Budget, Receipt), BudgetError>)
        requires self.well_formed(),
        ensures
            match result {
                Ok((b, r)) => b.well_formed() && b.max == self.max
                    && r.well_formed() && r.max == self.max
                    && reserved <= self.micro_cents
                    && b.micro_cents == self.micro_cents - reserved
                    && r.reserved == reserved,
                Err(BudgetError::InsufficientFunds) => reserved > self.micro_cents,
                Err(_) => false,
            },
    {
        if reserved > self.micro_cents { return Err(BudgetError::InsufficientFunds); }
        Ok((Budget { micro_cents: self.micro_cents - reserved, max: self.max },
            Receipt { reserved, max: self.max }))
    }
}

impl Receipt {
    pub fn confirm(self, actual: u64) -> (result: Result<Refund, BudgetError>)
        requires self.well_formed(),
        ensures
            match result {
                Ok(r) => r.well_formed() && r.max == self.max
                    && actual <= self.reserved && r.amount == self.reserved - actual,
                Err(BudgetError::ExceedsMax) => actual > self.reserved,
                Err(_) => false,
            },
    {
        if actual > self.reserved { return Err(BudgetError::ExceedsMax); }
        Ok(Refund { amount: self.reserved - actual, max: self.max })
    }
}

impl Refund {
    pub fn apply_to(self, b: Budget) -> (result: Result<Budget, BudgetError>)
        requires self.well_formed(), b.well_formed(), self.max == b.max,
        ensures
            match result {
                Ok(b2) => b2.well_formed() && b2.max == b.max
                    && b.micro_cents + self.amount <= b.max
                    && b2.micro_cents == b.micro_cents + self.amount,
                Err(BudgetError::ExceedsMax) => b.micro_cents + self.amount > b.max,
                Err(_) => false,
            },
    {
        let headroom = b.max - b.micro_cents;
        if self.amount > headroom { return Err(BudgetError::ExceedsMax); }
        Ok(Budget { micro_cents: b.micro_cents + self.amount, max: b.max })
    }
}

pub open spec fn total_spent(initial: int, ops: Seq<int>) -> int
    decreases ops.len()
{
    if ops.len() == 0 { 0 } else {
        let head = ops[0];
        let head_spent = if head <= initial && head >= 0 { head } else { 0int };
        let after_head = initial - head_spent;
        head_spent + total_spent(after_head, ops.subrange(1, ops.len() as int))
    }
}

pub proof fn trace_cap_soundness(initial: int, ops: Seq<int>)
    requires initial >= 0,
    ensures total_spent(initial, ops) <= initial, total_spent(initial, ops) >= 0,
    decreases ops.len()
{
    if ops.len() == 0 {} else {
        let head = ops[0];
        let head_spent: int = if head <= initial && head >= 0 { head } else { 0int };
        let after_head: int = initial - head_spent;
        trace_cap_soundness(after_head, ops.subrange(1, ops.len() as int));
    }
}

pub proof fn lemma_two_spend_conserves(b0: Budget, a1: u64, a2: u64)
    requires b0.well_formed(), a1 <= b0.micro_cents, a2 <= b0.micro_cents - a1,
    ensures b0.micro_cents - a1 - a2 <= b0.max, b0.micro_cents >= a1 + a2,
{}

pub open spec fn budget_after_spend(b: Budget, amount: u64) -> Budget {
    if amount <= b.micro_cents {
        Budget { micro_cents: (b.micro_cents - amount) as u64, max: b.max }
    } else { b }
}

pub open spec fn amount_spent(b: Budget, amount: u64) -> int {
    if amount <= b.micro_cents { amount as int } else { 0int }
}

pub open spec fn budget_after_ops(b: Budget, ops: Seq<u64>) -> Budget
    decreases ops.len()
{
    if ops.len() == 0 { b } else {
        budget_after_ops(budget_after_spend(b, ops[0]),
                         ops.subrange(1, ops.len() as int))
    }
}

pub open spec fn total_amount_spent(b: Budget, ops: Seq<u64>) -> int
    decreases ops.len()
{
    if ops.len() == 0 { 0 } else {
        amount_spent(b, ops[0])
            + total_amount_spent(budget_after_spend(b, ops[0]),
                                 ops.subrange(1, ops.len() as int))
    }
}

pub proof fn lemma_budget_after_spend_preserves(b: Budget, amount: u64)
    requires b.well_formed(),
    ensures
        budget_after_spend(b, amount).well_formed(),
        budget_after_spend(b, amount).max == b.max,
        budget_after_spend(b, amount).micro_cents as int
            == b.micro_cents as int - amount_spent(b, amount),
        amount_spent(b, amount) >= 0,
        amount_spent(b, amount) <= b.micro_cents as int,
{}

pub proof fn end_to_end_cap_soundness(b: Budget, ops: Seq<u64>)
    requires b.well_formed(),
    ensures
        total_amount_spent(b, ops) >= 0,
        total_amount_spent(b, ops) <= b.micro_cents as int,
        budget_after_ops(b, ops).well_formed(),
        budget_after_ops(b, ops).max == b.max,
        budget_after_ops(b, ops).micro_cents as int
            == b.micro_cents as int - total_amount_spent(b, ops),
    decreases ops.len()
{
    if ops.len() == 0 {} else {
        let head = ops[0];
        let b_after_head = budget_after_spend(b, head);
        lemma_budget_after_spend_preserves(b, head);
        end_to_end_cap_soundness(b_after_head, ops.subrange(1, ops.len() as int));
    }
}

pub fn try_spend(b: Budget, amount: u64) -> (result: (Budget, u64))
    requires b.well_formed(),
    ensures
        result.0.well_formed(),
        result.0.max == b.max,
        result.1 as int == amount_spent(b, amount),
        result.0.micro_cents as int == b.micro_cents as int - amount_spent(b, amount),
        result.0 == budget_after_spend(b, amount),
{
    if amount > b.micro_cents {
        (b, 0)
    } else {
        match b.spend(amount) {
            Ok(b2) => (b2, amount),
            Err(_) => {
                assert(false);
                (Budget { micro_cents: 0, max: 0 }, 0)
            }
        }
    }
}

pub fn try_spend_seq(b: Budget, ops: &[u64]) -> (result: (Budget, u64))
    requires b.well_formed(),
    ensures
        result.0.well_formed(),
        result.0.max == b.max,
        result.0 == budget_after_ops(b, ops@),
        result.1 as int == total_amount_spent(b, ops@),
{
    let mut current = b;
    let mut total: u64 = 0;
    let mut i: usize = 0;
    let ghost b_initial = b;

    proof {
        assert(ops@.subrange(0 as int, ops.len() as int) =~= ops@);
    }

    while i < ops.len()
        invariant
            i <= ops.len(),
            current.well_formed(),
            current.max == b_initial.max,
            budget_after_ops(current, ops@.subrange(i as int, ops.len() as int))
                == budget_after_ops(b_initial, ops@),
            total as int + total_amount_spent(current, ops@.subrange(i as int, ops.len() as int))
                == total_amount_spent(b_initial, ops@),
            current.micro_cents as int + total as int == b_initial.micro_cents as int,
            total <= b_initial.micro_cents,
        decreases ops.len() - i,
    {
        let head = ops[i];

        proof {
            let remaining = ops@.subrange(i as int, ops.len() as int);
            assert(remaining.len() > 0);
            assert(remaining[0] == head);
            assert(remaining.subrange(1, remaining.len() as int)
                =~= ops@.subrange((i + 1) as int, ops.len() as int));
        }

        let (new_current, spent) = try_spend(current, head);
        total = total + spent;
        current = new_current;
        i = i + 1;
    }

    proof {
        assert(ops@.subrange(i as int, ops.len() as int) =~= Seq::<u64>::empty());
    }

    (current, total)
}

} // verus!

fn main() {}
