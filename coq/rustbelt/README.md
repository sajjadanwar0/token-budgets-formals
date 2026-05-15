# Token Budgets — RustBelt Embedding

This subdirectory contains the in-progress RustBelt mechanization of
the Token Budgets paper's Conjecture 1 (binary-level cap-soundness).

It lives **alongside** the existing `tla/`, `coq/`, and `dafny/`
subdirectories of `token-budgets-formals/`, not inside any of them.
The existing `coq/` directory contains an independent stdlib-Coq
proof of the abstract state machine; this `rustbelt/` directory
contains the Iris+λ_Rust embedding that closes the binary-level
conjecture.

## Status

| Component | Status |
|-----------|--------|
| Semantic type definition | scaffolded, 3/3 obligations proved |
| `Budget::new` constructor | scaffolded, proof Admitted |
| `Budget::spend` | scaffolded, proof Admitted (the hard one) |
| `Budget::split` | scaffolded, proof Admitted |
| `Budget::merge` | scaffolded, proof Admitted |
| `Budget::consume` | scaffolded, proof Admitted |
| `cap_soundness_binary` theorem | stated, proof Admitted |

When all `Admitted` are discharged, Conjecture 1 closes and the paper
gets promoted (Conjecture → Theorem).

## Directory layout

```
rustbelt/
├── README.md                     ← you are here
├── DAY_1_WALKTHROUGH.md          ← do this first
├── WEEK_1_READING.md             ← reading list with verification questions
├── EIGHT_WEEK_PLAN.md            ← overall calendar
├── setup.sh                      ← installs Coq+Iris, clones lambda-rust
├── budget.v                      ← THE MAIN PROOF FILE
├── day1_exercises.v              ← sanity-check exercises for Day 1
├── _CoqProject.fragment          ← include path additions
├── .gitignore
├── notes/                        ← your personal notes, scratch proofs
│   └── .gitkeep
└── scratch/                      ← throwaway proof attempts, debugging
    └── .gitkeep
```

## How `budget.v` integrates with the lambda-rust repo

`budget.v` is designed to live at
`lambda-rust/theories/typing/lib/budget.v` for compilation. The
canonical source-of-truth copy lives **here** in `rustbelt/`. The
`setup.sh` script symlinks it into the lambda-rust tree:

```
~/lambda-rust/theories/typing/lib/budget.v  →  symlink to
  /path/to/token-budgets-formals/rustbelt/budget.v
```

This way:
1. You edit one canonical file (under version control here)
2. The lambda-rust build picks it up automatically via the symlink
3. Reproducibility: anyone running `setup.sh` ends up with the same
   integration

If symlinks aren't available (e.g., on Windows/WSL), `setup.sh` will
copy instead, and you'll need to re-copy after edits.

## Quick start

```bash
# From your token-budgets-formals/rustbelt directory:

# 1. Install toolchain + clone lambda-rust + smoke test (~60-90 min)
./setup.sh

# 2. Verify your Day 1 understanding (5 tiny exercises, ~30 min)
cd ~/lambda-rust
coqc -Q theories lrust theories/typing/lib/day1_exercises.v

# 3. Smoke-test budget.v compiles (with Admitted proofs)
coqc -Q theories lrust theories/typing/lib/budget.v
# Expect: warnings about Admitted lemmas, no errors.

# 4. Start the Week 1 reading guide
$EDITOR WEEK_1_READING.md
```

## Where to put your work

- **Personal notes** as you read: `notes/`
- **Failed proof attempts and debugging:** `scratch/`
- **Working proofs:** edit `budget.v` directly

The `scratch/` directory is your safe space — commit aggressively,
even broken stuff. The `budget.v` file should always at least
*compile* (with `Admitted` for incomplete proofs); never push a
broken `budget.v`.

## When you get stuck

1. Re-read the relevant section of `WEEK_1_READING.md`
2. Look for a similar pattern in `lambda-rust/theories/typing/lib/cell.v`
   or `mutex.v`
3. Post the goal state + error to https://iris.dev/contact (Iris
   Slack/Mattermost — the community is responsive)
4. Or post it back to the chat where you got these files; we'll
   work through it together

## Deliverable

When all `Admitted` in `budget.v` are discharged:

1. The proof compiles silently with no warnings
2. The paper updates: Conjecture 1 → Theorem 2
3. Section IV-B-c gets a sentence: "Conjecture 1 is closed; see
   `token-budgets-formals/rustbelt/budget.v` for the mechanization"
4. Appendix A is replaced with a 2-3 page proof exposition

Estimated calendar: **8 weeks** part-time for a Coq newcomer with
strong proof-engineering background (TLA+/Dafny experience helps).

## Honest scope

I (the AI assistant) cannot run Coq in my sandbox. I can write
proofs that follow RustBelt's documented patterns and identify
which existing lemmas to invoke, but I cannot verify they
typecheck. You will be the one running `coqc` and finding the
inevitable mismatches between my training data and the live
RustBelt API.

The right working pattern: you do the reading, run the proofs, hit
errors, paste the goal state and error back to me, I propose
tactics, you try them. Iterate. Same loop as your TLAPS work, just
slower per-iteration.
