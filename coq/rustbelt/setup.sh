#!/usr/bin/env bash
# setup.sh
#
# Token Budgets RustBelt Embedding — Day 1 Environment Setup
#
# Run from: token-budgets-formals/rustbelt/
# Run on:   your local Linux/macOS dev machine
# DO NOT:   run inside the Claude/AI sandbox; the formals work
#           happens on your own hardware.
#
# Idempotent: re-running is safe.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUSTBELT_DIR=${RUSTBELT_DIR:-$HOME/lambda-rust}

cat << 'BANNER'
==============================================================
Token Budgets RustBelt Embedding — Day 1 Environment Setup
==============================================================
This will:
  1. Install opam (OCaml package manager)
  2. Create an opam switch with OCaml 4.14
  3. Install Coq 8.18 + Iris 4.2 + RustBelt dependencies
  4. Clone lambda-rust to ~/lambda-rust (or $RUSTBELT_DIR)
  5. Build lambda-rust (~30-60 minutes on first run)
  6. Symlink budget.v into the lambda-rust tree
  7. Run a smoke test

Total time: 60-90 minutes (mostly waiting for compile)
BANNER

read -p "Proceed? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# --------------------------------------------------------------------
# 1. opam
# --------------------------------------------------------------------
echo "==== Step 1/7: opam ===="
if ! command -v opam &> /dev/null; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install opam
    else
        sudo apt-get update
        sudo apt-get install -y opam
    fi
fi
echo "opam version: $(opam --version)"

# Init if first time
if [ ! -d "$HOME/.opam" ]; then
    opam init --bare --no-setup --disable-sandboxing -y
fi

# --------------------------------------------------------------------
# 2. opam switch
# --------------------------------------------------------------------
echo "==== Step 2/7: opam switch 'rustbelt' (OCaml 4.14.1) ===="
if ! opam switch list 2>/dev/null | grep -q "rustbelt"; then
    opam switch create rustbelt 4.14.1 -y
fi
eval $(opam env --switch=rustbelt)
echo "Active switch: $(opam switch show)"

# --------------------------------------------------------------------
# 3. Coq + Iris
# --------------------------------------------------------------------
echo "==== Step 3/7: Coq + Iris ===="
opam repo add coq-released https://coq.inria.fr/opam/released --all-switches 2>/dev/null || true
opam repo add iris-dev https://gitlab.mpi-sws.org/iris/opam.git --all-switches 2>/dev/null || true
opam update -y

opam install -y \
    coq.8.18.0 \
    coq-stdpp.1.10.0 \
    coq-iris.4.2.0 \
    coq-iris-heap-lang.4.2.0

# CoqIDE is optional; install but tolerate failure (e.g., headless servers)
opam install -y coqide || echo "(coqide install skipped; non-fatal)"

echo "Installed:"
echo "  coq:               $(coqc --version | head -1)"
echo "  iris (via opam):   $(opam list --installed coq-iris | tail -1)"

# --------------------------------------------------------------------
# 4. lambda-rust clone
# --------------------------------------------------------------------
echo "==== Step 4/7: lambda-rust clone ===="
if [ ! -d "$RUSTBELT_DIR" ]; then
    git clone https://gitlab.mpi-sws.org/iris/lambda-rust.git "$RUSTBELT_DIR"
fi
cd "$RUSTBELT_DIR"

# Check out a known-good commit if specified
if [ -n "${KNOWN_GOOD_COMMIT}" ]; then
    git checkout "$KNOWN_GOOD_COMMIT"
fi

echo "lambda-rust at: $RUSTBELT_DIR"
echo "Current commit: $(git rev-parse --short HEAD) ($(git log -1 --format=%s | head -c 60))"

# --------------------------------------------------------------------
# 5. Build lambda-rust
# --------------------------------------------------------------------
echo "==== Step 5/7: Build lambda-rust ===="
NPROC=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 2)
JOBS=$((NPROC > 4 ? 4 : NPROC))  # cap at 4 to avoid OOM

if make -j$JOBS 2>&1 | tail -50 ; then
    echo "lambda-rust built successfully"
else
    cat << 'EOF'

==============================================================
BUILD FAILED.

Common fixes:
  1. Iris version drift. Try:
       opam install coq-iris.4.2.0 -y
  2. lambda-rust master past iris-4.2 API. Try:
       git tag | sort -V | tail -5
       git checkout <recent-tag>
       make clean && make -j2
  3. OOM during build. Try:
       make -j2  # or just `make`

If stuck, paste the last 30 lines of `make` output to chat.
==============================================================
EOF
    exit 1
fi

# --------------------------------------------------------------------
# 6. Symlink budget.v + day1_exercises.v into the lambda-rust tree
# --------------------------------------------------------------------
echo "==== Step 6/7: Symlink working files into lambda-rust ===="
LIB_DIR="$RUSTBELT_DIR/theories/typing/lib"
mkdir -p "$LIB_DIR"

for f in budget.v day1_exercises.v; do
    SRC="$SCRIPT_DIR/$f"
    DST="$LIB_DIR/$f"
    if [ ! -f "$SRC" ]; then
        echo "WARN: $SRC not found; skipping symlink for $f"
        continue
    fi
    if [ -e "$DST" ] && [ ! -L "$DST" ]; then
        echo "WARN: $DST exists and is NOT a symlink; not overwriting"
        continue
    fi
    ln -sf "$SRC" "$DST"
    echo "  symlinked: $DST -> $SRC"
done

# --------------------------------------------------------------------
# 7. Smoke test
# --------------------------------------------------------------------
echo "==== Step 7/7: Smoke test ===="
SMOKE=$(mktemp /tmp/smoke_XXXXXX.v)
cat > "$SMOKE" << 'EOF'
From iris.proofmode Require Import proofmode.
From lrust.typing Require Import own.

Lemma smoke_test : forall (n : nat), n + 0 = n.
Proof. intros n. induction n; simpl; auto. Qed.
EOF

cd "$RUSTBELT_DIR"
if coqc -Q theories lrust "$SMOKE" 2>&1 ; then
    echo
    cat << 'SUCCESS'

==============================================================
==== Day 1 environment ready. ====
==============================================================

Next steps:

  1. Compile day1_exercises.v (5 small Iris proofs):
       cd ~/lambda-rust
       coqc -Q theories lrust theories/typing/lib/day1_exercises.v
     Expected: silent output, exit code 0

  2. Compile budget.v with Admitted (warnings, no errors):
       coqc -Q theories lrust theories/typing/lib/budget.v
     Expected: 6 Admitted warnings

  3. Open WEEK_1_READING.md and start the Day 2-7 reading

Post the outputs of (1) and (2) back to chat.
==============================================================
SUCCESS
    rm -f "$SMOKE"
else
    rm -f "$SMOKE"
    echo
    echo "Smoke test FAILED. See error above."
    echo "Most likely: the iris/typing imports moved. Paste error to chat."
    exit 1
fi
