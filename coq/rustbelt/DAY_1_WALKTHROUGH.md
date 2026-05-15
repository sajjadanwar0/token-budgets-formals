# Day 1 Walkthrough — End-to-End

This is the literal sequence of commands and decisions for Day 1.
Total time: 2-4 hours, mostly waiting for compiles. Active work
~45 minutes.

If anything fails: stop, paste the error back to chat, fix before
moving on. Don't power through errors — they compound.

---

## Prerequisites check (5 minutes)

Run these on your dev machine (Linux or macOS, NOT inside the
Claude sandbox):

```bash
# Disk space: need ~5GB for Coq + Iris + RustBelt + builds
df -h ~ | tail -1

# RAM: 4GB minimum, 8GB comfortable for parallel build
free -h 2>/dev/null || vm_stat | head -5

# CPU cores: more = faster build
nproc 2>/dev/null || sysctl -n hw.ncpu
```

If you have less than 4GB free RAM, run `make` with `-j2` instead
of `-j$(nproc)` later.

---

## Step 1: Place this directory in your formals repo (2 minutes)

```bash
# From your token-budgets-formals checkout:
cd ~/path/to/token-budgets-formals/

# Verify existing structure
ls -d */
# Expected: tla/  coq/  dafny/  IRR/  prusti/

# Extract the rustbelt tarball (you'll receive this from chat)
tar -xzf ~/Downloads/rustbelt.tar.gz
# Result: a new rustbelt/ subdirectory parallel to tla/, coq/, etc.

ls -d */
# Expected: tla/  coq/  dafny/  IRR/  prusti/  rustbelt/
```

Commit this immediately:

```bash
git add rustbelt/
git commit -m "Add RustBelt embedding subdirectory (Conjecture 1 mechanization in progress)"
git push
```

You now have a place to work, under version control.

---

## Step 2: Run the toolchain setup (45-90 minutes)

```bash
cd rustbelt/
chmod +x setup.sh
./setup.sh
```

What happens:
- 5 min: opam + OCaml 4.14 install
- 5 min: Coq 8.18, Iris 4.2, stdpp, heap-lang install
- 30-60 min: clone + build lambda-rust (this is the long wait)
- 1 min: symlink budget.v into lambda-rust
- 1 min: smoke test

When it finishes, you should see:
```
==== Day 1 environment ready. ====
```

If it fails: paste the last 30 lines of output back to chat. Most
common failures and fixes are listed at the end of this document.

---

## Step 3: Run the Day 1 exercises (30 minutes)

These verify your minimal Iris vocabulary works.

```bash
cd ~/lambda-rust  # the lambda-rust clone, not the formals repo

# The setup script symlinked our exercises file into theories/typing/lib/
ls theories/typing/lib/day1_exercises.v
# Expected: shows the file (as a symlink)

# Compile it. Should be silent.
coqc -Q theories lrust theories/typing/lib/day1_exercises.v
echo "Exit code: $?"
# Expected: silent output, exit code 0
```

**If it fails:**
- Paste the error back to chat. Don't try to fix it yourself yet —
  the error message format will tell us what library is missing.

**If it succeeds:**
- You have a working Coq + Iris + RustBelt environment.
- You've executed your first 5 Iris proofs.
- You know how to invoke `coqc` against the lambda-rust build.

This is a meaningful milestone. Commit:

```bash
cd ~/path/to/token-budgets-formals/rustbelt/
git add notes/  # any notes you've made so far
git commit -m "Day 1 environment verified, exercises pass" --allow-empty
```

---

## Step 4: Verify budget.v compiles with Admitted (5 minutes)

The starter `budget.v` has `Admitted` proofs but should still
typecheck (the goal statements must be well-formed).

```bash
cd ~/lambda-rust
coqc -Q theories lrust theories/typing/lib/budget.v 2>&1 | tail -20
```

Expected output: a list of warnings like
```
Warning: Lemma type_budget_new_typed declared as Axiom (admitted)
Warning: Lemma type_budget_spend_typed declared as Axiom (admitted)
... (six total)
```

**If you see Errors (not Warnings):**
- The `Admitted` lemmas have malformed goal statements. Paste the
  error back to chat — this is fixable but I likely guessed wrong
  on a RustBelt API.

**If you see only Warnings:**
- The starter compiles. The proofs are real holes you'll fill in
  Weeks 3-7.

---

## Step 5: Begin Week 1 reading (2 hours of Day 1 evening, then Days 2-7)

Open `WEEK_1_READING.md`. Do not skip. Do not jump ahead to Day 2's
material before you've done Day 1's exercises.

Specifically for the rest of Day 1: skim Software Foundations Vol 1
chapters Logic and Tactics. URL is in the reading guide.

Don't aim for mastery. Aim for vocabulary: by Day 7 you should be
able to read a Coq proof and follow what it does.

---

## Step 6: End-of-Day-1 report

Post these back to chat:

1. **Smoke test result:** the output of `setup.sh`'s final lines
2. **Exercises result:** `coqc` exit code on `day1_exercises.v`
3. **budget.v result:** the warning list from `coqc` on `budget.v`
4. **Time spent:** rough hours, so we can calibrate the rest of the
   plan
5. **Sticky points:** any concept that didn't click

I'll then either confirm Day 2 (continue with Software Foundations)
or unblock specific issues.

---

## Common failures and fixes

### `opam: command not found` after install

**Fix:** opam needs to be in PATH. Run:
```bash
echo 'eval $(opam env)' >> ~/.bashrc
source ~/.bashrc
```

### `coq-iris` install fails with version conflict

**Fix:** the iris-dev opam repo may have moved past 4.2.0. Pin
explicitly:
```bash
opam install coq-iris.4.2.0 coq-stdpp.1.10.0 -y
```

If 4.2.0 is unavailable, try the latest stable:
```bash
opam install coq-iris -y
```
And note the version installed; I may need to adjust `budget.v`'s
imports.

### `lambda-rust make` fails with "Cannot find ... in lrust.typing"

**Fix:** the lambda-rust master branch may have moved past the
iris version we're using. Check out a known-good tag:
```bash
cd ~/lambda-rust
git tag | sort -V | tail -5
git checkout <latest-tag-that-builds>
make clean && make -j2
```

### `coqc` reports "Reference not found"

This is a RustBelt-API drift between my training data and your
installation. Paste the error and the missing reference back to
chat; I'll either find the renamed lemma or update the proof
structure.

### Build runs out of memory

**Fix:** reduce parallelism:
```bash
make -j2   # instead of -j$(nproc)
```

Or build serially:
```bash
make
```

### `coqide` won't open

It's optional for Day 1. Use any text editor + command-line `coqc`.
For Week 3 onward when you're writing real proofs, you'll want
either `coqide` or Proof General (Emacs mode) for interactive proof
state. Install `proofgeneral` from your package manager if `coqide`
is broken.

---

## What "Day 1 done" looks like

✅ `setup.sh` completed successfully
✅ `day1_exercises.v` compiles with exit code 0
✅ `budget.v` compiles with only Admitted warnings (no errors)
✅ You've started reading Software Foundations Vol 1
✅ You've committed the verified environment to git

When you have all five, post back to chat. We move to Day 2.
