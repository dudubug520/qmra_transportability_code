# ============================================================
# Transportable QMRA --- minimal Bayesian-network skeleton (R / bnlearn)
# ------------------------------------------------------------
# Goal: run the farm-to-fork pipeline on EXAMPLE parameters and demonstrate the core
#       "transportability" operation: swap the CONTEXT-DEPENDENT CPTs (prevalence,
#       cold-chain temperature), keep the INVARIANT-MECHANISM CPTs (growth, dose-response),
#       and see how the risk estimate changes across contexts.
#
# Important: all CPTs are example values; replace them with the real parameters you extract
#       from the literature. States are discretized only for the demo; the full model can use
#       bnlearn Gaussian (continuous) nodes or brms/PyMC.
# ============================================================

library(bnlearn)

# ---- 1. DAG: farm-to-fork causal structure (= the transportable part) ----
# The structure is "invariant" (this is the DAG backbone of the selection diagram);
# the parameters are "variable". This is "shared mechanism, swapped inputs".
dag <- model2network(
  "[Prevalence][Temp][Concentration|Prevalence][Growth|Temp][Dose|Concentration:Growth][Ill|Dose]"
)

# ---- 2. CPTs: annotated into two classes ----
#   [context-dependent] replaced when the context changes
#   [invariant mechanism] kept when the context changes (biologically/physically invariant)

# US baseline (context A)
cpt_us <- list(
  # [context-dependent] retail prevalence
  Prevalence = array(c(0.85, 0.15), dim = 2,
                     dimnames = list(Prevalence = c("low", "high"))),
  # [context-dependent] cold-chain temperature
  Temp = array(c(0.90, 0.10), dim = 2,
               dimnames = list(Temp = c("cold", "warm"))),
  # [semi-context] concentration | prevalence
  Concentration = array(c(0.90, 0.10,   # Prevalence = low
                          0.40, 0.60),  # Prevalence = high
                        dim = c(2, 2),
                        dimnames = list(Concentration = c("low", "high"),
                                        Prevalence     = c("low", "high"))),
  # [invariant mechanism] growth | temperature (microbiological mechanism, same worldwide, not swapped)
  Growth = array(c(0.90, 0.10,   # Temp = cold
                   0.40, 0.60),  # Temp = warm
                 dim = c(2, 2),
                 dimnames = list(Growth = c("no", "yes"),
                                 Temp   = c("cold", "warm"))),
  # [semi-context] dose | concentration, growth
  Dose = array(c(0.85, 0.12, 0.03,   # Conc=low,  Growth=no
                 0.40, 0.40, 0.20,   # Conc=high, Growth=no
                 0.50, 0.30, 0.20,   # Conc=low,  Growth=yes
                 0.10, 0.35, 0.55),  # Conc=high, Growth=yes
               dim = c(3, 2, 2),
               dimnames = list(Dose          = c("low", "med", "high"),
                               Concentration = c("low", "high"),
                               Growth        = c("no", "yes"))),
  # [invariant mechanism] illness | dose (dose-response, biologically invariant, not swapped)
  Ill = array(c(0.999, 0.001,   # Dose = low
                0.995, 0.005,   # Dose = med
                0.970, 0.030),  # Dose = high
              dim = c(2, 3),
              dimnames = list(Ill  = c("no", "yes"),
                              Dose = c("low", "med", "high")))
)

bn_us <- custom.fit(dag, cpt_us)

# ---- 3. Forward inference: US baseline risk ----
# cpquery defaults to likelihood-weighted sampling (approximate); for exact results use gRain junction-tree inference.
p_ill_us <- cpquery(bn_us, event = (Ill == "yes"), evidence = TRUE, n = 1e6)
cat("US baseline P(illness = yes) =", signif(p_ill_us, 6), "\n\n")

# ---- 4. Transportability operation: swap only the context CPTs, keep invariant mechanisms ----
# China context: higher retail prevalence, poorer cold chain (higher warm probability)
cpt_cn <- cpt_us                                   # inherit everything first (incl. invariant mechanisms)
cpt_cn$Prevalence <- array(c(0.60, 0.40), dim = 2,
                           dimnames = list(Prevalence = c("low", "high")))  # context-swapped
cpt_cn$Temp        <- array(c(0.60, 0.40), dim = 2,
                            dimnames = list(Temp = c("cold", "warm")))       # context-swapped
# Growth, Ill (invariant mechanisms) stay fixed --- this is the transportability criterion: shared mechanism, swapped inputs

bn_cn <- custom.fit(dag, cpt_cn)
p_ill_cn <- cpquery(bn_cn, event = (Ill == "yes"), evidence = TRUE, n = 1e6)
cat("China context P(illness = yes) =", signif(p_ill_cn, 6), "\n")
cat("Risk factor (China/US) =", signif(p_ill_cn / p_ill_us, 4), "\n\n")

# ---- 5. Reverse inference (source attribution, bonus) ----
# Given that illness occurred, infer the most likely source (high prevalence vs warm temperature)
post_prev <- cpquery(bn_cn, event = (Prevalence == "high"),
                     evidence = (Ill == "yes"), n = 1e6)
post_temp <- cpquery(bn_cn, event = (Temp == "warm"),
                     evidence = (Ill == "yes"), n = 1e6)
cat("In the China context, given that illness occurred:\n")
cat("  P(prevalence = high | illness) =", signif(post_prev, 4), "\n")
cat("  P(temp = warm    | illness) =", signif(post_temp, 4), "\n")

# ============================================================
# Extension roadmap (next steps)
# 1) Add nodes: cross-contamination, consumption, population susceptibility -> a fuller farm-to-fork model
# 2) Continuous nodes: use bnlearn Gaussian nodes (bn.fit(..., method="mle-g")) or switch to PyMC/brms
# 3) Make context covariates explicit: add Climate/ProductionSystem nodes pointing to Prevalence/Temp
#    -> this is the graphical representation of the "M1 transportability criterion"
# 4) Parameters from the literature: fill in the CPTs from the parameter-extraction schema, replacing the example values
# 5) Leave-one-context-out: hold out one context, predict it using CPTs estimated from the others,
#    compare prediction vs observation -> the "M2 extrapolation error vs context distance"
# ============================================================
