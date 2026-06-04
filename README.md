# Token Budgets — Formal Verification & Reliability

[![arXiv](https://img.shields.io/badge/arXiv-2606.04056-b31b1b.svg)](https://arxiv.org/abs/2606.04056)
[![DOI](https://img.shields.io/badge/DOI-10.48550%2FarXiv.2606.04056-blue.svg)](https://doi.org/10.48550/arXiv.2606.04056)

> **Paper:** Sajjad Khan, *Token Budgets: An Empirical Catalog of 63 LLM-Agent
> Budget-Overrun Incidents, with an Affine-Typed Rust Mitigation as a Case
> Study*, arXiv:2606.04056 [cs.SE], 2026. <https://arxiv.org/abs/2606.04056>

Mechanized proofs and inter-rater reliability for the
[`token-budgets`](https://github.com/sajjadanwar0/token-budgets) artifact.

## Contents

```
token-budgets-formals/
├── coq/         # Coq mechanization of the cap discipline (see coq/README.md)
├── dafny/       # Budget.dfy — Dafny model of the budget operations
├── verus/       # source-level Verus obligations (gen_obligations.sh, OBLIGATIONS.md)
└── irr/         # inter-rater reliability for the catalog taxonomy
    ├── irr_scaffold.py
    ├── independent_second_human_annotator_113.csv
    └── cluster/ # exploratory cluster-level IRR (frozen codings)
```

## Coq

A three-tier mechanization of the cap discipline (`budget-typed-cap`):
Tier A (pure Coq), Tier B (Iris Hoare triples), Tier C (lambda-rust semantic
typing), plus a `Print Assumptions` audit that closes with **zero `Admitted`,
zero `Axiom`**. Full build instructions, dependency setup, and troubleshooting
are in **`coq/README.md`** — note in particular that Iris, lambda-rust, and
this project must all be compiled by the same `coqc` (one opam switch).

```bash
cd coq
make tier-b                       # pure + Iris (no lambda-rust needed)
make all LRUST_BASE=~/lambda-rust # full build incl. lambda-rust + zero-axiom audit
```

## Dafny

```bash
cd dafny
dafny verify Budget.dfy
```

## Verus (optional, source-level)

```bash
cd verus
bash gen_obligations.sh           # regenerates OBLIGATIONS.md (66 obligations)
```

`OBLIGATIONS.md` ships pre-generated; the script reproduces it.

## Inter-rater reliability

The eight-cluster failure taxonomy in the paper is backed by an independent
second human annotator:

```bash
cd irr
python3 irr_scaffold.py compute --input independent_second_human_annotator_113.csv
# -> Cohen's kappa = 0.837 on N = 113
```

The `cluster/` subdirectory contains the exploratory cluster-level IRR over
frozen independent codings (overall kappa ~0.44; cost-observability 0.78 and
multimodal 0.65 are the reliable clusters). Use the **frozen** codings, not the
live catalog, to reproduce these numbers.

## Citation

```bibtex
@misc{khan2026tokenbudgets,
  title         = {Token Budgets: An Empirical Catalog of 63 LLM-Agent
                   Budget-Overrun Incidents, with an Affine-Typed Rust
                   Mitigation as a Case Study},
  author        = {Khan, Sajjad},
  year          = {2026},
  eprint        = {2606.04056},
  archivePrefix = {arXiv},
  primaryClass  = {cs.SE},
  doi           = {10.48550/arXiv.2606.04056},
  url           = {https://arxiv.org/abs/2606.04056}
}
```

## License

Paper: CC BY 4.0 (arXiv). Code/proofs: see the repository `LICENSE` file.