# token-budgets-formals

Mechanized formal verification and the inter-rater reliability (IRR) study for the *Token Budgets* paper, currently under review at *Empirical Software Engineering*.

This repository contains four independent verification artifacts and the complete IRR materials. Each is reproducible standalone; the parent paper integrates the results.

## Structure

```
.
├── verus/        # Verus mechanization (Rust + SMT). 66 obligations verified.
├── coq/          # Coq lemmas, including the partial mechanization of Conjecture 1.
├── tla/          # TLA+ specification and model-check config. 4,267 states.
├── dafny/        # Dafny proofs. 23 obligations verified.
├── irr/          # Inter-rater reliability study (κ = 0.832 on N = 109).
└── README.md
```

## Headline results

| Tier  | Tool        | Result                                          | Paper reference |
|-------|-------------|-------------------------------------------------|-----------------|
| 1     | Verus 0.6   | **66 obligations verified, 0 errors**           | §IV-D, Table 16 |
| 2     | Coq 8.19    | Partial Conjecture 1 + cap-soundness lemmas     | §IV-E           |
| 3     | TLA+ TLC    | 4,267 states, 0 violations                      | §IV-F           |
| 4     | Dafny 4.10  | 23 obligations verified                         | §IV-G           |
| —     | Human IRR   | **κ = 0.832 (N = 109), 95% CI [0.740, 0.916]**  | §3              |

## Tier 1: Verus

```bash
cd verus
verus src/lib.rs       # 42 verified, 0 errors
verus src/pool.rs      # 11 verified, 0 errors
verus src/concurrent.rs # 13 verified, 0 errors
```

The 66 obligations cover: budget conservation under split and merge, monotone consumption, receipt finality, pool reservation invariant, atomic commit/cancel/forget transitions, and a 3-thread interleaving lemma over Pool reservations.

Verus 0.6.0 or later is required. Install: see [verus-lang/verus](https://github.com/verus-lang/verus).

## Tier 2: Coq

```bash
cd coq
coq_makefile -f _CoqProject -o Makefile
make
```

The Coq development includes the cap-soundness theorem on the abstract operational semantics and a *partial* mechanization of Conjecture 1 (operational refinement to the running Tokio binary). Conjecture 1 is **open**; the full proof is identified as future work requiring multi-person-months of Coq/Iris effort.

Coq 8.19 or later is required.

## Tier 3: TLA+

```bash
cd tla
java -jar $TLA2TOOLS_JAR -modelcheck Budget.tla -config Budget.cfg
```

The TLA+ specification covers the Pool typestate machine and its concurrent reservation protocol. Model-checking with TLC explores all reachable states for the configured parameters and verifies the cap-soundness invariant.

`tla2tools.jar` is required. Download from [tlaplus/tlaplus](https://github.com/tlaplus/tlaplus/releases).

## Tier 4: Dafny

```bash
cd dafny
dafny verify *.dfy
```

The Dafny proofs cover an alternative axiomatic specification of the Budget abstract type, with method-level pre/post-conditions on `new`, `split`, `merge`, and `spend`. 23 verification obligations, all discharged.

Dafny 4.10 or later is required.

## IRR study

The `irr/` directory contains the complete materials for an independent dual-coded inter-rater reliability study on the 109-case failure catalog.

### Files

| File                                              | Purpose                                              |
|---------------------------------------------------|------------------------------------------------------|
| `budget-archaeology.csv`                          | The 167-row triage record (109 retained + 58 skipped) |
| `coding_sheet.csv`                                | The 109-row master with rater A's tags                |
| `_master_with_rater_a.csv`                        | Same as `coding_sheet.csv`, used by the merge script  |
| `coding_sheet_for_rater_b.csv`                    | Blank coding sheet sent to rater B (brief subset)     |
| `RATER_BRIEF.md`                                  | The written brief given to rater B                    |
| `codebook_v1.md`                                  | The formal codebook (4-tag taxonomy + 7 exclusion criteria) |
| `independent_second_human_annotator_109.csv`      | Rater B's completed annotations for all 109 rows      |
| `rater_b_done.csv`                                | Rater B's annotations for the brief subset            |
| `irr_scaffold.py`                                 | The IRR computation tool (Cohen's κ + bootstrap CI)   |
| `merge_and_compute.py`                            | One-shot script: merge + compute κ + list disagreements |

### Reproduce the κ = 0.832 result

```bash
cd irr
python3 merge_and_compute.py independent_second_human_annotator_109.csv
```

Expected output:

```
Pairs analyzed:          109
Observed agreement:      0.890
Cohen's kappa:           0.832
  Bootstrap 95% CI:      [0.740, 0.916]

Per-class agreement rate (rater A's coding as reference):
  bug_fixed_by_framework  : 0.923
  bug_unfixed             : 0.909
  feature_request         : 0.810
  maintainer_framing      : 0.857

Found 12 disagreements out of 109 rows.
```

The 12 disagreements (with full evidence trails for each) are emitted to stdout for adjudication. They are documented in the paper §3 with rater rationale.

### IRR methodology disclosure

- This is a **sequential re-annotation** IRR: rater A's coding was done first (during catalog construction); the formal codebook was prepared post-hoc; rater B independently re-coded all 109 cases against the codebook without seeing rater A's tags.
- This methodology is documented as a limitation in §3 of the paper. A fully independent dual-coding study (both raters coding in parallel from the start) is identified as future work.
- The codebook itself is `codebook_v1.md`. Version 1.1 will refine the `bu`/`fr` boundary on interrogative-feature-gap titles based on adjudication outcomes.

## Known issues

- **Conjecture 1** (the operational refinement of cap-soundness to a running Tokio binary) is open. The Coq development contains a partial mechanization; the abstract-trace soundness theorem is fully mechanized in Verus.
- **Assumption A1** (UTF-8 byte-length is a sound proxy for tokenizer output length under margin 2.0) is **calibrated, not formally proven**. The margin is load-bearing; at margin 1.0, A1 holds only 1/3 of cells. Mechanized proof of A1 for a defined class of BPE tokenizers is identified as future work.
- The IRR is a **sequential re-annotation** with codebook prepared post-rater-A coding; not a fully independent dual-coding from scratch.

## Citation

See the main repository [token-budgets](https://github.com/sajjadanwar0/token-budgets) for the BibTeX entry and paper reference.

## License

[Add license. CC-BY-4.0 recommended for data; Apache-2.0 OR MIT for code.]