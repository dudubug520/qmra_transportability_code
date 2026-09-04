# Data dictionary

## `QMRA_parameter_database.csv` (39 studies × 49 columns)

The main parameter-extraction table. Columns are grouped as follows:

| Field group | Columns | Content |
|---|---|---|
| Metadata | `pmid`, `first_author`, `year`, `journal`, `pathogen`, `food_commodity`, `country_region`, `context_desc` | Source and context |
| Prevalence | `prev_stage`, `prev_value`, `prev_dist`, `prev_dist_params`, `prev_source` | Prevalence at each stage |
| Concentration | `conc_unit`, `conc_dist`, `conc_mean`, `conc_sd`, `conc_source` | Contamination concentration |
| Growth / inactivation | `growth_*`, `inact_*` | Kinetics (μ_opt, Tmin/Tmax, D, z, log-reduction) |
| Cross-contamination / consumption | `cross_contam_*`, `serving_size_*`, `frequency`, `cooking_storage` | Exposure pathway |
| Dose–response | `dr_model`, `dr_alpha`, `dr_beta`, `dr_r`, `dr_source` | Dose–response mechanism (invariant) |
| Output | `predicted_risk`, `risk_unit`, `validated`, `validation_source` | Predicted risk and validation |
| **Context covariates** | `cov_production_system`, `cov_climate_zone`, `cov_cold_chain`, `cov_population_susceptibility`, `cov_model_assumptions` | Basis for the transfer decision |

The dose–response family (`dr_family` in the covariate matrix) encodes the canonical curves referenced in the paper (e.g. `fao_who_2002`, `who_feeding`, `egg_specific`, `virulence_stratified`, `teunis_2010`). A value of `none` marks a study that reports no dose–response.

## `QMRA_context_covariates.csv` (39 studies × 21 columns)

Context covariates and derived fields: the categorical covariates above (production system, climate zone, cold chain, population susceptibility), plus the numerical dose–response family/parameters (`dr_family`, `dr_alpha`, `dr_beta`, `dr_r`) and the risk basis (`risk_basis`).

## `QMRA_parameters_long.csv`

Long-form parameter values (one value per row), produced by `code/QMRA_reshape_long_covariates.py`.

## `QMRA_LOCO_risk_normalized.csv`

Per-serving illness probability normalized to a common endpoint, used for the leave-one-context-out test (n = 11 studies).

## `QMRA_Salmonella_search_results.csv`

The 108 PubMed *Salmonella* records from the primary search (columns: index, PMID, year, title, journal), used to construct the PRISMA flow (Fig. 1).
