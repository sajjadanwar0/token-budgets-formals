# Token Budgets — Formals

> Mechanized verification of the [`token-budgets`](https://github.com/sajjadanwar0/token-budgets)
> affine-resource discipline. **Five independent provers** verifying
> cap-soundness from five different angles: TLAPS, TLC, Coq, Dafny,
> and Verus. Every claim in this README is reproducible from the
> sources in this repository.

[![TLAPS](https://img.shields.io/badge/TLAPS-497_obligations_proved-brightgreen)](#tier-1-tlaps-tla-theorem-prover)
[![TLC](https://img.shields.io/badge/TLC-252_distinct_states-brightgreen)](#tier-2-tlc-tla-model-checker)
[![Coq](https://img.shields.io/badge/Coq-0_Admitted%2C_0_axioms-brightgreen)](#tier-3-coq)
[![Dafny](https://img.shields.io/badge/Dafny-23_verified%2C_0_errors-brightgreen)](#tier-4-dafny)
[![Verus](https://img.shields.io/badge/Verus-66_theorems%2C_0_errors-brightgreen)](#tier-5-verus)
[![License](https://img.shields.io/badge/license-MIT_OR_Apache--2.0-blue)](LICENSE-MIT)

This repository consolidates **all formal verification artifacts**
for the [`token-budgets`](https://github.com/sajjadanwar0/token-budgets)
crate into one place. The paper's headline soundness claim
(Lemma 1 / cap-soundness) is verified across **five independent
provers using independent specification styles**. Each tier sits in
its own subdirectory with an independent build system. Reviewers
can verify each tier independently or run all five in sequence.

## The five-tier verification stack

The paper proves Lemma 1 (cap-soundness) using five mechanically
independent provers, each with its own specification style:

| Tier | Subdirectory | Paper claim | Verified |
|---|---|---|---|
| **1. TLAPS** | `tla/BudgetProofs.tla` | 497 obligations proved, Zenon+Isabelle (no SMT) | ✅ "All 497 obligations proved" |
| **2. TLC** | `tla/BudgetMC.tla` | 252 distinct reachable states at B₀=5 | ✅ "252 distinct states found" |
| **3. Coq** | `coq/budget.v` | 0 Admitted, 0 axioms | ✅ Clean build |
| **4. Dafny** | `dafny/Budget.dfy` | 23 verified, 0 errors | ✅ "23 verified, 0 errors" |
| **5. Verus** | `verus/{lib,pool,concurrent}.rs` | 66 verified, 0 errors (42+11+13) | ✅ "42/11/13 verified, 0 errors" |

The five tools span four distinct specification styles:
- **TLA⁺ action-level state machine** (Tiers 1, 2: TLAPS + TLC)
- **Pure-Coq forward-induction proof** (Tier 3)
- **SMT-based contract verification with ghost state** (Tier 4)
- **SMT-based Rust source-level verification** (Tier 5)

Tier 5 (Verus) is the strongest in one specific sense: it verifies
cap-soundness on **the actual Rust source code** rather than on an
encoded abstract model. Tiers 1-4 each operate on a separately
transcribed specification of the same state machine.

## Tier 1: TLAPS (TLA⁺ theorem prover)

`tla/BudgetProofs.tla` specifies the Budget transition system with
six conservation variables and eight transitions. The TLAPS proof
checker discharges **497 proof obligations** using the default
Zenon+Isabelle backend (**no SMT required**), establishing:

```
Spec ⇒ □(Conservation ∧ CapSoundness)
```

across all eight transitions (`SpendSuccess`, `SpendInsufficient`,
`SpendFailPostCheck`, `Consume`, `Reserve`, `ConfirmWithRefund`,
`Forfeit`, `RefundTo`).

### Verify

```bash
cd tla/
tlapm BudgetProofs.tla 2>&1 | grep -E "(obligations|proved|failed)"
# Expected output: "[INFO]: All 497 obligations proved."
```

Tested against TLAPS 1.4.5+ with Zenon and Isabelle 2024.

## Tier 2: TLC (TLA⁺ model checker)

`tla/BudgetMC.tla` is the model-checked version of the same
specification, exhaustively explored at parameter $B_0 = 5$.
TLC discovers exactly **252 distinct reachable states** ($= \binom{10}{5}$),
which is the full conservation simplex with no inaccessible regions.
Zero states violate `Conservation` or `CapSoundness`.

### Verify

```bash
cd tla/

# Download tla2tools.jar (one-time setup) from:
#   http://lamport.azurewebsites.net/tla/tools.html
# Place it in tla/ but do NOT commit it (.gitignored).

# Model-check the Budget specification
java -jar tla2tools.jar -modelcheck BudgetMC.tla -config Budget.cfg
# Expected: "252 distinct states found, 0 states left on queue."
```

Tested against TLA⁺ Toolbox 1.7.x.

## Tier 3: Coq

`coq/budget.v` is an independent forward-induction proof of
cap-soundness over a transition relation with eight constructors.

| Property | Value |
|---|---|
| Admitted | **0** |
| Axioms (in proven portion) | **0** |
| Theorem statement | `reachable_implies_invariants` |

`coq/budget_iris.tex` (pencil-and-paper) sketches an Iris-based
affine-ownership proof; that complementary work is honest
hand-proof rather than mechanized.

The directory also contains additional `.v` files exploring
the open Conjecture 1 obligation: `BudgetRustBelt.v` (lambda-rust
encoding), `BudgetTraceRefinement{,Pure}.v` (partial Conjecture 1
mechanization). **These additions are not required by the paper's
headline claim** — that claim is established by `budget.v` alone.
The additional files are present for reviewers interested in the
open trace-refinement work.

### Verify

```bash
cd coq/
coq_makefile -f _CoqProject -o Makefile
make
# Expected: clean build (docroot warnings are about install paths,
# not proof failures)
```

Prerequisites:

- Coq 8.18+
- (Optional, for `BudgetRustBelt.v` and Iris exploration only)
  `coq-iris ≥ 4.1` and lambda-rust Coq library (from the RustBelt
  project)

## Tier 4: Dafny

`dafny/Budget.dfy` provides per-instance method-contract obligations
on a Dafny class with a `ghost consumed` flag enforcing affine
discipline. The Dafny verifier produces **23 verified, 0 errors**
across all method contracts.

### Verify

```bash
cd dafny/
dafny verify Budget.dfy 2>&1 | grep -E "verified|errors"
# Expected: "Dafny program verifier finished with 23 verified, 0 errors"
```

Prerequisites:

- Dafny 4.x
- Z3 (bundled with Dafny)

## Tier 5: Verus

The Verus mechanization proves cap-soundness on **the actual Rust
source code** across three layers:

| Layer | Theorems | Description |
|---|---:|---|
| (a) Core API (`src/lib.rs`) | 42 | Sequential cap-soundness on `Budget`, `Receipt`, `Refund`, `BudgetPool`, `Reservation`, `StreamingReceipt`, `CapAuthority`. |
| (b) Multi-tenant pool (`src/pool.rs`) | 11 | Abstract `BudgetPool` well-formedness, monotonicity, trace cap-soundness (under A4). |
| (c) Concurrent split/merge/spend (`src/concurrent.rs`) | 13 | Any interleaving of operations across a tree of budgets preserves the cap invariant. |

**Total**: 66 verified, 0 errors.

Verus's contribution to the stack is qualitatively different from
the other four tiers: Tiers 1-4 prove the abstract state machine
correct, while **Verus proves the running Rust code correct**.
Together, the five tiers establish cap-soundness both at the
specification level (TLAPS, TLC, Coq, Dafny) and at the
implementation level (Verus).

### Verify

```bash
cd verus/
verus src/lib.rs        # Expect: "42 verified, 0 errors"
verus src/pool.rs       # Expect: "11 verified, 0 errors"
verus src/concurrent.rs # Expect: "13 verified, 0 errors"

# Or as a single-line check:
{
  echo "lib.rs:        $(verus src/lib.rs 2>&1 | grep -oP '\d+ verified, \d+ errors')"
  echo "pool.rs:       $(verus src/pool.rs 2>&1 | grep -oP '\d+ verified, \d+ errors')"
  echo "concurrent.rs: $(verus src/concurrent.rs 2>&1 | grep -oP '\d+ verified, \d+ errors')"
} | column -t
```

Tested against Verus commit `b9d5e3a` (October 2025). Z3 backend.
Verification time on a modern laptop (M2 Pro, 16 GB): ~47s for
all 66 theorems.

## What this verification establishes (and does NOT establish)

### Establishes

1. **Cap-soundness of the Budget abstract state machine** under
   the eight specified transitions, verified by four independent
   abstract-level tools (TLAPS, TLC, Coq, Dafny — Tiers 1-4).
2. **Cap-soundness on actual Rust source code** for sequential,
   multi-tenant pool, and concurrent split/merge/spend semantics
   (Verus — Tier 5).
3. **Cross-validation of the same theorem across five independent
   encodings**, each by a different prover with a different
   specification style.

### Does NOT establish

1. **Assumption A1 (UTF-8 byte-length dominance) is empirical.**
   An informal proof sketch is in the paper §IV-B; a mechanized
   proof for a defined class of BPE tokenizer constructions is
   open work.
2. **Operational refinement to running Tokio (Conjecture 1)** is
   open work. Partial mechanization is in
   `coq/BudgetTraceRefinement{,Pure}.v` and
   [`token-budgets-extensions/verus-skeleton/`](https://github.com/sajjadanwar0/token-budgets-extensions/tree/master/verus-skeleton).
   The Verus mechanization in Tier 5 of this repository proves
   cap-soundness on the *Rust source*; Conjecture 1 additionally
   asks whether the *running Tokio binary* observably matches that
   source under work-stealing scheduling.
3. **The `Drop` implementation is not mechanically verified atomic**
   under nested-panic scenarios.
4. **A3 (provider truthfulness) is an external assumption** no
   client-side proof can falsify.

### Cross-check, not formal composition

The five tools (TLAPS, TLC, Coq, Dafny, Verus) agree on the same
theorem and use independent provers, providing a cross-check at
each level. **This is not formal composition**: the TLAPS, Coq,
and Dafny specifications are independently transcribed from the
same informal English statement of the state machine, so the
cross-check guarantees that human transcriptions of the same
English are each provably consistent. The Verus specification is
embedded directly in the Rust source, which is a different kind
of cross-check (English → Rust → Verus rather than English →
state-machine encoding → prover-specific syntax).

## Reviewer reproduction checklist

```bash
# Tier 1 — TLAPS (497 obligations)
cd tla/
tlapm BudgetProofs.tla 2>&1 | grep -E "(obligations|proved)"

# Tier 2 — TLC (252 distinct states)
java -jar tla2tools.jar -modelcheck BudgetMC.tla -config Budget.cfg

# Tier 3 — Coq (0 Admitted, 0 axioms in budget.v)
cd ../coq/
coq_makefile -f _CoqProject -o Makefile && make

# Tier 4 — Dafny (23 verified, 0 errors)
cd ../dafny/
dafny verify Budget.dfy

# Tier 5 — Verus (66 verified, 0 errors)
cd ../verus/
verus src/lib.rs src/pool.rs src/concurrent.rs
```

If any tier fails to verify on your machine, please open an issue
with your platform details and the verifier version you used. We
test against the versions documented in each tier's prerequisites
section.

## Repository layout

```
token-budgets-formals/
├── tla/                   # Tier 1 + Tier 2: TLAPS theorem-proving + TLC model-checking
│   ├── BudgetProofs.tla       # TLAPS spec (497 obligations)
│   ├── BudgetMC.tla           # TLC model-check spec (252 states)
│   ├── Budget.cfg
│   └── README.md
├── coq/                   # Tier 3: Coq stdlib forward-induction proof
│   ├── budget.v               # The headline proof (0 Admitted, 0 axioms)
│   ├── budget_iris.tex        # Pencil-and-paper Iris sketch
│   ├── BudgetRustBelt.v       # Lambda-rust encoding (exploration)
│   ├── BudgetTraceRefinement.v       # Conjecture 1 (partial)
│   ├── BudgetTraceRefinementPure.v   # Conjecture 1 (partial, pure-Coq)
│   ├── _CoqProject, Makefile
│   └── README.md
├── dafny/                 # Tier 4: Dafny SMT-based receipt-cycle obligations
│   ├── Budget.dfy             # 23 verified, 0 errors
│   └── README.md
├── verus/                 # Tier 5: Verus full Rust mechanization
│   ├── src/{lib.rs, pool.rs, concurrent.rs}   # 42 + 11 + 13 = 66 theorems
│   ├── Cargo.toml
│   └── README.md
├── README.md              # This file
├── LICENSE-MIT
└── LICENSE-APACHE
```

## Related repositories

- [`token-budgets`](https://github.com/sajjadanwar0/token-budgets) — the main Rust crate this repository verifies
- [`token-budgets-extensions`](https://github.com/sajjadanwar0/token-budgets-extensions) — adaptive estimator and Verus Conjecture-1 skeleton (open work)
- [`token-budgets-experiments`](https://github.com/sajjadanwar0/token-budgets-experiments) — empirical validation (5,424 live API row-events)
- [`rig-budget`](https://github.com/sajjadanwar0/rig-budget) — integration with the `rig` LLM framework

## Paper

```bibtex
@article{khan-token-budgets-2026,
  author  = {Khan, Sajjad},
  title   = {Token Budgets: An Affine-Resource Discipline for LLM Cost Caps in Rust},
  journal = {arXiv preprint arXiv:TBD},
  year    = {2026}
}
```

The five-tier mechanization is discussed in paper §IV-D
("Verification status" subsection of the affine-resource API
section). Tier 5 (Verus) is integrated as a first-class tool
alongside TLAPS, TLC, Coq, and Dafny.

## License

Dual MIT/Apache-2.0. See `LICENSE-MIT` and `LICENSE-APACHE`.