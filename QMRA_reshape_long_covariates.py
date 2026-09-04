#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
QMRA parameter database: wide -> long + context-covariate matrix

Input: QMRA_parameter_database.csv  (49 columns, 39 studies)
Output:
  1) QMRA_parameters_long.csv      one row = (study, parameter), 8 parameter groups; value_num is the
                                   machine-readable scalar (filled only when parseable)
  2) QMRA_context_covariates.csv   one row = 1 study, with the climate/production/cold-chain/population/
                                   dose-response-family/risk-basis fields needed for the Gower distance

Judgment-based fields (climate zone / production system / cold chain / population / dose-response family /
risk basis) are coded manually by domain knowledge, concentrated in the COV dictionary below for easy
review. Mechanical fields (has_growth, etc.) are determined automatically from the source text.
"""
import csv, re, os

SRC = os.path.join(os.path.dirname(os.path.abspath(__file__)), "QMRA_parameter_database.csv")
OUT_LONG = os.path.join(os.path.dirname(os.path.abspath(__file__)), "QMRA_parameters_long.csv")
OUT_COV  = os.path.join(os.path.dirname(os.path.abspath(__file__)), "QMRA_context_covariates.csv")

# ---------------------------------------------------------------------------
# 1) Manual coding: context covariates (reviewable)
#    Value sets:
#      commodity_group : poultry_meat | eggs | egg_product | offal | mixed
#      climate_zone    : temperate | subtropical | tropical | arid | mediterranean
#      production_sys  : intensive | retail | food_service | smallholder | processing
#      cold_chain      : full | partial | none | frozen
#      population      : general | susceptible
#      dr_family       : fao_who_2002 | who_feeding | egg_specific | virulence_stratified
#                      | ensemble | hierarchical | pfarm_dt | stochastic | exponential_bird | none
# ---------------------------------------------------------------------------
COV = {
    "37969349": dict(commodity_group="eggs",        climate_zone="temperate",    production_sys="intensive",    cold_chain="full",     population="general",     dr_family="egg_specific"),
    "38034810": dict(commodity_group="poultry_meat",climate_zone="subtropical",  production_sys="food_service", cold_chain="partial",  population="susceptible",dr_family="fao_who_2002"),
    "30479510": dict(commodity_group="poultry_meat",climate_zone="temperate",    production_sys="intensive",    cold_chain="partial",  population="general",     dr_family="who_feeding"),
    "41097550": dict(commodity_group="eggs",        climate_zone="arid",         production_sys="retail",       cold_chain="none",     population="susceptible",dr_family="pfarm_dt"),
    "19833032": dict(commodity_group="poultry_meat",climate_zone="temperate",    production_sys="retail",       cold_chain="partial",  population="general",     dr_family="fao_who_2003_set"),
    "34954835": dict(commodity_group="mixed",       climate_zone="subtropical",  production_sys="retail",       cold_chain="partial",  population="general",     dr_family="none"),
    "11028959": dict(commodity_group="eggs",        climate_zone="temperate",    production_sys="intensive",    cold_chain="full",     population="general",     dr_family="none"),
    "18260816": dict(commodity_group="egg_product", climate_zone="temperate",    production_sys="processing",   cold_chain="full",     population="general",     dr_family="fao_who_2002"),
    "36461177": dict(commodity_group="poultry_meat",climate_zone="subtropical",  production_sys="retail",       cold_chain="partial",  population="susceptible",dr_family="virulence_stratified"),
    "34086915": dict(commodity_group="offal",       climate_zone="temperate",    production_sys="retail",       cold_chain="full",     population="general",     dr_family="none"),
    "41097983": dict(commodity_group="poultry_meat",climate_zone="temperate",    production_sys="retail",       cold_chain="partial",  population="general",     dr_family="fao_who_2002"),
    "32599476": dict(commodity_group="poultry_meat",climate_zone="temperate",    production_sys="intensive",    cold_chain="full",     population="susceptible",dr_family="fao_who_2002"),
    "42155255": dict(commodity_group="poultry_meat",climate_zone="temperate",    production_sys="retail",       cold_chain="partial",  population="general",     dr_family="none"),
    "38309878": dict(commodity_group="poultry_meat",climate_zone="temperate",    production_sys="processing",   cold_chain="full",     population="general",     dr_family="ensemble"),
    "31099597": dict(commodity_group="poultry_meat",climate_zone="temperate",    production_sys="food_service", cold_chain="none",     population="general",     dr_family="who_feeding"),
    "38777091": dict(commodity_group="poultry_meat",climate_zone="temperate",    production_sys="processing",   cold_chain="full",     population="general",     dr_family="hierarchical"),
    "37075983": dict(commodity_group="offal",       climate_zone="temperate",    production_sys="processing",   cold_chain="full",     population="susceptible",dr_family="pfarm_dt"),
    "38360409": dict(commodity_group="offal",       climate_zone="temperate",    production_sys="retail",       cold_chain="partial",  population="general",     dr_family="none"),
    "38422679": dict(commodity_group="poultry_meat",climate_zone="tropical",     production_sys="smallholder",  cold_chain="none",     population="susceptible",dr_family="fao_who_2002"),
    "31734519": dict(commodity_group="poultry_meat",climate_zone="temperate",    production_sys="intensive",    cold_chain="full",     population="general",     dr_family="exponential_bird"),
    "12022671": dict(commodity_group="eggs",        climate_zone="temperate",    production_sys="intensive",    cold_chain="full",     population="susceptible",dr_family="stochastic"),
    "36617468": dict(commodity_group="poultry_meat",climate_zone="mediterranean",production_sys="retail",       cold_chain="frozen",   population="general",     dr_family="fao_who_2002"),
    "36230018": dict(commodity_group="pork",        climate_zone="tropical",     production_sys="retail",       cold_chain="partial",  population="general",     dr_family="fao_who_2002"),
    # --- 2026-09 data expansion (non-poultry/egg commodities + non-temperate countries) ---
    "30525084": dict(commodity_group="seafood",     climate_zone="tropical",     production_sys="aquaculture",  cold_chain="partial",  population="general",     dr_family="who_feeding"),
    "27837223": dict(commodity_group="pork",        climate_zone="tropical",     production_sys="smallholder",  cold_chain="none",     population="general",     dr_family="teunis_2010"),
    "28648297": dict(commodity_group="nuts",        climate_zone="arid",         production_sys="processing",   cold_chain="none",     population="general",     dr_family="fao_who_2002"),
    "35853833": dict(commodity_group="pork",        climate_zone="subtropical",  production_sys="retail",       cold_chain="partial",  population="general",     dr_family="fao_who_2002"),
    "31399019": dict(commodity_group="pork",        climate_zone="tropical",     production_sys="processing",   cold_chain="partial",  population="general",     dr_family="none"),
    "37061185": dict(commodity_group="beef",        climate_zone="temperate",    production_sys="processing",   cold_chain="full",     population="general",     dr_family="virulence_stratified"),
    "30144103": dict(commodity_group="pork",        climate_zone="temperate",    production_sys="retail",       cold_chain="partial",  population="general",     dr_family="fao_who_2002"),
    "26857423": dict(commodity_group="pork",        climate_zone="temperate",    production_sys="retail",       cold_chain="full",     population="general",     dr_family="fao_who_2002"),
    "24674430": dict(commodity_group="vegetables",  climate_zone="temperate",    production_sys="retail",       cold_chain="full",     population="general",     dr_family="none"),
    "26857651": dict(commodity_group="pork",        climate_zone="temperate",    production_sys="food_service", cold_chain="full",     population="general",     dr_family="none"),
    "26857531": dict(commodity_group="pork",        climate_zone="temperate",    production_sys="processing",   cold_chain="partial",  population="general",     dr_family="none"),
    "27002672": dict(commodity_group="pork",        climate_zone="temperate",    production_sys="intensive",    cold_chain="full",     population="general",     dr_family="none"),
    # --- 2026-09-03 four China pork studies ---
    "41819918": dict(commodity_group="pork",        climate_zone="subtropical",  production_sys="retail",       cold_chain="partial",  population="general",     dr_family="fao_who_2002"),
    "41655324": dict(commodity_group="pork",        climate_zone="temperate",    production_sys="retail",       cold_chain="partial",  population="general",     dr_family="fao_who_2002"),
    "38011665": dict(commodity_group="pork",        climate_zone="temperate",    production_sys="processing",   cold_chain="full",     population="general",     dr_family="fao_who_2002"),
    "42562523": dict(commodity_group="pork",        climate_zone="temperate",    production_sys="retail",       cold_chain="partial",  population="general",     dr_family="none"),
}

# single-value dose-response (α, β), for pooling / hierarchical Bayes; multi-tier / ensemble / none -> left empty
DR_NUM = {
    "37969349": (0.89,    4.4e5),
    "38034810": (0.1324,  51.45),
    "30479510": (0.3126,  2885),
    "18260816": (0.1324,  51.45),
    "41097983": (0.132,   51.45),
    "32599476": (0.1324,  51.45),
    "31099597": (0.3126,  2885),
    "38422679": (0.1324,  51.45),
    "36617468": (0.1324,  51.45),
    "36230018": (0.1324,  51.45),
    "30525084": (0.3126,  2884),
    "27837223": (0.0085,  3.14),
    "28648297": (0.1324,  51.45),
    "35853833": (0.1324,  51.45),
    "30144103": (0.1324,  51.45),
    "26857423": (0.1324,  51.45),
    "41819918": (0.1324,  51.45),
    "41655324": (0.1324,  51.45),
    "38011665": (0.1324,  51.45),
}

# Simulation software + fitting method (grep from the PDF full-text methods sections, 2026-09)
#   simulation_software : @RISK(Palisade) | @RISK/PFARM | @RISK + JAGS | R(mc2d) | R(rstan) | R(fitdistrplus) | none
#   fitting_method      : MLE | hierarchical Bayes (JAGS/Stan) | scenario-tree Bayes | bootstrap, etc.; left empty if unconfirmed
SIM_SOFT = {
    "37969349": "@RISK",           "38034810": "@RISK",           "30479510": "@RISK",
    "41097550": "@RISK/PFARM",     "19833032": "@RISK",           "11028959": "@RISK",
    "18260816": "@RISK",           "36461177": "@RISK",           "34086915": "@RISK/PFARM",
    "41097983": "@RISK",           "32599476": "@RISK",           "31099597": "@RISK",
    "38777091": "@RISK + JAGS",    "37075983": "@RISK/PFARM",     "38360409": "@RISK/PFARM",
    "38422679": "@RISK",           "12022671": "@RISK",
    "42155255": "R(fitdistrplus)", "38309878": "R(mc2d)",         "31734519": "R(rstan)",
    "36617468": "R(mc2d)",         "34954835": "none",
    "36230018": "Simulacion 4.0 (Monte Carlo)",
    "30144103": "R (2D Monte Carlo)",
    "41819918": "@RISK",            "41655324": "@RISK",            "38011665": "@RISK",
}
FIT_METHOD = {
    "32599476": "MLE",                              "11028959": "MLE + scenario-tree Bayes",
    "18260816": "MLE",                              "42155255": "MLE + hierarchical Bayes + bootstrap",
    "36617468": "MLE(fitdistrplus)",                "38309878": "MLE + 2D Monte Carlo",
    "38777091": "hierarchical Bayes (JAGS)",        "31734519": "Bayes (Stan) + bootstrap",
    "36230018": "Monte Carlo (Simulacion 4.0)",
    "30144103": "2D Monte Carlo (R, variability/uncertainty separated)",
    "41819918": "Monte Carlo (100,000 iterations)",
    "41655324": "Monte Carlo (10,000 iterations)",
    "38011665": "Latin hypercube sampling",
}

# Risk-output basis (LOCO needs units aligned first; here we only annotate the basis, no forced normalization)
RISK_BASIS = {
    "37969349": "per_serving",      "38034810": "per_100k_infection",
    "30479510": "per_month_prob",   "41097550": "per_100k_meals",
    "19833032": "per_serving",      "11028959": "fraction_contaminated",
    "18260816": "annual_count",     "36461177": "annual_count",
    "41097983": "per_100k_meals",   "32599476": "per_100k_servings",
    "38309878": "per_serving",      "38777091": "per_serving",
    "38422679": "per_100k_yr",      "12022671": "annual_count",
    "36617468": "relative_MRRR",
    "36230018": "per_serving",
    "30525084": "annual_infection_prob",
    "27837223": "annual_incidence",
    "28648297": "annual_cases",
    "35853833": "annual_cases_per_million",
    "31399019": "",
    "37061185": "annual_illness",
    "30144103": "per_serving",
    "26857423": "per_serving",
    "24674430": "annual_cases",
    "26857651": "per_serving",
    "26857531": "",
    "27002672": "per_serving_infection",
    "41819918": "annual_cases_per_million",
    "41655324": "annual_cases_per_million",
    "38011665": "per_serving_infection",
    "42562523": "annual_count",
}

# ---------------------------------------------------------------------------
# 2) parameter group -> column mapping (for the long table)
# ---------------------------------------------------------------------------
PARAM_GROUPS = {
    "prevalence":         ["prev_stage","prev_value","prev_dist","prev_dist_params","prev_source"],
    "concentration":      ["conc_unit","conc_dist","conc_mean","conc_sd","conc_source"],
    "growth":             ["growth_model","growth_mu_opt","growth_Tmin","growth_Tmax","growth_lag","growth_source"],
    "inactivation":       ["inact_D_ref","inact_z","inact_log_reduction","inact_source"],
    "cross_contamination":["cross_contam_rate","cross_contam_dist","cross_contam_source"],
    "consumption":        ["serving_size_g","serving_size_dist","frequency","cooking_storage"],
    "dose_response":      ["dr_model","dr_alpha","dr_beta","dr_r","dr_source"],
    "risk_output":        ["predicted_risk","risk_unit","validated","validation_source"],
}

NUM_RE = re.compile(r"^[-+]?(\d+\.?\d*|\.\d+)([eE][-+]?\d+)?$")

def try_num(s):
    if not s:
        return None
    t = s.strip().replace(",", "").replace("%", "")
    t = re.sub(r"\s+[a-zA-Z]+$", "", t).strip()   # strip trailing unit word
    return float(t) if NUM_RE.match(t) else None

def main():
    with open(SRC, encoding="utf-8-sig", newline="") as f:
        rows = list(csv.DictReader(f))

    # the "source" column for each parameter group (consumption has no source column)
    GROUP_SOURCE = {
        "prevalence": "prev_source",
        "concentration": "conc_source",
        "growth": "growth_source",
        "inactivation": "inact_source",
        "cross_contamination": "cross_contam_source",
        "consumption": None,
        "dose_response": "dr_source",
        "risk_output": "validation_source",
    }

    # ---------------- long table ----------------
    long_rows = []
    for r in rows:
        pid = r["pmid"]
        for group, cols in PARAM_GROUPS.items():
            src_col = GROUP_SOURCE[group]
            src = (r.get(src_col) or "").strip() if src_col else ""
            for col in cols:
                raw = (r.get(col) or "").strip()
                if not raw:
                    continue
                long_rows.append({
                    "pmid": pid,
                    "first_author": r["first_author"],
                    "year": r["year"],
                    "country_region": r["country_region"],
                    "food_commodity": r["food_commodity"],
                    "param_group": group,
                    "param_name": col,
                    "value_raw": raw,
                    "value_num": try_num(raw) if try_num(raw) is not None else "",
                    "source": src,
                })

    with open(OUT_LONG, "w", encoding="utf-8-sig", newline="") as f:
        w = csv.DictWriter(f, fieldnames=[
            "pmid","first_author","year","country_region","food_commodity",
            "param_group","param_name","value_raw","value_num","source"])
        w.writeheader()
        w.writerows(long_rows)

    # ---------------- context-covariate matrix ----------------
    cov_rows = []
    for r in rows:
        pid = r["pmid"]
        c = COV.get(pid, {})
        dr = DR_NUM.get(pid)
        cov_rows.append({
            "pmid": pid,
            "first_author": r["first_author"],
            "year": r["year"],
            "country_region": r["country_region"],
            "food_commodity": r["food_commodity"],
            "commodity_group": c.get("commodity_group",""),
            "climate_zone": c.get("climate_zone",""),
            "production_sys": c.get("production_sys",""),
            "cold_chain": c.get("cold_chain",""),
            "population": c.get("population",""),
            "dr_family": c.get("dr_family",""),
            "dr_alpha_num": dr[0] if dr else "",
            "dr_beta_num":  dr[1] if dr else "",
            "has_growth":       int(bool((r.get("growth_model") or "").strip())),
            "has_inactivation": int(bool((r.get("inact_D_ref") or r.get("inact_z") or r.get("inact_log_reduction") or "").strip())),
            "has_cross_contam": int(bool((r.get("cross_contam_rate") or r.get("cross_contam_dist") or "").strip())),
            "validated":        1 if (r.get("validated") or "").strip().lower().startswith("yes") else 0,
            "is_full_qmra":     int(bool((r.get("predicted_risk") or "").strip() and (r.get("dr_model") or "").strip())),
            "risk_basis": RISK_BASIS.get(pid, ""),
            "risk_value_raw": (r.get("predicted_risk") or "").strip(),
            "simulation_software": SIM_SOFT.get(pid, ""),
            "fitting_method": FIT_METHOD.get(pid, ""),
        })

    with open(OUT_COV, "w", encoding="utf-8-sig", newline="") as f:
        w = csv.DictWriter(f, fieldnames=[
            "pmid","first_author","year","country_region","food_commodity",
            "commodity_group","climate_zone","production_sys","cold_chain","population",
            "dr_family","dr_alpha_num","dr_beta_num",
            "has_growth","has_inactivation","has_cross_contam","validated","is_full_qmra",
            "risk_basis","risk_value_raw","simulation_software","fitting_method"])
        w.writeheader()
        w.writerows(cov_rows)

    # ---------------- summary ----------------
    print(f"long-table rows: {len(long_rows)}")
    print(f"covariate-matrix rows: {len(cov_rows)}")
    print()
    from collections import Counter
    print("dose-response family distribution:")
    for k, v in Counter(r["dr_family"] for r in cov_rows).most_common():
        print(f"  {k:<22} {v}")
    print()
    print("risk-basis distribution (studies with a predicted risk):")
    for k, v in Counter(r["risk_basis"] for r in cov_rows if r["risk_basis"]).most_common():
        print(f"  {k:<24} {v}")
    print()
    print("full farm-to-fork QMRA (has risk + DR):", sum(r["is_full_qmra"] for r in cov_rows), "/", len(cov_rows))
    print("single-value dose-response (poolable):", sum(1 for r in cov_rows if r["dr_alpha_num"] != ""))
    print()
    print("simulation software distribution:")
    for k, v in Counter(r["simulation_software"] for r in cov_rows if r["simulation_software"]).most_common():
        print(f"  {k:<20} {v}")
    print("studies with a fitting-method annotation:", sum(1 for r in cov_rows if r["fitting_method"]))

if __name__ == "__main__":
    main()
