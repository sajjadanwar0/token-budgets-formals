# budget-verus

Source-level verification of the Token Budgets discipline using
Verus. This crate is the **scaffolding for the sequel paper**:
closing the source-to-spec refinement gap that the main paper
identifies as the principal open obligation of the mechanization.

## What this addresses

The main paper's mechanization closes cap-soundness at three
levels:

| Tier | Language | Status |
|---|---|---|
| A | Pure Coq abstract state machine | Closed |
| B | Iris Hoare triples on heap_lang | Closed (heap_lang, not Rust) |
| C | lambda-rust well-typing | Closed (skeletal bodies only) |

None of these is the Rust binary itself. Reviewers (correctly)
identified this as the central limitation of the mechanization.

**This crate closes that gap** by re-implementing the Budget
discipline with Verus annotations. Verus operates on the actual
Rust source code, uses Z3 as backend, and discharges
`requires`/`ensures` clauses on every method directly against the
implementation. There is no embedding, no skeleton, no translation
layer.

## Status

**Scaffolding shipped, proofs pending.**

What's done:
- Full Verus-annotated Rust source with `requires`, `ensures`,
  and `spec` clauses on all five core methods (`new`, `spend`,
  `split`, `merge`, `consume`)
- Specification clauses for the trace-level cap-soundness theorem
- Documentation of the proof structure and the inductive
  argument

What's pending (the sequel paper deliverable):
- Replace `assume(...)` placeholders with actual proof bodies
- Discharge all SMT obligations via Verus + Z3
- Add the trace-level cap-soundness `proof fn` with full
  induction
- Run the verifier and confirm `verified` rather than `assumed`
  for every theorem

Estimated effort: 6-12 weeks of focused Verus work. The
specifications are already in place; the remaining work is the
proof-mechanic discharge.

## Why ship the scaffolding now

The main paper's claim is "Verus is a credible 6-12 week sequel
effort." That claim is testable: a reviewer can read this file
and judge whether (a) the specifications are well-formed,
(b) the proof obligations look tractable, (c) the trace-level
theorem statement matches the abstract-machine theorem.

Shipping the scaffolding makes the claim falsifiable rather than
hand-waved.

## To install Verus

See https://verus-lang.github.io/verus/guide/install.html

```bash
# Approximate installation (check the official guide for current steps)
git clone https://github.com/verus-lang/verus
cd verus/source
./tools/get-z3.sh
cargo build --release
```

## To run verification

```bash
verus src/lib.rs
```

**Current expected output**: most obligations marked as `assumed`
(via the placeholder `assume(...)` blocks). The sequel deliverable
is to remove every `assume` and have Verus report `verified`.

## Comparison with the main mechanization

| Property | Coq (main paper) | Verus (this crate) |
|---|---|---|
| Operates on | Heap_lang model, lambda-rust skeleton | Actual Rust source |
| Proof backend | Manual Coq tactics | Automatic Z3 SMT |
| Discharge style | Interactive | Automatic with annotations |
| Time-to-prove a method | Hours of tactic work | Minutes once spec is right |
| What's proved | Abstract-machine soundness | Source-level conformance |
| Trusted base | Coq kernel + stdpp + Iris + lambda-rust | Verus + Rust compiler + Z3 |

The two approaches are complementary, not competing: Coq gives
foundational guarantees with a small trusted base; Verus gives
direct source-level guarantees with a larger but automated trusted
base. The sequel paper will explicitly compare both and argue that
for production Rust crates the Verus path is more practical.

## File layout

```
budget-verus/
├── Cargo.toml              # crate manifest, Verus dependency commented
├── README.md               # this file
└── src/
    └── lib.rs              # annotated Budget source (300+ LOC of specs)
```

## What the sequel paper will report

1. **Source-level cap-soundness theorem**: a Verus-discharged
   proof that the running Rust source code satisfies the
   abstract-machine specification.
2. **Trace-level cap-soundness**: composed via induction over
   operation sequences.
3. **Comparison with the main paper's Coq mechanization**:
   what the two prove, what neither proves, and what the
   combination establishes.
4. **Implementation effort**: actual time-to-discharge, number of
   manual proof hints required, comparison with the heap_lang
   route.
5. **Generalisations**: the Verus specification extends naturally
   to the receipt/refund mechanism, the multi-tenant
   `BudgetPool`, and the streaming per-token refund variant.
   We expect each extension to be 1-2 weeks of additional
   work.
