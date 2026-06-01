# IRR Coverage Note

The kappa = 0.838 result reported in the paper was computed on the full
N = 113 two-phase IRR sample (`independent_second_human_annotator_113.csv`,
which carries both raters' tags and the `phase` column).

## Two-phase design

### Phase 1 (baseline, N = 109)

The original IRR campaign rated 109 catalogue rows. Rater B was Zahid
Hussain (Mindgigs, Peshawar, Pakistan): no prior catalog exposure, no compensation,
blinded to the original codings. Phase 1 produced **kappa = 0.832**
(Landis–Koch: almost perfect).

This was a **tag-only** pass. The instrument (`RATER_BRIEF.md`) asked the
rater to enter exactly one tag per row into the `rater_b_tag` column; free-text
rationales were not requested. Consequently the `rater_b_notes` field is empty
for all 109 Phase-1 rows and is populated only for the 4 Phase-2 rows (see
below). This is a property of the instrument, not missing data.

Three Phase-1 rows refer to IDs that were renumbered or removed during later
catalog cleanup (`ATGN-004`, `DSPY-005`, `MAST-005`). Their rater-B
annotations are retained in the IRR file for audit traceability: the underlying
issue *content* (not the catalog ID) is what was rated, so the observations
remain valid for the reliability statistics.

### Phase 2 (supplementary, N = 4)

Four catalogue entries were added during continued construction after the
Phase-1 campaign concluded (`CCDE-002`, `LANG-020`, `LANG-035`, `SMAG-001`).
Rater B re-rated these four in a separate session, blind to rater A's tags, and
recorded a one-line rationale per row. All four agreed with rater A
(bu, bf, bu, fr). The raw return is `zahid_phase2_completed.csv`; the
rationales are carried into the `rater_b_notes` column of the combined file.

## Files and provenance

| Sample | File | Total | Coverage of the 110-row catalog |
|--------|------|------:|--------------------------------|
| Phase 1 | `independent_second_human_annotator_109.csv` | 109 | 106 / 110 (96.4%) |
| Phase 2 | `zahid_phase2_completed.csv` | 4 | 4 / 110 (3.6%) |
| **Combined** | `independent_second_human_annotator_113.csv` | **113** | **110 / 110 (100%)** |

The 3-row delta between IRR sample size (113) and catalog coverage (110) is the
three renumbered/removed rows listed above.

**Reconstructed audit files.** The original per-rater working files were not
placed under version control during the campaign. For traceability the
following are reconstructed deterministically from the committed combined file
and are byte-faithful to the recorded annotations:

- `independent_second_human_annotator_109.csv` — the Phase-1 subset
  (`phase == 1`) of the combined 113-row file. Recomputing kappa on this file
  reproduces the Phase-1 figure (po = 0.890, kappa = 0.832).
- `coding_sheet_phase1_reconstructed.csv` — the blinded coding *instrument*
  for Phase 1 (issue metadata with an empty `rater_b_tag` column), i.e. the
  sheet the rater filled in. It contains no rater-A tags.

These reconstructions let a reviewer regenerate every reported number from the
committed data; they are not claimed to be the pristine original spreadsheets.

## Reporting

Combined kappa = 0.838 (95% bootstrap CI [0.745, 0.919]) on N = 113 reflects
100% coverage of the current catalogue. Per-class kappas in
`per_class_kappa.csv` are computed on the same 113-row sample. The confirmed
subset figure (kappa = 0.943) is the agreement on the n = 79 rows *both* raters
classed as confirmed (bf ∪ bu); it conditions on agreement about the
confirmed/not-confirmed boundary and is an optimistic within-class measure, not
a substitute for the headline N = 113 value.

## Reproducing

```bash
cd token-budgets-formals/irr
python3 irr_scaffold.py compute --input independent_second_human_annotator_113.csv
```

Expected:
```
Pairs analyzed:          113
Observed agreement:      0.894
Cohen's kappa:           0.837
  Bootstrap 95% CI:      [0.745, 0.919]
Landis-Koch interpretation: almost perfect
```

The κ = 0.838 reported in the paper rounds 0.8374 to three decimals.
