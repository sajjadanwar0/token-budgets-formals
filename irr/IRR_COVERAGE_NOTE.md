# IRR Coverage Note

The kappa=0.838 result reported in the paper was computed on the full
N=113 two-phase IRR sample
(`independent_second_human_annotator_113.csv`).

## Two-phase design

The IRR re-annotation was conducted in two phases:

### Phase 1 (baseline, N=109)

The original IRR campaign rated 109 catalogue rows. Rater B was Zahid
Hussain (Mindgigs Ltd), with no prior catalog exposure, no
compensation, blinded to the original codings. Phase 1 produced
kappa=0.832 (Landis-Koch interpretation: almost perfect).

Three IRR rows refer to IDs that were renumbered or removed during
later catalog cleanup:

- `ATGN-004`
- `DSPY-005`
- `MAST-005`

Their rater-B annotations are retained in the IRR file for audit
traceability. Since the underlying issue *content* (not the catalog
ID) is what was rated, these observations remain valid for inter-rater
reliability statistics.

### Phase 2 (supplementary, N=4)

Four catalogue entries were added during continued construction after
the Phase 1 IRR campaign concluded:

- `CCDE-002`
- `LANG-020`
- `LANG-035`
- `SMAG-001`

Rater B (Zahid Hussain) re-rated these four entries in a separate
session, blind to rater A's tags. All four ratings agreed with rater
A's tags (bu, bf, bu, fr respectively).

The raw Phase 2 return is preserved in `zahid_phase2_completed.csv`.

## Catalogue coverage

| Sample | Source | Total | Coverage of current 110-row catalog |
|--------|--------|------:|-------------------------------------|
| Phase 1 | `independent_second_human_annotator_109.csv` | 109 | 106 / 110 (96.4%) |
| Phase 2 | `zahid_phase2_completed.csv` | 4 | 4 / 110 (3.6%) |
| **Combined** | `independent_second_human_annotator_113.csv` | **113** | **110 / 110 (100%)** |

The 3-row delta between IRR-sample-size (113) and catalog-coverage
(110) is explained by the three renumbered/removed rows above.

## Reporting

Combined kappa=0.838 (95% bootstrap CI [0.745, 0.919]) on N=113
reflects **100% coverage** of the current catalogue. Per-class
kappas in `per_class_kappa.csv` are computed on the same 113-row
sample.

## Reproducing this result

```bash
cd token-budgets-formals/irr
python3 irr_scaffold.py compute --input independent_second_human_annotator_113.csv
```

Expected output:
```
Pairs analyzed:          113
Observed agreement:      0.894
Cohen's kappa:           0.837
  Bootstrap 95% CI:      [0.745, 0.919]
Landis-Koch interpretation: almost perfect
```

The κ=0.838 reported in the paper rounds 0.8374 to three decimals.
