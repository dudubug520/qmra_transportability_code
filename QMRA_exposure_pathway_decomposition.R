#!/usr/bin/env Rscript
# -*- coding: utf-8 -*-
# M1 decomposition, the "exposure-pathway" half: fix the dose-response model (invariant mechanism),
#    use only each study's own exposure inputs (prevalence × concentration × serving) to recompute
#    per-serving illness probability, to gauge the span of the "context-specific" part, and juxtapose
#    it with the span of DR selection (the invariant mechanism).
#
# Key definitions:
#   dose = prev (contamination prevalence) × conc_gm (geometric mean CFU/g, retail/finished stage) × serving (g)
#   P_ill = 1 - (1 + dose/β)^(-α)   (canonical FAO/WHO α=0.1324, β=51.45, fixed)
#
# Honest statement: concentration definitions/stages differ across studies (see NOTE column);
#                   this is an order-of-magnitude demonstration, not a poolable meta-analysis.

canon <- c(0.1324, 51.45)
bp <- function(D, a, b) 1 - (1 + D/b)^(-a)

# 3 "published generic" DR curves (DR-selection reference) + Mexico virulence tiers (reference only, not a "choice")
DR <- list(
  "FAO/WHO 2002 (0.1324/51.45)" = c(0.1324, 51.45),
  "WHO feeding (0.3126/2884)"    = c(0.3126, 2884),
  "Egg-specific (0.89/4.4e5)"    = c(0.89, 4.4e5)
)
DR_VIR <- list(
  "Vir-high (0.1324/51.54)"     = c(0.1324, 51.54),
  "Vir-mod (9.21e3/3.165e10)"   = c(9.21e3, 3.165e10),
  "Vir-low (9.31e4/9.99e12)"    = c(9.31e4, 9.99e12)
)

# ---- Exposure inputs (retail/finished stage, per-serving basis) ----
E <- data.frame(
  pmid      = c(38034810, 30479510, 41097983, 38777091, 38309878),
  label     = c("Taiwan-salty-chicken","Korea-Dakgalbi","Beijing-chicken","USA-parts","EU-patties"),
  prev      = c(0.3698, 0.3188, 0.0887, 0.2890, 0.0327),
  conc_gm   = c(0.916, 10^5.3, 10^-2.98, 10^-3.19, 10^2.91),
  serving_g = c(34.02, 200, 158.3, 114, 100),
  note      = c("MPN/100g -> /g", "Pert mean 5.3 log (positive samples, upward bias)", "log MPN/g retail",
                "finished 2012", "conc = patty, but prev = pre-processing feces/litter (stage mixing)"),
  stringsAsFactors = FALSE
)
E$dose     <- E$prev * E$conc_gm * E$serving_g
E$log10_dose <- log10(E$dose)
E$p_fix    <- bp(E$dose, canon[1], canon[2])
E$log10_p  <- log10(E$p_fix)

cat("=== Exposure inputs -> per-serving dose and risk under fixed canonical DR ===\n")
print(data.frame(label=E$label, prev=E$prev, conc_gm=signif(E$conc_gm,3),
                 serving=E$serving_g, dose=signif(E$dose,3), log10_dose=round(E$log10_dose,2),
                 p_fix=signif(E$p_fix,3), log10_p=round(E$log10_p,2), note=E$note),
      row.names=FALSE)

cat("\n=== Span comparison ===\n")
cat(sprintf("Exposure span (fixed DR, 5 retail/finished studies)  log10 P range = %.2f  (=%.0f×)\n",
            diff(range(E$log10_p)), 10^diff(range(E$log10_p))))
cat(sprintf("Exposure dose span                log10 dose range = %.2f\n",
            diff(range(E$log10_dose))))

# DR-selection span at each study's own dose (3 generic curves)
cat("\n=== P span from DR selection at each study's own dose (3 generic curves) ===\n")
for (i in 1:nrow(E)) {
  ps <- sapply(DR, function(ab) bp(E$dose[i], ab[1], ab[2]))
  cat(sprintf("  %-22s D=%.2e  log10 P range=%.2f  (max/min=%.0f×)\n",
              E$label[i], E$dose[i], diff(range(log10(ps))), max(ps)/min(ps)))
}

cat("\nDR-selection span at a typical low dose D=10 CFU:\n")
ps10 <- sapply(DR, function(ab) bp(10, ab[1], ab[2]))
cat(sprintf("  3 generic curves: log10 range=%.2f (=%.0f×)\n", diff(range(log10(ps10))), max(ps10)/min(ps10)))
ps10v <- sapply(c(DR, DR_VIR), function(ab) bp(10, ab[1], ab[2]))
cat(sprintf("  incl. Mexico virulence tiers: log10 range=%.2f (=%.0f×)\n",
            diff(range(log10(ps10v))), max(ps10v)/min(ps10v)))

# ---- Figure: vertical = DR selection, horizontal = exposure ----
pdf("QMRA_exposure_vs_dose_response.pdf", width=8, height=6)
dd <- 10^seq(-2, 8, length.out=400)
cols <- c("black", "#E41A1C", "#377EB8")
lty  <- c(1, 2, 3)
plot(log10(dd), log10(bp(dd, canon[1], canon[2])), type="l", col=cols[1], lwd=2.6, lty=lty[1],
     xlab="log10 ingested dose (CFU/serving)", ylab="log10 P(illness)",
     main="Decomposition: DR choice (vertical) vs exposure pathway (horizontal)",
     xlim=c(-2, 8), ylim=c(-8, 0), axes=FALSE)
axis(1, at=seq(-2,8,2), labels=parse(text=sprintf("10^%d", seq(-2,8,2))))
axis(2)
for (j in 2:length(DR)) {
  ab <- DR[[j]]
  lines(log10(dd), log10(bp(dd, ab[1], ab[2])), col=cols[j], lwd=1.6, lty=lty[j])
}
# gray dashed = Mexico virulence tiers (reference only)
for (ab in DR_VIR) lines(log10(dd), log10(bp(dd, ab[1], ab[2])), col="grey70", lwd=1, lty=4)

# each study's exposure point on the canonical curve (horizontal = exposure span)
points(E$log10_dose, E$log10_p, pch=16, col="#FF7F00", cex=1.3)
text(E$log10_dose, E$log10_p, labels=E$label, pos=3, cex=0.7, col="#FF7F00")

legend("bottomright",
       legend=c(names(DR), "virulence tiers (ref)", "studies (fixed canonical DR)"),
       col=c(cols, "grey70", "#FF7F00"), lty=c(lty,4,NA), lwd=c(2.6,1.6,1.6,1,NA),
       pch=c(NA,NA,NA,NA,16), cex=0.62, bty="n")
box()
dev.off()
cat("\nPlot saved: QMRA_exposure_vs_dose_response.pdf\n")
