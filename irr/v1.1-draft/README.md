# v1.1-draft: 22-case fr-only re-annotation (SUPERSEDED)

**Status**: SUPERSEDED by `../v1.1-final/` on 2026-05-27.
**Reason**: mathematically degenerate kappa (rater A prevalence = 1.0
on a single-class subsample makes Cohen's kappa = 0 by construction,
regardless of the actual reclassification pattern). See
`kappa_v1_1_draft_report.txt` "METHODOLOGICAL DIAGNOSIS" section.

This directory is retained for transparency about the methodological
iteration documented in the paper's section 8.3 M6 paragraph
("EXECUTED 2026-05-27, outcome (iii)" + "Protocol iteration" sub-paragraph).

## Contents

| File | Description |
|---|---|
| `codebook_v1_1_draft.md` | Initial v1.1 codebook with rule v1.1.1 (PR-linkage override). Rule v1.1.1 retracted in v1.1-final on independent semantic grounds. |
| `generate_blinded_sheet_v2.py` | Generator that produced the 22-case blinded sheet (filtered to v1.0-fr cases only). |
| `blinded_coding_sheet_22cases.csv` | 22 rows sent to rater B; v1.0 labels stripped. |
| `returned_sheet_22cases.csv` | Rater B's filled-in v1.1 labels and rationales. **YOU MUST DROP THIS FILE IN FROM YOUR LOCAL MACHINE** (your m6 directory's `returned_sheet.csv` from the first run). |
| `kappa_v1_1_draft_report.txt` | Pre-committed-rule output: kappa = 0.000, outcome (iii), 15/22 reclassifications. |
| `manifest_v1_1_draft.txt` | SHA-256s of inputs and outputs at generation time. |

## What this attempt did NOT do
- Did not produce a publishable kappa figure (mathematically degenerate)
- Did not survive methodological review of rule v1.1.1
- Did not contribute to paper's reported numbers

## What this attempt DID contribute
- Identified the subsample-filtering protocol flaw (corrected in v1.1-final)
- Identified rule v1.1.1 as semantically aggressive (retracted in v1.1-final)
- Demonstrated the pre-registration's decision rule fires mechanically

See `../v1.1-final/` for the primary v1.1 result that the paper reports.
