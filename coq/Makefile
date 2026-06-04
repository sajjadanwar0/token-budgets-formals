# Hand-written Makefile for the budget-typed-cap Coq mechanization.
# DO NOT regenerate with coq_makefile (see _CoqProject note).
#
# Tiers:
#   pure    BudgetAbstract, BudgetLinearTrace, BudgetTypedCap,
#           BudgetTraceRefinementPure        -- Coq stdlib only
#   tier-b  + BudgetIris, BudgetIrisTypedCap,
#             BudgetTraceRefinement           -- needs Iris (libcoq-iris)
#   tier-c  + BudgetRustBelt, BudgetRustBeltTypedCap
#                                             -- needs Iris + lambda-rust
#   verify  + VerifyAssumptions (Print Assumptions audit; needs Tier C)
#   all     == verify (the full build)

COQC ?= coqc

# Flags shared by every file (kept in sync with _CoqProject).
TOP_FLAGS := -Q . Top -w -notation-overridden -w -masking-absolute-name

# ---- lambda-rust location (Tier C only) -------------------------------
# Local checkout layout (default): lifetime under $(LRUST_BASE)/lifetime,
# lang/typing under $(LRUST_BASE)/lambda-rust/...  If lambda-rust is
# instead installed via opam (lands in Coq's user-contrib), leave
# LRUST_BASE pointing at a nonexistent path and the flags stay empty so
# the lrust.* logical paths resolve through user-contrib automatically.
LRUST_BASE ?= $(HOME)/lambda-rust

ifneq ($(wildcard $(LRUST_BASE)/lifetime/lifetime.vo),)
  LRUST_QFLAGS := \
	-Q $(LRUST_BASE)/lifetime lrust.lifetime \
	-Q $(LRUST_BASE)/lambda-rust/lang lrust.lang \
	-Q $(LRUST_BASE)/lambda-rust/typing lrust.typing
else
  LRUST_QFLAGS :=
endif

.PHONY: all pure tier-a tier-bprime tier-b tier-c verify \
        clean check-iris check-lrust check-all

all: verify

# Convenience tier aggregates -------------------------------------------
pure: BudgetAbstract.vo BudgetLinearTrace.vo BudgetTypedCap.vo \
      BudgetTraceRefinementPure.vo

tier-a: BudgetAbstract.vo

tier-bprime: BudgetAbstract.vo BudgetLinearTrace.vo

tier-b: pure BudgetIris.vo BudgetIrisTypedCap.vo BudgetTraceRefinement.vo

tier-c: tier-b BudgetRustBelt.vo BudgetRustBeltTypedCap.vo

verify: tier-c VerifyAssumptions.vo

# Pure Coq (stdlib only) ------------------------------------------------
BudgetAbstract.vo: BudgetAbstract.v
	$(COQC) $(TOP_FLAGS) $<

BudgetLinearTrace.vo: BudgetLinearTrace.v BudgetAbstract.vo
	$(COQC) $(TOP_FLAGS) $<

BudgetTypedCap.vo: BudgetTypedCap.v
	$(COQC) $(TOP_FLAGS) $<

BudgetTraceRefinementPure.vo: BudgetTraceRefinementPure.v
	$(COQC) $(TOP_FLAGS) $<

# Tier B (Iris) ---------------------------------------------------------
BudgetIris.vo: BudgetIris.v BudgetAbstract.vo
	$(COQC) $(TOP_FLAGS) $<

BudgetIrisTypedCap.vo: BudgetIrisTypedCap.v BudgetAbstract.vo BudgetIris.vo
	$(COQC) $(TOP_FLAGS) $<

BudgetTraceRefinement.vo: BudgetTraceRefinement.v BudgetAbstract.vo \
		BudgetIris.vo BudgetIrisTypedCap.vo BudgetTraceRefinementPure.vo
	$(COQC) $(TOP_FLAGS) $<

# Tier C (Iris + lambda-rust) -------------------------------------------
BudgetRustBelt.vo: BudgetRustBelt.v BudgetAbstract.vo BudgetLinearTrace.vo \
		BudgetIris.vo
	$(COQC) $(TOP_FLAGS) $(LRUST_QFLAGS) $<

BudgetRustBeltTypedCap.vo: BudgetRustBeltTypedCap.v BudgetAbstract.vo \
		BudgetLinearTrace.vo BudgetIris.vo BudgetRustBelt.vo
	$(COQC) $(TOP_FLAGS) $(LRUST_QFLAGS) $<

# Assumptions audit (transitively needs Tier C) -------------------------
VerifyAssumptions.vo: VerifyAssumptions.v BudgetTypedCap.vo \
		BudgetIrisTypedCap.vo BudgetRustBeltTypedCap.vo
	$(COQC) $(TOP_FLAGS) $(LRUST_QFLAGS) $<

clean:
	rm -f *.vo *.vok *.vos *.glob .*.aux .lia.cache
	rm -f rustbelt/*.vo rustbelt/*.vok rustbelt/*.vos rustbelt/*.glob rustbelt/.*.aux

check-iris:
	@echo "Checking for Iris..."
	@echo 'From iris.proofmode Require Import proofmode.' > /tmp/test_iris.v
	@$(COQC) /tmp/test_iris.v 2>/dev/null \
		&& echo "Iris available" \
		|| (echo "Iris not found (install libcoq-iris or opam coq-iris)."; exit 1)
	@rm -f /tmp/test_iris.v /tmp/test_iris.vo /tmp/test_iris.vok /tmp/test_iris.vos /tmp/test_iris.glob

check-lrust:
	@echo "Checking lambda-rust at $(LRUST_BASE)..."
	@test -f "$(LRUST_BASE)/lifetime/lifetime.vo" \
		&& test -f "$(LRUST_BASE)/lambda-rust/typing/typing.vo" \
		&& echo "lambda-rust .vo files found" \
		|| (echo "lambda-rust .vo files missing under LRUST_BASE; build lambda-rust or install it via opam."; exit 1)

check-all: check-iris check-lrust
