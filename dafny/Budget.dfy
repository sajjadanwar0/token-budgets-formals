// Dafny model of the Budget class for Token Capabilities.
//
// This file proves at the per-Budget-instance level the invariants that
// the TLA+ aggregate model abstracts away:
//
//   - Each Budget has a unique identity (the object reference).
//   - spend(r) requires r <= micro_cents and decrements micro_cents by r,
//     atomically and only on success.
//   - split(a) returns a pair of Budgets whose values sum to the parent's
//     original value (conservation).
//   - merge(b1, b2) returns a Budget whose value is the sum of the inputs.
//   - consume() releases the inner u64.
//
// Dafny's class-and-object semantics are a refinement of Rust's affine
// ownership: each Budget is a unique object, methods that consume `self`
// in Rust correspond to methods that "consume" the Dafny object via the
// `consumed` ghost flag. Once consumed, the budget cannot be operated on
// again (a Dafny precondition rules it out).
//
// What this DOES NOT capture: the static guarantee that Rust's borrow
// checker rejects programs which would attempt to operate on a consumed
// Budget. That guarantee comes from rustc and is proved separately at the
// Iris level (iris/budget_iris.tex). The Dafny model checks the runtime
// behaviour assuming the affine discipline is enforced.

datatype BudgetError = Insufficient

datatype SpendResult<T> =
    | Success(remaining: Budget, value: T)
    | Failed(remaining: Budget, error: BudgetError)

class Budget {
    var micro_cents: nat
    ghost var consumed: bool

    // Class invariant: the consumed flag is well-formed.
    // (This is a tautology but documents the intent.)
    predicate Valid()
        reads this
    {
        true
    }

    // Constructor: creates a fresh Budget with the specified amount.
    // This corresponds to `Budget::new(micro_cents)` in Rust. It is the
    // trusted entry point; Dafny does not verify the caller's authority
    // to call it (this is the same trust assumption as in the paper's
    // threat model: Budget::new is outside the discipline).
    constructor New(amount: nat)
        ensures this.micro_cents == amount
        ensures this.consumed == false
        ensures fresh(this)
    {
        this.micro_cents := amount;
        this.consumed := false;
    }

    // Read-only accessor.
    function available(): nat
        reads this
        requires !consumed
    {
        micro_cents
    }

    // spend(r): consume `r` from the budget if available, return a new
    // Budget with the remainder; otherwise return `Insufficient` and
    // leave the budget unchanged.
    //
    // In Rust this method takes self by value; in Dafny we model that by
    // marking the receiver as consumed and returning a fresh Budget on
    // success, or a fresh Budget identical to the receiver on failure.
    // The precondition `!consumed` is the Dafny encoding of the affine
    // type rule that you cannot operate on an already-consumed Budget.
    method spend(r: nat) returns (result: SpendResult<()>)
        requires !consumed
        modifies this
        ensures consumed
        ensures result.Success? ==>
            && fresh(result.remaining)
            && result.remaining.micro_cents == old(micro_cents) - r
            && !result.remaining.consumed
            && r <= old(micro_cents)
        ensures result.Failed? ==>
            && fresh(result.remaining)
            && result.remaining.micro_cents == old(micro_cents)
            && !result.remaining.consumed
            && r > old(micro_cents)
            && result.error == Insufficient
    {
        if r <= micro_cents {
            var remaining := new Budget.New(micro_cents - r);
            consumed := true;
            return Success(remaining, ());
        } else {
            var remaining := new Budget.New(micro_cents);
            consumed := true;
            return Failed(remaining, Insufficient);
        }
    }

    // split(a): partition this budget into a parent (with original - a)
    // and a child (with a). The combined value of the returned pair
    // equals the original value: conservation.
    method split(a: nat) returns (parent: Budget, child: Budget)
        requires !consumed
        requires a <= micro_cents
        modifies this
        ensures consumed
        ensures fresh(parent) && fresh(child) && parent != child
        ensures !parent.consumed && !child.consumed
        ensures parent.micro_cents == old(micro_cents) - a
        ensures child.micro_cents == a
        // The conservation theorem at the method level: split partitions
        // the original budget exactly.
        ensures parent.micro_cents + child.micro_cents == old(micro_cents)
    {
        parent := new Budget.New(micro_cents - a);
        child := new Budget.New(a);
        consumed := true;
    }

    // merge(other): combine two budgets into one. Both inputs are
    // consumed; a new Budget with the sum is returned.
    method merge(other: Budget) returns (combined: Budget)
        requires this != other
        requires !this.consumed && !other.consumed
        modifies this, other
        ensures this.consumed && other.consumed
        ensures fresh(combined) && !combined.consumed
        ensures combined.micro_cents ==
                old(this.micro_cents) + old(other.micro_cents)
    {
        combined := new Budget.New(micro_cents + other.micro_cents);
        consumed := true;
        other.consumed := true;
    }

    // consume(): release the inner u64 and mark this Budget consumed.
    // Returns the value to the caller.
    method consume() returns (released: nat)
        requires !consumed
        modifies this
        ensures consumed
        ensures released == old(micro_cents)
    {
        released := micro_cents;
        consumed := true;
    }
}

// =====================================================================
// CAP SOUNDNESS THEOREM
// =====================================================================
//
// We model a "session" as a sequence of Budget operations starting from
// a single root Budget(B0). The ghost variables totalReserved, totalCharged,
// and totalReleased track the cumulative effect of the session.
//
// Theorem (CapSoundness): at every state in the session,
//   totalCharged <= totalReserved <= B0
//
// This is the conclusion of Lemma 1 in the paper, proven at the
// Dafny method-call level rather than the TLA+ aggregate level.

class Session {
    var totalReserved: nat
    var totalCharged: nat
    var totalReleased: nat
    var liveSum: nat
    const B0: nat

    constructor (b0: nat)
        ensures totalReserved == 0
        ensures totalCharged == 0
        ensures totalReleased == 0
        ensures liveSum == b0
        ensures B0 == b0
    {
        totalReserved := 0;
        totalCharged := 0;
        totalReleased := 0;
        liveSum := b0;
        B0 := b0;
    }

    predicate Conservation()
        reads this
    {
        liveSum + totalReserved + totalReleased == B0
    }

    predicate CapSoundness()
        reads this
    {
        totalCharged <= totalReserved && totalReserved <= B0
    }

    // SpendSuccess: the caller has chosen a Budget to spend against; the
    // call succeeds; the provider charges `c` (with c <= r). This method
    // updates the session ledger.
    method spendSuccess(r: nat, c: nat)
        requires Conservation() && CapSoundness()
        requires r > 0 && c <= r
        requires r <= liveSum
        modifies this
        ensures Conservation() && CapSoundness()
        ensures liveSum == old(liveSum) - r
        ensures totalReserved == old(totalReserved) + r
        ensures totalCharged == old(totalCharged) + c
        ensures totalReleased == old(totalReleased)
    {
        liveSum := liveSum - r;
        totalReserved := totalReserved + r;
        totalCharged := totalCharged + c;
    }

    // SpendInsufficient: r exceeds the live budget; nothing changes.
    method spendInsufficient(r: nat)
        requires Conservation() && CapSoundness()
        requires r > liveSum
        modifies this
        ensures Conservation() && CapSoundness()
        ensures liveSum == old(liveSum)
        ensures totalReserved == old(totalReserved)
        ensures totalCharged == old(totalCharged)
        ensures totalReleased == old(totalReleased)
    {
        // No-op.
    }

    // SpendFailPostCheck: the runtime check passed, the call was issued,
    // but the call subsequently failed; the budget is consumed but the
    // provider may have charged 0 <= c <= r.
    method spendFailPostCheck(r: nat, c: nat)
        requires Conservation() && CapSoundness()
        requires r > 0 && c <= r
        requires r <= liveSum
        modifies this
        ensures Conservation() && CapSoundness()
        ensures liveSum == old(liveSum) - r
        ensures totalReserved == old(totalReserved) + r
        ensures totalCharged == old(totalCharged) + c
        ensures totalReleased == old(totalReleased)
    {
        liveSum := liveSum - r;
        totalReserved := totalReserved + r;
        totalCharged := totalCharged + c;
    }

    // Consume: release amount from the budget pool to the host program.
    method releaseConsume(amount: nat)
        requires Conservation() && CapSoundness()
        requires amount > 0 && amount <= liveSum
        modifies this
        ensures Conservation() && CapSoundness()
        ensures liveSum == old(liveSum) - amount
        ensures totalReleased == old(totalReleased) + amount
        ensures totalReserved == old(totalReserved)
        ensures totalCharged == old(totalCharged)
    {
        liveSum := liveSum - amount;
        totalReleased := totalReleased + amount;
    }
}

// =====================================================================
// LEMMA 1 (paper) AT THE DAFNY LEVEL
// =====================================================================
//
// The methods above are individually verified by Dafny: each preserves
// Conservation and CapSoundness. By induction over any sequence of method
// calls, both invariants hold at every state. We verify a representative
// sequence below.

method Lemma1Witness()
{
    var session := new Session(1000);  // B0 = 1000 micro-cents
    assert session.Conservation();
    assert session.CapSoundness();

    // Sequence: spend 200 succeeding, spend 800 failing pre-check,
    // spend 100 succeeding, consume 700.
    session.spendSuccess(200, 150);
    assert session.totalReserved == 200;
    assert session.totalCharged == 150;
    assert session.liveSum == 800;

    session.spendInsufficient(900);   // 900 > 800
    assert session.totalReserved == 200;
    assert session.liveSum == 800;

    session.spendSuccess(100, 100);
    assert session.totalReserved == 300;
    assert session.totalCharged == 250;
    assert session.liveSum == 700;

    session.releaseConsume(700);
    assert session.liveSum == 0;
    assert session.totalReleased == 700;

    // Final state satisfies CapSoundness.
    assert session.totalCharged <= session.totalReserved;
    assert session.totalReserved <= session.B0;
}

// =====================================================================
// PER-BUDGET UNIQUENESS WITNESS
// =====================================================================
//
// The Dafny class-and-object semantics enforce uniqueness of access via
// the `consumed` ghost flag plus the precondition `!consumed` on every
// non-consumer method. Attempting to use a consumed Budget violates the
// precondition and Dafny rejects the program.

method UniquenessWitness()
{
    var b := new Budget.New(100);
    var b_remaining: Budget;
    var b_child: Budget;
    b_remaining, b_child := b.split(40);

    // After split, b is consumed. Calling b.spend(...) here would fail
    // verification because !b.consumed is false:
    //
    //   var r := b.spend(10);   // VERIFICATION ERROR: precondition violated
    //
    // The above line is commented out; uncommenting it produces a
    // verification failure. This is the Dafny-level analogue of Rust's
    // E0382 "use of moved value".

    // We can, however, continue to use the returned remaining/child:
    assert b_remaining.micro_cents == 60;
    assert b_child.micro_cents == 40;
    assert b_remaining.micro_cents + b_child.micro_cents == 100;
}
