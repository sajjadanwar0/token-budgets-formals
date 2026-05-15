# TLA+ / TLAPS proofs for Token Budgets

This directory contains the TLA+ aggregate state-machine specification
(`Budget.tla`) and TLAPS proof script (`BudgetProofs.tla`, v5) for the
Budget state machine.

## What this proves

The TLA+ specification models the discipline at the aggregate level:
a single pool `liveSum` of currently-live budget, plus running totals
`totalReserved`, `totalCharged`, and `totalReleased`. The proof
discharges three theorems:

1. **`Conservation`**: at every reachable state,
   `liveSum + totalReserved + totalReleased = B0`.
2. **`CapSoundness`**: at every reachable state,
   `totalCharged <= totalReserved <= B0`.
3. **`SpecImpliesInv`**: the inductive invariant `Inv` (the conjunction of
   `TypeOK`, `Conservation`, and `CapSoundness`) holds at every state.

## How to run

### Prerequisites

```bash
# Install Z3 (provides the SMT backend)
sudo apt install z3
z3 --version   # should show 4.8.x or newer

# Install TLAPS following https://tla.msr-inria.inria.fr/tlaps/
```

### Run TLAPS with Z3 enabled

```bash
tlapm --method z3 BudgetProofs.tla
```

Or for finer control over the backend chain:

```bash
# Two-pass approach: default chain first, then Z3 for arithmetic stragglers
tlapm BudgetProofs.tla              # closes structural obligations
tlapm --method z3 BudgetProofs.tla  # closes arithmetic obligations
```

The fingerprint cache (`.tlacache/`) preserves successfully-closed
obligations across runs, so the second pass only re-tries unproven ones.

Expected output: `0/N obligations failed` after both passes.

### Model-check with TLC (sanity check only)

```bash
java -cp tla2tools.jar tlc2.TLC -config Budget.cfg Budget
```

## What v5 fixed (vs. v4)

The v4 script had 9 of 312 obligations fail with `--method z3` because
five `BY` directives lacked sufficient type-context facts. v5 patches
those five directives to include the missing facts:

- `SpendSuccess` Conservation arithmetic now passes type facts (`<1>1`)
  and precondition facts (`<1>4`) to the SMT backend.
- `SpendSuccess` CapSoundness adds `<1>10` (`totalReserved' \in Nat`)
  and `B0InNat` to the deduction `totalReserved' <= B0`.
- `SpendFailPostCheck` gets the same two patches (Conservation + CapSoundness).
- `Consume` Conservation arithmetic gets type facts (`<1>1`, `<1>3`).
- `InvImpliesNextInv` UNCHANGED case arithmetic gets defensive type facts.

## What this DOES NOT prove

- **Per-Budget uniqueness of access** (Invariant 2 of Lemma 1). Modelling
  individual Budget identities at the TLA+ level requires recursive sums
  over a function from IDs to natural numbers, which is workable but adds
  proof-engineering weight without changing the cap-soundness conclusion.
  Uniqueness of access is proven separately in `dafny/Budget.dfy`
  (precondition-based) and `coq/budget_iris.tex` (Iris-style).
- **Conservative-estimator condition `c_i <= r_i`**. Precondition on each
  Spend action; the byte-length argument that justifies it is empirical
  (paper Section 5.6).
- **The `Budget::new` constructor**. Outside the discipline's scope
  (trusted-base assumption).

## Cross-tier reference

The same theorem is also mechanically verified in Coq stdlib only
(`coq/budget.v`, `reachable_implies_invariants` — rc=0, 0 Admitted,
0 axioms in the proven portion). The Coq proof serves as independent
verification of the abstract state machine.
