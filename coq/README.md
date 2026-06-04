# Coq Mechanization for `budget-typed-cap`

Coq mechanization of cap-soundness for the const-generic `Budget<MAX>` type,
paired with the Rust const-assertion

```rust
const _A2_HOLDS: () = assert!(MAX < (1u64 << 63), ...);
```

in `../src/lib.rs`. Every concrete `Budget::<K>` in Rust pairs with a concrete
instantiation of these Coq theorems at the same `K`; the Coq hypothesis
`MAX < 2^63` is discharged by rustc's const-eval check of `_A2_HOLDS`.

The proof develops in three tiers (A, B, C) plus a pure linear-trace layer and
an assumptions audit. The full build closes with **zero `Admitted`, zero
`Axiom`** — `VerifyAssumptions.v` prints `Closed under the global context` for
every headline theorem.

> The `.v` files are comment-free by design; this README is the documentation
> of record for what each file proves and how to build it.

---

## TL;DR build

```bash
# one-time: pick ONE opam switch and use it for EVERYTHING
opam switch rustbelt-stable           # the switch that has Iris + lambda-rust's deps
eval $(opam env --switch=rustbelt-stable)
which coqc                            # confirm: .../rustbelt-stable/bin/coqc

# build lambda-rust ONCE under that switch (Tier C dependency)
( cd ~/lambda-rust && make -j )

# build this project under the SAME switch
cd ~/RustroverProjects/token-budgets-formals/coq
make all LRUST_BASE=~/lambda-rust
```

A successful `make all` ends with a block of `Closed under the global context`
lines. If you only have Iris (no lambda-rust), use `make tier-b` instead.

---

## The three golden rules (read this before debugging anything)

Almost every build failure on this project reduces to a toolchain-consistency
mistake. Three rules prevent all of them:

1. **One opam switch for everything.** This project, Iris/stdpp, and
   lambda-rust must all be compiled by the *same* `coqc`. Coq `.vo` files are
   version-locked: a library built by one Coq cannot be loaded by another.

2. **`which coqc` in every shell before you build.** `opam env` is *per-shell*.
   If you work in tmux / split panes, each pane has its own environment. A very
   common failure is rebuilding lambda-rust in one pane (correct switch) and
   building the project in another pane (different/default switch). Run
   `eval $(opam env --switch=rustbelt-stable)` in each pane and verify with
   `which coqc`.

3. **Changed the toolchain? `make clean`, then rebuild.** If you upgrade Coq,
   switch opam switches, or rebuild lambda-rust, the project's existing `.vo`
   become stale relative to the new toolchain. Always `make clean && make all`
   after any such change. Likewise, if you rebuild this project against a
   different Coq, rebuild lambda-rust too.

---

## Files

```
coq/
├── _CoqProject                      # logical paths + ordered source list
├── Makefile                         # hand-written build driver (do NOT regenerate)
├── README.md                        # this file
│
│   # --- Tier A / pure (Coq stdlib only) ---
├── BudgetAbstract.v                 # abstract cap state machine + soundness
├── BudgetLinearTrace.v              # pure linear-trace obligations
├── BudgetTypedCap.v                 # Tier A with the type-level MAX bundled in
├── BudgetTraceRefinementPure.v      # pure trace-refinement scaffolding
│
│   # --- Tier B (needs Iris) ---
├── BudgetIris.v                     # heap_lang Hoare triples + affineness
├── BudgetIrisTypedCap.v             # per-method capped Iris triples
├── BudgetTraceRefinement.v          # Iris-side trace refinement glue
│
│   # --- Tier C (needs Iris + lambda-rust) ---
├── BudgetRustBelt.v                 # lambdaRust structural well-typing
├── BudgetRustBeltTypedCap.v         # parameterized semantic type budget_max
│
│   # --- Assumptions audit (needs Tier C) ---
├── VerifyAssumptions.v              # Print Assumptions for all headline theorems
│
└── rustbelt/
    └── budget.v                     # legacy placeholder; NOT part of the build
```

`rustbelt/budget.v` is an unreferenced early scaffold (a `Parameter budget`
plus `True` lemmas). Nothing imports it and no Makefile target builds it; it is
kept only for history.

---

## What's mechanized

### Tier A — `BudgetTypedCap.v` (pure)

Abstract state machine over a list of live budgets plus a committed total.
Closes with zero `Admitted` / zero `Axiom`, no dependencies beyond the Coq
standard library (`ZArith`, `Lia`, `List`, `Bool`):

- `step_invariant` — every step preserves the cap invariant
- `reachable_invariant` — reachable states satisfy the invariant
- `typed_cap_soundness` — for `0 ≤ MAX < 2^63`, `committed s ≤ MAX`
- `typed_cap_conservation` — for `0 ≤ MAX < 2^63`, `total s ≤ MAX`

`BudgetAbstract.v` and `BudgetLinearTrace.v` provide the underlying state
machine and the pure linear-trace obligations.

### Tier B — `BudgetIrisTypedCap.v` (Iris)

Per-method Iris Hoare triples on heap_lang with the type-level cap bundled in.
`budget_inv_cap MAX l v` is `budget_inv l v ∗ ⌜0 ≤ v ≤ MAX⌝ ∗ ⌜MAX < 2^63⌝`:

- `wp_spend_cap` — capped spend preserves `0 ≤ v ≤ MAX`
- `wp_split_cap` — split yields two capped budgets
- `wp_merge_cap` — merge stays capped (precondition `v1 + v2 ≤ MAX`)
- `wp_consume_cap` — consume yields 0, trivially capped
- `budget_inv_cap_excl` — capped budgets remain affine
- `budget_iris_typed_cap_closed` — aggregator of the four triples

The affineness lemma `budget_inv_excl` (in `BudgetIris.v`) selects the
points-to disequality lemma by name at proof time
(`first [ pointsto_ne | mapsto_ne ]`) so the file compiles unchanged across the
Iris 4.1 → 4.2 rename of the points-to connective.

### Tier C — `BudgetRustBeltTypedCap.v` (lambda-rust)

Parameterized lambdaRust semantic type `budget_max : Z → type` with predicate
`0 ≤ z ≤ MAX ∧ MAX < 2^63`. Lifts the runtime Tier C well-typings:

- `spend_well_typed_max`, `split_well_typed_max`, `merge_well_typed_max`,
  `consume_well_typed_max`
- `conservation_alloc_max` — invariant-allocation scaffolding
- `rust_to_abstract_refinement_max` — aggregate well-typing, universally
  quantified over `MAX`

The encoding is "`MAX` is a Coq-meta parameter at the type-former level, with
`MAX < 2^63` discharged at the Rust const-assertion site." Native const-generic
type formers in lambdaRust would require extending the lambdaRust type system
itself; that remains open work.

---

## Prerequisites

| Tier | Coq | Iris | stdpp | lambda-rust |
|------|------|------|-------|-------------|
| A    | 8.18 | —    | —     | —           |
| B    | 8.18 | 4.1+ | 1.9+  | —           |
| C    | 8.18 | 4.1+ | 1.9+  | a4e89895+   |

Verified working configuration: Coq **8.18.0**, opam switch **rustbelt-stable**
(Iris + stdpp installed in-switch), lambda-rust at **a4e89895** under
`~/lambda-rust`.

### Installing Iris / stdpp

Into the active opam switch (recommended, keeps everything on one Coq):

```bash
opam install coq-iris coq-stdpp
```

Or, if your Coq came from the system package manager (apt):

```bash
sudo apt install libcoq-iris libcoq-stdpp
```

Either way the libraries land in that Coq's `user-contrib` and are found
automatically — no `-Q` flags needed for Iris/stdpp.

### Building lambda-rust (Tier C only)

lambda-rust must be **compiled** before this project's Tier C can build — the
Makefile looks for its `.vo` files, not its `.v` sources. Build it under the
**same switch** you will use here:

```bash
eval $(opam env --switch=rustbelt-stable)
cd ~/lambda-rust
make -j                       # or: dune build, depending on the repo's setup
```

The Makefile expects this layout under `LRUST_BASE` (default `~/lambda-rust`):

```
$(LRUST_BASE)/lifetime/lifetime.vo
$(LRUST_BASE)/lambda-rust/lang/...
$(LRUST_BASE)/lambda-rust/typing/...
```

---

## Building

The `Makefile` is **hand-written and authoritative**. Do **not** run
`coq_makefile -f _CoqProject -o Makefile`: it would overwrite the Makefile and
drop the lambda-rust path handling, and it would build from `_CoqProject` only
(no lambda-rust `-Q` flags), which is exactly the historical breakage this
setup avoids.

```bash
make                # == make all : pure + Tier B + Tier C + assumptions audit
make all            # same as above
make pure           # Coq stdlib only (no Iris, no lambda-rust)
make tier-b         # pure + Iris
make tier-c         # pure + Iris + lambda-rust
make verify         # + VerifyAssumptions (Print Assumptions audit)
make check-iris     # is Iris findable by the active coqc?
make check-lrust    # are lambda-rust .vo present under LRUST_BASE?
make check-all      # both checks
make clean          # remove all build products
```

Point at a non-default lambda-rust location with `LRUST_BASE`:

```bash
make all LRUST_BASE=/path/to/lambda-rust
```

If lambda-rust is installed via opam (in `user-contrib`) rather than as a local
checkout, leave `LRUST_BASE` unset/nonexistent — the Makefile then emits no
lambda-rust `-Q` flags and the `lrust.*` paths resolve through `user-contrib`
automatically.

### Compiling a single file by hand

Pass the same flags the Makefile uses:

```bash
coqc -Q . Top BudgetTypedCap.v             # Tier A (no Iris)
coqc -Q . Top BudgetIrisTypedCap.v         # Tier B (needs Iris)
coqc -Q . Top \
     -Q $LRUST_BASE/lifetime          lrust.lifetime \
     -Q $LRUST_BASE/lambda-rust/lang   lrust.lang \
     -Q $LRUST_BASE/lambda-rust/typing lrust.typing \
     BudgetRustBeltTypedCap.v               # Tier C (needs lambda-rust)
```

---

## Troubleshooting

These are the exact errors seen in practice and their fixes.

### `Cannot find a physical path bound to logical path iris.proofmode`

Iris is not installed in the **active** switch (or you are in a shell whose
`coqc` is a different switch). Fix:

```bash
eval $(opam env --switch=rustbelt-stable)
which coqc                    # confirm the right switch
opam install coq-iris coq-stdpp   # if genuinely not installed
```

### `Cannot find a physical path bound to logical path lang with prefix lrust.lang`

lambda-rust is not built, or `LRUST_BASE` points to the wrong place. Build
lambda-rust (see above) and pass the correct path:

```bash
make tier-c LRUST_BASE=~/lambda-rust
make check-lrust LRUST_BASE=~/lambda-rust   # verifies the .vo are present
```

### `Compiled library X makes inconsistent assumptions over library Coq.Init.Ltac`

The single most common error here. It means library `X.vo` was compiled by a
**different Coq** than the one currently loading it. Coq refuses to mix `.vo`
files across Coq versions/builds. Two variants:

- **`X` is a lambda-rust library** (e.g. `lrust.lang.lang`): lambda-rust's
  `.vo` are stale relative to your current Coq. Rebuild lambda-rust under the
  switch you build the project with:
  ```bash
  eval $(opam env --switch=rustbelt-stable)
  cd ~/lambda-rust && find . -name '*.vo' -delete && make -j
  ```

- **`X` is one of this project's files** (e.g. `Top.BudgetAbstract`): the
  project's own `.vo` were built by a different Coq than lambda-rust — usually
  the split-pane mistake (Rule 2). Activate one switch in *this* shell and
  rebuild from clean:
  ```bash
  eval $(opam env --switch=rustbelt-stable)
  which coqc                 # must match the switch lambda-rust was built with
  make clean && make all
  ```

The general cure is Rule 1 + Rule 3: one switch everywhere, and `make clean`
after any toolchain change.

### `make: Nothing to be done for 'pure'`

Not an error — the pure-tier `.vo` are already up to date. Run `make clean`
first if you want a fresh build.

---

## Verifying zero axioms

`make verify` compiles `VerifyAssumptions.v`, which runs `Print Assumptions` on
every headline theorem across the three tiers. Each should report:

```
Closed under the global context
```

To check a subset by hand (e.g. without lambda-rust), feed `coqtop`:

```bash
echo '
From Top Require Import BudgetTypedCap BudgetIrisTypedCap.
Print Assumptions typed_cap_soundness.
Print Assumptions typed_cap_conservation.
Print Assumptions wp_spend_cap.
Print Assumptions budget_iris_typed_cap_closed.
' | coqtop -Q . Top
```

---

## Honest scope

These files mechanize the **structural** properties of the const-generic
discipline:

- Tier A: abstract cap-soundness on a state-machine model
- Tier B: per-method Iris Hoare triples preserving the cap bound
- Tier C: structural well-typing of method bodies at a parameterized semantic type

What they do **not** mechanize (same caveats as the runtime Tier C):

- The trace-level semantic refinement of the running program against the
  abstract state machine. This is the principal remaining open obligation in
  `BudgetRustBelt.v` and applies equally to the const-generic version.
- Native const-generic type formers in the lambdaRust type system itself. The
  encoding here is at the meta level (Coq parameter paired with Rust
  const-assertion).

---

## Pairing with the Rust const-assertion

Every concrete Rust instantiation `Budget::<K>` pairs with a Coq instantiation
of the relevant theorems at `MAX = K`. The Rust const-eval check of `_A2_HOLDS`
guarantees `K < 2^63` for every successfully compiled Rust program, so the Coq
hypothesis `MAX < 2^63` is mechanically discharged at every concrete
instantiation point. Coq cannot know whether the `K` passed in was
const-checked, but the rustc-side check is sound.
