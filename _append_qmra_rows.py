#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Append newly extracted QMRA rows to QMRA_parameter_database.csv. One dict per study; comment them out after appending."""
import csv, os

CSV = os.path.join(os.path.dirname(os.path.abspath(__file__)), "QMRA_parameter_database.csv")

FN = ['pmid','first_author','year','journal','pathogen','food_commodity','country_region',
      'context_desc','prev_stage','prev_value','prev_dist','prev_dist_params','prev_source',
      'conc_unit','conc_dist','conc_mean','conc_sd','conc_source',
      'growth_model','growth_mu_opt','growth_Tmin','growth_Tmax','growth_lag','growth_source',
      'inact_D_ref','inact_z','inact_log_reduction','inact_source',
      'cross_contam_rate','cross_contam_dist','cross_contam_source',
      'serving_size_g','serving_size_dist','frequency','cooking_storage',
      'dr_model','dr_alpha','dr_beta','dr_r','dr_source',
      'predicted_risk','risk_unit','validated','validation_source',
      'cov_production_system','cov_climate_zone','cov_cold_chain',
      'cov_population_susceptibility','cov_model_assumptions']

ROWS = [
    dict(pmid="41819918", first_author="Li Bai", year="2026",
         journal="Food Research International", pathogen="Salmonella (nontyphoid, NTS)",
         food_commodity="retail pork", country_region="China (Hunan/Sichuan and other provinces)",
         context_desc="subtropical; China retail pork; high prevalence; cutting-board cross-contamination dominates",
         prev_stage="retail pork", prev_value="Hunan 72.66% / Sichuan 62.34%",
         prev_dist="", prev_dist_params="", prev_source="market survey (multi-province)",
         conc_unit="log CFU/g", conc_dist="", conc_mean="0.0079 (mean) / north 0.0247 / south 0.1520",
         conc_sd="", conc_source="quantitative culture",
         growth_model="transport + storage growth", growth_mu_opt="", growth_Tmin="", growth_Tmax="",
         growth_lag="", growth_source="transport/storage conditions",
         inact_D_ref="", inact_z="", inact_log_reduction="cooking", inact_source="pre-consumption cooking",
         cross_contam_rate="", cross_contam_dist="", cross_contam_source="pork-to-cutting-board transfer rate (most sensitive factor)",
         serving_size_g="", serving_size_dist="", frequency="",
         cooking_storage="household cooking",
         dr_model="Beta-Poisson", dr_alpha="0.1324", dr_beta="51.45", dr_r="",
         dr_source="WHO/FAO 2002",
         predicted_risk="2526 cases/million/year (95% CI 2475-2578)",
         risk_unit="annual incidence (per million)", validated="", validation_source="",
         cov_production_system="retail",
         cov_climate_zone="subtropical (Hunan/Sichuan)",
         cov_cold_chain="partial", cov_population_susceptibility="general",
         cov_model_assumptions="WHO/FAO DR; cutting-board cross-contamination dominates; multi-province stratified"),
    dict(pmid="41655324", first_author="Shounan Zhang", year="2026",
         journal="International Journal of Food Microbiology", pathogen="Salmonella (nontyphoid, NTS)",
         food_commodity="pork (household)", country_region="China (national)",
         context_desc="China national household pork; disease burden (DALY); MDR-NTS; wet markets 60.3%",
         prev_stage="retail (wet markets + supermarkets)", prev_value="pooled 17% (7-46% across provinces)",
         prev_dist="", prev_dist_params="", prev_source="literature pooling",
         conc_unit="log CFU/g", conc_dist="", conc_mean="", conc_sd="",
         conc_source="retail pork concentration",
         growth_model="transport growth (0.022*(T1.w-5.93))^2", growth_mu_opt="", growth_Tmin="",
         growth_Tmax="", growth_lag="", growth_source="consumer transport temperature rise (Jeong 2018)",
         inact_D_ref="", inact_z="", inact_log_reduction="cooking", inact_source="household cooking",
         cross_contam_rate="", cross_contam_dist="", cross_contam_source="household cross-contamination",
         serving_size_g="", serving_size_dist="", frequency="wet markets 60.3% / supermarkets 39.7%",
         cooking_storage="18% ambient storage; household cooking",
         dr_model="Beta-Poisson", dr_alpha="0.1324", dr_beta="51.45", dr_r="",
         dr_source="WHO/FAO 2002",
         predicted_risk="2643 cases/million/year (95% CI 2498-2790); 16,597 DALYs (15,627-17,567); MDR 91.8%",
         risk_unit="cases/million + DALY", validated="", validation_source="",
         cov_production_system="retail (wet markets + supermarkets -> household)",
         cov_climate_zone="temperate (China national)", cov_cold_chain="partial (18% ambient)",
         cov_population_susceptibility="general",
         cov_model_assumptions="WHO/FAO DR; MDR-NTS disease burden; transport growth model; wet-market dominated"),
    dict(pmid="38011665", first_author="Huimin Cheng", year="2024",
         journal="Foodborne Pathogens and Disease", pathogen="Salmonella (nontyphoid)",
         food_commodity="breaded pork products", country_region="China",
         context_desc="breaded pork products (battered/fried/quick-frozen); 4C cold chain; low infection risk",
         prev_stage="processing (cutting/battering/frying)", prev_value="cutting 66.7% / peak 60.5%; product 41.3%",
         prev_dist="", prev_dist_params="20/30, 26/43, 63/153", prev_source="sampling at each processing stage",
         conc_unit="MPN/g", conc_dist="", conc_mean="0.1532-0.3027 (cutting) / 0.3111-0.8921 (peak)",
         conc_sd="", conc_source="MPN (USDA/FSIS)",
         growth_model="1/k=0.03568T-0.17322", growth_mu_opt="", growth_Tmin="", growth_Tmax="",
         growth_lag="", growth_source="square-root model",
         inact_D_ref="", inact_z="", inact_log_reduction="frying/quick-freezing; microwave thawing reduces by 30.969-fold", inact_source="frying + quick-freezing + thawing",
         cross_contam_rate="", cross_contam_dist="", cross_contam_source="",
         serving_size_g="", serving_size_dist="", frequency="",
         cooking_storage="4C cold chain (packaging to consumption)",
         dr_model="Beta-Poisson", dr_alpha="0.1324", dr_beta="51.45", dr_r="",
         dr_source="WHO/FAO 2002 (Pill=1-(1+DOSE/b)^-a)",
         predicted_risk="infection probability 5.585e-9/meal (0.001% undercooked eaten raw)",
         risk_unit="infection/meal", validated="", validation_source="",
         cov_production_system="processing (breaded-product processing)",
         cov_climate_zone="temperate (China)", cov_cold_chain="full (4C cold chain)",
         cov_population_susceptibility="general",
         cov_model_assumptions="WHO/FAO DR; infection endpoint; frying/quick-freezing inactivation; 0.001% raw-eating fraction"),
    dict(pmid="42562523", first_author="Chen Xu", year="2026",
         journal="Food Research International", pathogen="Salmonella (serotype-stratified)",
         food_commodity="pork (farm-to-consumption)", country_region="China (national, regionalized)",
         context_desc="meta-analysis + QMRA; China pig farm -> consumption; regional differences; serotype risk ranking",
         prev_stage="live pigs/pig feces (meta)", prev_value="live pigs 8.1% (5.43-11.91) / pig feces 13.29% (9.19-18.69)",
         prev_dist="", prev_dist_params="meta-pooled", prev_source="published prevalence meta-analysis",
         conc_unit="", conc_dist="", conc_mean="", conc_sd="", conc_source="",
         growth_model="", growth_mu_opt="", growth_Tmin="", growth_Tmax="", growth_lag="", growth_source="",
         inact_D_ref="", inact_z="", inact_log_reduction="", inact_source="",
         cross_contam_rate="", cross_contam_dist="", cross_contam_source="household kitchen cross-contamination",
         serving_size_g="", serving_size_dist="", frequency="",
         cooking_storage="farm-to-consumption",
         dr_model="Beta-Poisson", dr_alpha="", dr_beta="", dr_r="",
         dr_source="Beta-Poisson (abstract gives no alpha/beta)",
         predicted_risk="3.46e6 cases/year (China pork-attributable); highest in the west; S. Typhimurium first",
         risk_unit="annual cases (China national)", validated="", validation_source="",
         cov_production_system="retail (farm-to-consumption)",
         cov_climate_zone="temperate (China national, regionalized)", cov_cold_chain="partial",
         cov_population_susceptibility="general",
         cov_model_assumptions="abstract-level data (1-page PDF); meta prevalence; serotype risk ranking; alpha/beta not extracted"),
]

def main():
    existing = set()
    if os.path.exists(CSV):
        with open(CSV, encoding="utf-8-sig", newline="") as f:
            existing = {r["pmid"] for r in csv.DictReader(f)}
    added = [r for r in ROWS if r["pmid"] not in existing]
    if not added:
        print("no new rows (PMID already present)")
        return
    with open(CSV, "a", encoding="utf-8-sig", newline="") as f:
        w = csv.DictWriter(f, fieldnames=FN)
        for r in added:
            w.writerow({k: r.get(k, "") for k in FN})
    print(f"appended {len(added)} rows: {[r['pmid'] for r in added]}")

if __name__ == "__main__":
    main()
