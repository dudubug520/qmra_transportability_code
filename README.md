# Causal transportability of *Salmonella* QMRA — code and data

This repository accompanies the manuscript:

> **Causal transportability of *Salmonella* quantitative microbial risk assessment: a selection-diagram criterion and an extrapolation-error estimate for China**

It contains the analysis and figure-generation scripts (`code/`) and the 39-study parameter database (`data/`) that reproduce the results in the paper.

## Contents


code/     R and Python scripts (analysis + figures + Table 1)
data/     parameter database, context covariates, and search records (Table S1)


## Requirements

**R** (≥ 4.x) with: `bnlearn`, `gRain`, `brms`, `rstan`, `dagitty`.

**Python** 3 with: `pandas`, `numpy` (optionally `pgmpy`, `pymc` for the BN equivalent).

## Reproduction

| Result | Script |
|---|---|
| Selection diagram (Fig. 2) | `code/QMRA_selection_diagram.R` |
| Dose–response decomposition (Δ_DR) | `code/QMRA_dose_response_decomposition.R` |
| Exposure-pathway decomposition (Δ_exp) | `code/QMRA_exposure_pathway_decomposition.R` |
| Leave-one-context-out (LOCO) test | `code/QMRA_LOCO_real.R` (n = 11), `code/QMRA_LOCO_synthetic.R` (8 synthetic contexts) |
| Figures 1, 3, 4 | `code/QMRA_Figures.R` |
| Table 1 | `code/QMRA_Table1.py` |
| BN skeleton / transport-formula numerical check | `code/QMRA_bn_skeleton.R` |
| Long-table and covariate construction | `code/QMRA_reshape_long_covariates.py` |

`_append_qmra_rows.py` is a data-entry helper used while assembling the 39-study database; it is not needed to reproduce the reported results.

## Data

- `data/QMRA_parameter_database.csv` — 39 studies × 49 columns, the main parameter-extraction table.
- `data/QMRA_context_covariates.csv` — 39 studies × 21 columns, context covariates + numerical dose–response + risk basis.
- `data/QMRA_parameters_long.csv` — long-form parameters (one value per row).
- `data/QMRA_LOCO_risk_normalized.csv` — per-serving illness probability normalized for the LOCO test.
- `data/QMRA_Salmonella_search_results.csv` — the 152 PubMed *Salmonella* records from the search.
- `data/QMRA_WoS_search_results.txt` — the 356-record Web of Science (Core Collection) export of the same search (351 with DOI; 128 shared with PubMed by DOI, leaving 380 unique records).

Column descriptions are in `data/README.md`.

## License

Code: MIT. Data: CC-BY 4.0. *(choose and add the corresponding files before publishing)*
