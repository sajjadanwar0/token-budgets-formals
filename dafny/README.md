# Dafny proofs for Token Budgets

This directory contains a Dafny model of the Token Budgets `Budget` type
and a proof of cap-soundness at the per-instance level.

## What this proves

`Budget.dfy` defines two classes:

1. **`Budget`** — Models the per-instance behaviour of a single `Budget`
   value with a ghost `consumed` flag. The pre-/post-conditions on each
   method (`spend`, `split`, `merge`, `consume`) capture:
   - **Conservation per operation**: `split(a)` returns parent and child
     budgets whose values sum to the original; `merge` returns the sum.
   - **Affine discipline**: every non-constructor method requires
     `!consumed` and sets `consumed := true` on the receiver. Attempting
     to operate on an already-consumed Budget is a Dafny precondition
     violation.

2. **`Session`** — Models the aggregate session ledger (`liveSum`,
   `totalReserved`, `totalCharged`, `totalReleased`) and proves
   `Conservation` and `CapSoundness` as method-level postconditions on
   each ledger update.

Two top-level methods provide explicit witnesses:
- **`Lemma1Witness`** — Walks through a representative session and
  asserts the cap-soundness invariant at every state.
- **`UniquenessWitness`** — Constructs a split sequence and demonstrates
  that calling `spend` on the consumed parent would violate
  the precondition (the Dafny analogue of Rust's E0382).

## What this DOES NOT prove

- The **static** guarantee that Rust's borrow checker rejects programs
  attempting to operate on consumed Budgets. The Dafny class-and-object
  semantics are a refinement of Rust's affine ownership: in Dafny we
  encode "consumed" as a ghost flag that methods check at verification
  time; in Rust the same property is enforced by the type system without
  any runtime flag. The static-vs-dynamic refinement is proved at the
  Iris level (see `iris/budget_iris.tex`).

- The conservative-estimator condition `c_i <= r_i`. As in the TLA+
  artifact, this is a precondition on each `spend` call, justified
  empirically for byte-length estimation against BPE tokenizers (paper
  Section 5.6).

## How to run

```bash
# Install Dafny: https://github.com/dafny-lang/dafny/releases
dafny verify Budget.dfy
```

Expected output: `Dafny program verifier finished with N verified, 0 errors`,
where `N` is the number of methods plus the number of static assertions
in the witness methods. The exact count depends on Dafny version; on
Dafny 4.x it should be in the range of 20-30 verified obligations.

The witness methods (`Lemma1Witness`, `UniquenessWitness`) provide
self-contained example traces; if Dafny accepts them, the per-instance
invariants are mechanically verified.

## Correspondence with the paper

| Paper artifact | Dafny formalisation |
|---|---|
| Lemma 1, Invariant 1 (arithmetic conservation) | `Session.Conservation()` predicate |
| Lemma 1, Invariant 2 (uniqueness of access) | `Budget.consumed` ghost flag + precondition `!consumed` on every method |
| Lemma 1 conclusion (cap-respecting) | `Session.CapSoundness()` predicate |
| `Budget::new` constructor (trusted) | `Budget.New` constructor (no precondition; trusted) |
| `spend(r)` returning Result | `Budget.spend(r)` returning `SpendResult<()>` |
| `split(a)` returning (parent, child) | `Budget.split(a)` returning `(parent, child)` with conservation |
| `merge(b1, b2)` returning sum | `Budget.merge(other)` returning combined |
| `consume()` releasing inner u64 | `Budget.consume()` returning `nat` |
| Rust E0382 "use of moved value" | Dafny precondition violation in `UniquenessWitness` |

## Honesty note

Dafny's verifier is sound modulo the standard caveats: SMT-solver bugs,
type-system unsoundness in Dafny itself (rare but historically not zero),
and the `assume`/`{:trusted}` annotations (we use neither).

The Dafny model is a refinement of the TLA+ aggregate model in `tla/`.
The full chain — Rust source → Iris semantic types → Dafny method-level
contracts → TLA+ aggregate state machine — is the multi-tier verification
strategy this artifact targets, with the Iris tier remaining
pencil-and-paper pending the journal extension.
