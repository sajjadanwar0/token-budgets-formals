datatype BudgetError = Insufficient

datatype SpendResult<T> =
    | Success(remaining: Budget, value: T)
    | Failed(remaining: Budget, error: BudgetError)

class Budget {
    var micro_cents: nat
    ghost var consumed: bool

    predicate Valid()
        reads this
    {
        true
    }

    constructor New(amount: nat)
        ensures this.micro_cents == amount
        ensures this.consumed == false
        ensures fresh(this)
    {
        this.micro_cents := amount;
        this.consumed := false;
    }

    function available(): nat
        reads this
        requires !consumed
    {
        micro_cents
    }

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

    method split(a: nat) returns (parent: Budget, child: Budget)
        requires !consumed
        requires a <= micro_cents
        modifies this
        ensures consumed
        ensures fresh(parent) && fresh(child) && parent != child
        ensures !parent.consumed && !child.consumed
        ensures parent.micro_cents == old(micro_cents) - a
        ensures child.micro_cents == a
        ensures parent.micro_cents + child.micro_cents == old(micro_cents)
    {
        parent := new Budget.New(micro_cents - a);
        child := new Budget.New(a);
        consumed := true;
    }

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

method Lemma1Witness()
{
    var session := new Session(1000);
    assert session.Conservation();
    assert session.CapSoundness();
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

    assert session.totalCharged <= session.totalReserved;
    assert session.totalReserved <= session.B0;
}

method UniquenessWitness()
{
    var b := new Budget.New(100);
    var b_remaining: Budget;
    var b_child: Budget;
    b_remaining, b_child := b.split(40);
    assert b_remaining.micro_cents == 60;
    assert b_child.micro_cents == 40;
    assert b_remaining.micro_cents + b_child.micro_cents == 100;
}