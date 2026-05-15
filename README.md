# Token Budgets Formals

> Mechanized verification of the `token-budgets` affine-resource
> discipline. **One repository, four formal tiers**: Verus, Coq
> (Iris + RustBelt + trace-refinement), TLA+, and Dafny.
>
> The Verus tier is the primary headline (42 theorems, 0 errors).
> The other tiers provide independent cross-validation, action-level
> ledger conservation, and partial mechanization of Conjecture 1
> (operational trace refinement).

[![Verus](https://img.shields.io/badge/Verus-42%20verified%2C%200%20errors-brightgreen)](#tier-1-verus)
[![Coq](https://img.shields.io/badge/Coq-Iris%20%2B%20RustBelt-blue)](#tier-2-coq-iris--rustbelt)
[![TLA+](https://img.shields.io/badge/TLA%2B-ledger%20conservation-blueviolet)](#tier-3-tla)
[![Dafny](https://img.shields.io/badge/Dafny-receipt%20cycle-orange)](#tier-4-dafny)
[![License: MIT OR Apache-2.0](https://img.shields.io/badge/license-MIT%20OR%20Apache--2.0-blue)](#license)

This repository consolidates **all formal verification artifacts**
for the [`token-budgets`](https://github.com/sajjadanwar0/token-budgets)
crate into one place. Each tier sits in its own subdirectory with
an independent build system. Reviewers can verify each tier
independently or run all four in sequence.

## The four tiers

| Tier | Subdirectory | Status | What it proves |
|---|---|---|---|
| **1. Verus** | `verus/` | ✅ 42 theorems, 0 errors | Cap-soundness on actual Rust source for sequential, multi-tenant pool, and concurrent split/merge/spend traces. **Primary formal evidence.** |
| **2. Coq (Iris + RustBelt + trace-refinement)** | `coq/` | ✅ Cross-validation + ⚠️ partial Conjecture 1 | Abstract-machine cap-soundness via Iris; structural well-typing via RustBelt/lambda-rust; **partial mechanization of Conjecture 1** in `BudgetTraceRefinement{,Pure}.v`. |
| **3. TLA+** | `tla/` | ✅ Action-level ledger | Six-term conservation invariant verified action-by-action over the Budget transition system. |
| **4. Dafny** | `dafny/` | ✅ Receipt-cycle obligations | Independent SMT-based encoding of the reservation→confirm→refund discipline. |

## Tier 1: Verus

The Verus mechanization proves cap-soundness on the actual Rust
source code across three layers:

| Layer | Theorems | Description |
|---|---|---|
| (a) Sequential cap-soundness | 18 | `try_spend_seq` proves whole-program cap-soundness for the sequential-loop pattern. |
| (b) Multi-tenant pool | 11 | Abstract `BudgetPool` well-formedness, monotonicity, trace cap-soundness (under A4). |
| (c) Concurrent split/merge/spend | 13 | Any interleaving of operations across a tree of budgets preserves the cap invariant. |

**Headline command:**

```bash
cd verus/
verus src/lib.rs src/pool.rs src/concurrent.rs
# 42 verified, 0 errors
```

Tested against Verus commit `b9d5e3a` (October 2025). Z3 backend.
Verification time on a modern laptop (M2 Pro, 16 GB): ~47s for
all 42 theorems.

## Tier 2: Coq (Iris + RustBelt + trace-refinement)

The Coq tier provides abstract-machine cross-validation **and**
the partial mechanization of Conjecture 1 (operational
refinement). It originated in
`~/RustroverProjects/budget-typed-cap/coq/` and consolidates
the earlier `conjecture-1-mechanization-v3` prototype work
that was moved into this directory.

### File map

| File | Encoding | What it proves |
|---|---|---|
| `BudgetAbstract.v` | Pure-Coq abstract machine | Conservation invariants over the six-term ledger. |
| `BudgetIris.v` | Iris base ghost state | Token-based ownership reasoning for `Budget` values. |
| `BudgetIrisTypedCap.v` | Iris typed capability | Cap-soundness via Iris affine resources. |
| `BudgetRustBelt.v` | **lambda-rust encoding** | Structural well-typing of `Budget` operations in the lambda-rust formal model. |
| `BudgetRustBeltTypedCap.v` | RustBelt typed capability | Cap-soundness on the lambda-rust encoding. |
| `BudgetLinearTrace.v` | Linear trace model | Sequential trace cap-soundness. |
| `BudgetTraceRefinement.v` | **Conjecture 1 mechanization (partial)** | Operational refinement from abstract trace to concrete; ships partial obligations with honest open-work framing. |
| `BudgetTraceRefinementPure.v` | **Conjecture 1 mechanization (partial), pure-Coq fragment** | Pure-Coq fragment of the refinement obligation, separated to keep Iris dependencies localized. |
| `BudgetTypedCap.v` | Typed-cap abstract proof | Top-level typed-capability cap-soundness statement. |
| `VerifyAssumptions.v` | Assumption witnesses | Witnesses for A1/A2/A3/A4 under the stated scope. |

### On Conjecture 1

Conjecture 1 in the Token Budgets paper (§VII) states that the
abstract Verus trace model operationally refines the running
Rust binary scheduled by Tokio. **This is open work; the
discipline's headline soundness claim does not rely on it.**

The partial mechanization lives in `BudgetTraceRefinement.v` and
`BudgetTraceRefinementPure.v`. What these files deliver:

- The abstract-side trace structure restated as a Coq object
- The lambda-rust encoding of the implementation side
- The refinement relation is stated
- Pure-Coq fragments of the refinement obligation that don't
  require the full Iris context

What remains open:

- The simulation argument from concrete to abstract (the main
  proof obligation)
- The work-stealing scheduler scheduling-fairness assumption
- The lambda-rust drop-soundness chain that ties unwind events
  back to the abstract `Forfeit` transition

Honest estimate: closing Conjecture 1 along the lambda-rust
route is **multi-person-months** of dedicated Coq/Iris work.
The paper notes (§VII) that a Creusot-based binary-refinement
proof would have been a more economical route; we chose
lambda-rust to reuse the existing community-validated
foundational stack.

### Build

```bash
cd coq/
coq_makefile -f _CoqProject -o Makefile
make
```

Prerequisites:
- Coq 8.18+
- Iris coq-iris ≥ 4.1
- lambda-rust coq library (from the RustBelt project)

## Tier 3: TLA+

Action-by-action ledger conservation: every Budget transition
(`SpendSuccess`, `SpendInsufficient`, `SpendFailPostCheck`,
`Consume`, `Reserve`, `ConfirmWithRefund`, `Forfeit`, `RefundTo`)
is verified to preserve the six-term invariant:

```
liveSum + outstandingReceipts + outstandingRefunds
       + totalCharged + totalUnrecoverable + totalReleased = B_0
```

### Build

```bash
cd tla/

# Download tla2tools.jar (one-time setup) from:
#   http://lamport.azurewebsites.net/tla/tools.html
# Place it in tla/ but do NOT commit it (.gitignored).

# Model-check the Budget specification
java -jar tla2tools.jar -modelcheck Budget.tla -config Budget.cfg
```

Tested against TLA+ Toolbox 1.7.x. State-space exploration is
bounded by the configuration in `Budget.cfg`; the conservation
invariant is checked on every reachable state.

## Tier 4: Dafny

Independent SMT-based encoding of the reservation→confirm→refund
cycle. Provides cross-validation that the algebraic structure is
consistent across an SMT-based prover with a different
specification style than Verus.

### Build

```bash
cd dafny/
dafny verify *.dfy
```

Prerequisites:
- Dafny 4.x
- Z3 (bundled with Dafny)

The Dafny obligations focus specifically on the receipt cycle —
`ReservationReceipt::confirm`, `ReservationReceipt::forfeit`, and
`Refund::apply_to` — proving that the six-term ledger is
preserved across every transition.

## What this verification establishes (and does NOT establish)

### Establishes

1. **Cap-soundness of the Budget abstract trace model** under
   sequential, multi-tenant pool, and concurrent
   split/merge/spend semantics (Verus, 42 theorems).
2. **Cross-validation of the same theorem in two independent
   encodings** (Coq Iris + RustBelt).
3. **Action-level ledger conservation** (TLA+).
4. **Receipt-cycle integrity** in an independent SMT-based
   prover (Dafny).
5. **Partial scaffolding for the operational refinement**
   (Coq trace-refinement files) with explicit open obligations
   marked.

### Does NOT establish

1. **Assumption A1 (UTF-8 byte-length dominance) is empirical.**
   An informal proof sketch is in the paper §IV-B; a mechanized
   proof for a defined class of BPE tokenizer constructions is
   open work.
2. **Operational refinement to running Tokio is open
   (Conjecture 1).** The abstract-trace soundness is proven;
   the refinement to actual Tokio work-stealing is not closed.
   Partial mechanization is in `coq/BudgetTraceRefinement{,Pure}.v`.
3. **The `Drop` implementation is not mechanically verified
   atomic** under nested-panic scenarios.
4. **A3 (provider truthfulness) is an external assumption** no
   client-side proof can falsify.

## Repository layout

```
token-budgets-formals/
├── verus/
│   ├── src/{lib.rs, pool.rs, concurrent.rs}
│   ├── extensions/                          # optional extension experiments
│   ├── Cargo.toml
│   └── README.md
├── coq/
│   ├── BudgetAbstract.v
│   ├── BudgetIris.v, BudgetIrisTypedCap.v
│   ├── BudgetRustBelt.v, BudgetRustBeltTypedCap.v   ← lambda-rust encoding
│   ├── BudgetLinearTrace.v
│   ├── BudgetTraceRefinement.v                     ← Conjecture 1 (partial)
│   ├── BudgetTraceRefinementPure.v                 ← Conjecture 1 (partial, pure-Coq)
│   ├── BudgetTypedCap.v
│   ├── VerifyAssumptions.v
│   ├── _CoqProject, Makefile
│   └── README.md
├── tla/
│   ├── Budget.tla
│   ├── Budget.cfg
│   └── README.md
├── dafny/
│   ├── Budget.dfy
│   ├── ReservationReceipt.dfy
│   └── README.md
├── docs/
│   ├── theorem-index.md          # All 42 Verus theorems indexed
│   ├── assumption-map.md         # A1/A2/A3/A4 ↔ tier mapping
│   └── refinement-gap.md         # Conjecture 1 honest discussion
├── README.md                     ← you are here
├── LICENSE-MIT
└── LICENSE-APACHE
```

## .gitignore essentials

```gitignore
# Verus
verus/target/
verus/Cargo.lock
verus/**/*.log

# Coq build artifacts
coq/*.vo
coq/*.vok
coq/*.vos
coq/*.glob
coq/.*.aux
coq/.lia.cache
coq/.coqdeps.d
coq/Makefile
coq/Makefile.conf
coq/compile.log

# TLA+ tools binary (downloaded separately)
tla/tla2tools.jar
tla/*.out
tla/states/

# Dafny artifacts
dafny/*.dll
dafny/*.pdb
```

## Reviewer reproduction checklist

1. `cd verus && verus src/lib.rs src/pool.rs src/concurrent.rs` → expect "42 verified, 0 errors"
2. `cd coq && coq_makefile -f _CoqProject -o Makefile && make` → expect clean build
3. `cd tla && java -jar tla2tools.jar -modelcheck Budget.tla -config Budget.cfg` → expect "Model checking completed. No error has been found."
4. `cd dafny && dafny verify *.dfy` → expect "Dafny program verifier finished with X verified, 0 errors"

If any tier fails to verify on your machine, please open an
issue with your platform details and the verifier version you
used. We test against the versions documented in each tier's
prerequisites section.

## Related repositories

- [`token-budgets`](https://github.com/sajjadanwar0/token-budgets) — the main Rust crate this repository verifies
- [`token-budgets-extensions`](https://github.com/sajjadanwar0/token-budgets-extensions) — adaptive estimator, streaming receipt, and a Verus `tokenized_state_machine!` skeleton complementary to Conjecture 1
- [`token-budgets-experiments`](https://github.com/sajjadanwar0/token-budgets-experiments) — empirical validation harness (5,047+ live API calls)

## Paper

```bibtex
@article{khan-token-budgets-2026,
  author  = {Khan, Sajjad},
  title   = {Token Budgets: An Affine-Resource Discipline for LLM Cost Caps in Rust},
  journal = {arXiv preprint arXiv:TBD},
  year    = {2026}
}
```

Verification is discussed in §IV-B (assumptions), §IV-D (typed
capability formal foundation), and §VII (open work, including
Conjecture 1).

## License

Dual MIT/Apache-2.0. See `LICENSE-MIT` and `LICENSE-APACHE`.