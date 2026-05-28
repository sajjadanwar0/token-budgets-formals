# token-budgets-formals

Mechanised specification cross-checks and the inter-rater reliability (IRR)
study for the *Token Budgets* paper (preprint, 2026).

This repository contains the abstract-specification mechanisations and the
complete IRR materials. The mechanisations cross-check the abstract state
machine's internal consistency across multiple logics; they are **consistency
evidence on the abstract specification, not an end-to-end source-to-binary
proof**. The binary-level claim is Conjecture 1, deliberately open.

## Structure

```
.
├── verus/        # Verus source-level mechanisation. 66 obligations, 0 errors (preliminary).
├── coq/          # Coq re-encoding + partial Conjecture-1 skeleton.
├── tla/          # TLA+ spec; TLAPS deductive proof + TLC model check.
├── dafny/        # Dafny re-encoding of the same abstract spec.
├── irr/          # Inter-rater reliability study (kappa = 0.837 on N = 113).
└── README.md
```

## Headline results

| Tool        | Result                                                  | Paper reference |
|-------------|--------------------------------------------------------|-----------------|
| TLAPS       | **497 obligations discharged** (Zenon+Isabelle)        | Appendix B.1    |
| TLC         | **252 states at B0=5, 0 violations** (exhaustive)      | Appendix B.1    |
| Verus 0.18  | **66 obligations, 0 errors** (source-level, preliminary)| Appendix B.1    |
| Coq / Dafny | Re-encodings of the same abstract spec (cross-tool)    | Appendix B.1    |
| Human IRR   | **kappa = 0.837 (N = 113), 95% CI [0.746, 0.917]**     | §2.1, §5.27     |

> Coq/Dafny re-verify the same invariants in additional logics rather than
> establishing new guarantees, so per-tool obligation counts for them are not
> headline numbers. TLAPS (497) and TLC (252 states) are the primary
> abstract-spec cross-checks; Verus (66) is the preliminary source-level pass.

## Tier 1: Verus (source-level, preliminary)

```bash
cd verus
verus src/lib.rs         # 42 obligations, 0 errors
verus src/pool.rs        # 11 obligations, 0 errors
verus src/concurrent.rs  # 13 obligations, 0 errors
```

The 66 obligations cover budget conservation under split/merge, monotone
consumption, receipt finality, the pool reservation invariant, and a concurrent
trace lemma. Verus 0.18+ required. This result is preliminary and externally
unaudited; the Verus trust base (Z3, ghost erasure, VerusBelt) is documented in
the paper §5.34.

## Tier 2: TLA+ (TLAPS + TLC)

```bash
cd tla
# Deductive proof (TLAPS): 497 obligations
tlapm Budget.tla
# Exhaustive model check (TLC): 252 states at B0=5
java -jar $TLA2TOOLS_JAR -modelcheck Budget.tla -config Budget.cfg
```

The eight `Budget` transitions over the six-variable conservation ledger.
Adding the receipt path expanded the obligation count from 324 (spend-only) to
497; all close on the default backend chain.

## Tier 3: Coq and Dafny (cross-tool re-encodings)

```bash
cd coq   && coq_makefile -f _CoqProject -o Makefile && make
cd dafny && dafny verify *.dfy
```

These re-encode the same abstract specification for cross-tool confirmation.
The Coq development additionally carries a partial skeleton for Conjecture 1
(operational refinement to the running Tokio binary), which is **open**.

## IRR study (kappa = 0.837, N = 113)

The `irr/` directory contains the complete materials for the two-phase
independent re-annotation of the catalogue.

| File                                          | Purpose                                            |
|-----------------------------------------------|----------------------------------------------------|
| `codebook_v1.md`                              | The frozen codebook (4-tag taxonomy + 7 exclusions)|
| `blinded_coding_sheet.csv`                    | Blank sheet given to rater B                        |
| `independent_second_human_annotator_113.csv`  | Rater B's completed annotations (two-phase, N=113)  |
| `per_class_kappa.csv`                         | Per-class one-vs-rest κ                              |
| `irr-disagreements.md`                        | The 12 full-sample disagreements + adjudications     |
| `irr_scaffold.py`                             | Cohen's κ + bootstrap-CI computation tool           |
| `v1.1-draft/`, `v1.1-final/`                  | Superseded/primary v1.1 sharpening attempts (audit) |

### Reproduce the kappa = 0.837 result

```bash
cd irr
python3 irr_scaffold.py compute --input independent_second_human_annotator_113.csv
```

Expected output:

```
Pairs analyzed:          113
Observed agreement:      0.894
Cohen's kappa:           0.837
  Bootstrap 95% CI:      [0.746, 0.917]

Per-class one-vs-rest kappa:
  bug_fixed_by_framework (bf) : 0.858  (n=27)
  bug_unfixed            (bu) : 0.876  (n=57)
  maintainer_framing     (mf) : 0.918  (n=7)
  feature_request        (fr) : 0.727  (n=22)
Confirmed-bugs subset (bf u bu): kappa = 0.943 (n=84)
```

### IRR methodology disclosure

- This is a **two-phase independent re-annotation**: Phase 1 (N=109 baseline)
  plus Phase 2 (N=4 entries added during continued construction), giving N=113
  rater-pair observations over the 110 current catalogue rows. Rater B coded
  against the frozen codebook without seeing rater A's tags.
- The `fr`/`bu` boundary is the codebook's weakest seam (κ_fr = 0.727); the
  v1.1 sharpening attempt is committed under `v1.1-draft/` and `v1.1-final/` for
  transparency. A fully parallel dual-coding study under a post-v1.0 codebook is
  identified as catalogue-v2 follow-up.

## Known issues

- **Conjecture 1** (binary-level refinement to the running Tokio binary) is
  **open**; the abstract-spec cap-soundness is cross-checked by TLAPS/TLC with a
  preliminary Verus source-level pass.
- **Assumption A1** is calibrated with a load-bearing 2.0× margin, not formally
  proven (paper §5.30–§5.31).

## License

Dual MIT/Apache-2.0.