#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Generate Table 1: example rows from the parameter database (8 representative studies, covering
commodity / climate / production-system / DR-family diversity).
Fields are drawn from QMRA_parameter_database.csv + QMRA_context_covariates.csv."""
import csv, os

HERE = os.path.dirname(os.path.abspath(__file__))

def load(fn):
    with open(os.path.join(HERE, fn), encoding="utf-8-sig", newline="") as f:
        return {r["pmid"]: r for r in csv.DictReader(f)}

raw = load("QMRA_parameter_database.csv")
cov = load("QMRA_context_covariates.csv")

REPS = ["41819918", "41655324", "35853833", "36230018",
        "30525084", "28648297", "37061185", "27837223"]

HEADERS = [
    ("Study (country, year)",       lambda r, c: f"{r['first_author']} ({r['country_region']}, {r['year']})"),
    ("Commodity",                   lambda r, c: c["commodity_group"].replace("_", " ")),
    ("Climate",                     lambda r, c: c["climate_zone"]),
    ("Production system",           lambda r, c: c["production_sys"].replace("_", " ")),
    ("Cold chain",                  lambda r, c: c["cold_chain"]),
    ("Prevalence",                  lambda r, c: r["prev_value"]),
    ("Concentration",               lambda r, c: (f"{r['conc_mean']} {r['conc_unit']}".strip()
                                                   if r["conc_mean"] else r["conc_unit"])),
    ("Dose–response (α, β)",        lambda r, c: (f"({r['dr_alpha']}, {r['dr_beta']})"
                                                   if r["dr_alpha"] else c["dr_family"].replace("_", " "))),
    ("Predicted risk",              lambda r, c: r["predicted_risk"]),
    ("Risk basis",                  lambda r, c: r["risk_unit"]),
]

rows = []
for pmid in REPS:
    r = raw[pmid]; c = cov[pmid]
    rows.append([h[1](r, c) for h in HEADERS])

hdr = [h[0] for h in HEADERS]

# --- CSV ---
with open(os.path.join(HERE, "Table1_parameter_examples.csv"), "w", encoding="utf-8-sig", newline="") as f:
    w = csv.writer(f); w.writerow(hdr); w.writerows(rows)

# --- Markdown (transposed: fields as rows, studies as columns, to avoid horizontal overflow) ---
with open(os.path.join(HERE, "Table1_parameter_examples.md"), "w", encoding="utf-8") as f:
    f.write("| Field | " + " | ".join(rows[i][0] for i in range(len(rows))) + " |\n")
    f.write("|---|" + "---|" * len(rows) + "\n")
    for j in range(1, len(hdr)):
        f.write(f"| **{hdr[j]}** | " + " | ".join(rows[i][j].replace("|", "/") for i in range(len(rows))) + " |\n")

print("Saved: Table1_parameter_examples.csv + Table1_parameter_examples.md")
print("8 representative studies:", REPS)
