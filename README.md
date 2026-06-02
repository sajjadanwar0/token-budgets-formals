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
├── irr/          # IRR: four-class kappa = 0.837 (N = 113) + exploratory cluster IRR (kappa = 0.44).
└── README.md
```

## Headline results

| Tool        | Result                                                  | Paper reference |
|-------------|--------------------------------------------------------|-----------------|
| TLAPS       | **497 obligations discharged** (Zenon+Isabelle)        | Appendix B.1    |
| TLC         | **252 states at B0=5, 0 violations** (exhaustive)      | Appendix B.1    |
| Verus 0.18  | **66 obligations, 0 errors** (source-level, preliminary)| Appendix B.1    |
| Coq / Dafny | Re-encodings of the same abstract spec (cross-tool)    | Appendix B.1    |
| Human IRR (four-class) | **kappa = 0.837 (N = 113), 95% CI [0.746, 0.917]** | §2.1, §5.27 |
| Cluster IRR (exploratory) | **kappa = 0.44 (N = 110)**; cost-observability 0.78 and multimodal 0.65 reliably identified | §2.5, limitations |

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

## IRR study

The `irr/` directory contains the complete materials for the two-phase
independent re-annotation of the catalogue (four-class scheme) and the
exploratory cluster-assignment IRR. See `irr/README.md` for the full file list.

### Four-class IRR (kappa = 0.837, N = 113) — validated

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
```

`python3 compute_irr.py` additionally reports the per-class one-vs-rest kappa
(bf 0.858, bu 0.876, mf 0.918, fr 0.727) and the **confirmed-subset kappa =
0.943 over the n = 79 incidents both raters marked confirmed** (bf-vs-bu).

### Cluster IRR (kappa = 0.44, N = 110) — exploratory

```bash
cd irr/cluster
python3 compute_cluster_kappa.py cluster_irr_rater_a_frozen.csv cluster_irr_rater_b_frozen.csv
```

The eight mechanism clusters are an exploratory, descriptive layer; the
independent cluster-assignment agreement is moderate (kappa = 0.44, 95% CI
[0.34, 0.55]), with cost-observability (0.78) and multimodal (0.65) reliably
identified and the remaining boundaries overlapping. `reproduce.sh` check 14b
reproduces 0.4440 from the two frozen independent codings (not the live
catalogue; see `irr/README.md`).

### IRR methodology disclosure

- The four-class study is a **two-phase independent re-annotation**: Phase 1
  (N=109 baseline) plus Phase 2 (N=4 entries added during continued
  construction), giving N=113 rater-pair observations over the 110 current
  catalogue rows. Rater B coded against the frozen codebook without seeing rater
  A's tags.
- The `fr`/`bu` boundary is the four-class codebook's weakest seam (kappa_fr =
  0.727).
- The cluster study is a single blind second-rater pass over all 110 rows
  against `cluster/cluster_codebook_v2.md`, reported as exploratory.

## Known issues

- **Conjecture 1** (binary-level refinement to the running Tokio binary) is
  **open**; the abstract-spec cap-soundness is cross-checked by TLAPS/TLC with a
  preliminary Verus source-level pass.
- **Assumption A1** is calibrated with a load-bearing 2.0× margin, not formally
  proven (paper §5.30–§5.31).

## License

Dual MIT/Apache-2.0.