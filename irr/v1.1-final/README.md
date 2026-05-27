# v1.1-final: 113-case re-annotation (PRIMARY v1.1 RESULT)

**Status**: PRIMARY v1.1 result. Referenced in paper section 5
(per-class kappa discussion) and section 8.3 M6 (EXECUTED status).
**Outcome**: (iii) per pre-committed decision rule.
**Headline figure**: kappa_fr_v1.1-final = 0.075 on N=113.

## Why this supersedes v1.1-draft

The v1.1-draft attempt (`../v1.1-draft/`) ran on a 22-case fr-only
subsample, which made Cohen's kappa mathematically degenerate
(rater A prevalence = 1.0). v1.1-final corrects this by re-rating the
full 113-case IRR sample, producing a mathematically meaningful kappa
that is comparable to the v1.0 published figure (kappa_fr_v1.0 = 0.727).

Codebook v1.1-final also retracts rule v1.1.1 (PR-linkage override),
which v1.1-draft had included. The retraction rationale is in
`codebook_v1_1_final.md` under "Correction notice". The retraction is
documented as being on independent semantic grounds (the rule conflated
"feature shipped via PR" with "bug fix shipped"); the retraction did
NOT produce a more favourable kappa, confirming the correction was
not result-chasing.

## Contents

| File | Description |
|---|---|
| `codebook_v1_1_final.md` | Revised v1.1 codebook (rule v1.1.1 retracted). Correction notice at top. |
| `generate_blinded_sheet_v3.py` | Generator that produced the 113-case blinded sheet (all four classes). |
| `compute_v1_1_kappa.py` | Pure-stdlib kappa computation script with the pre-committed decision rule baked in. |
| `blinded_coding_sheet_113cases.csv` | 113 rows sent to rater B; v1.0 labels stripped. |
| `returned_sheet_113cases.csv` | Rater B's filled-in v1.1 labels and rationales. **YOU MUST DROP THIS FILE IN FROM YOUR LOCAL MACHINE** (your m6 directory's `returned_sheet.csv` from the second run). |
| `kappa_v1_1_final_report.txt` | Pre-committed-rule output: kappa_fr = 0.075, outcome (iii), 81/113 reclassifications with per-case rationales. |
| `manifest_v1_1_final.txt` | SHA-256s of inputs and outputs at generation time. |

## Reproducibility

To re-verify the kappa values:
```bash
python3 compute_v1_1_kappa.py \
    --rater-b-sheet returned_sheet_113cases.csv \
    --hidden-labels [hidden labels file -- archived locally, not committed] \
    --report regenerated_report.txt
diff regenerated_report.txt kappa_v1_1_final_report.txt
```

The hidden labels file (`v1_0_labels_HIDDEN_v3.csv`) is gitignored
because it would leak the v1.0 labels for the blinded sheet. Anyone
wanting to verify the kappa can re-generate it from the source
catalogue (`../../data/budget-archaeology.csv`) by running
`generate_blinded_sheet_v3.py`; the produced hidden-labels file will
have the same SHA-256 as recorded in `manifest_v1_1_final.txt`.

## Reading guide for reviewers

The 81 reclassifications cluster along the bu->fr axis (74 of 81).
Rater B's "framing as request" criterion vs the v1.0 "documented
overrun" criterion is the substantive disagreement. See paper section 5
(per-class kappa breakdown) for the full interpretation.

The downstream catalogue claims (case-type counts, cluster mappings)
depend on the union bu cup bf cup mf cup fr being 113 issues across
21 frameworks. This union is invariant across both raters and both
codebooks; the bu/fr cut is a labelling convention.
