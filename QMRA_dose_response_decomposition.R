#!/usr/bin/env Rscript
# -*- coding: utf-8 -*-
# M1 core: decomposition of the transfer between dose-response (invariant mechanism)
#         and exposure pathway (context-specific).
# Question: at a fixed ingested dose D, how much do P_ill values differ across the
#           beta-Poisson parameters chosen by different studies?
#           This difference = "DR-selection error" (pure modeling choice, context-independent, avoidable).
# Model: P = 1 - (1 + D/β)^(-α)

# The single-value DR studies span only 3 generic published curves + Mexico's virulence tiers (3 curves) as reference
dr <- list(
  "FAO/WHO 2002 (canonical, 0.1324/51.45)" = c(0.1324, 51.45),
  "WHO feeding trial (0.3126/2884)"        = c(0.3126, 2884),
  "Egg-specific (0.89/4.4e5)"              = c(0.89,   4.4e5),
  "Virulence-high (0.1324/51.54)"          = c(0.1324, 51.54),
  "Virulence-moderate (9.21e3/3.165e10)"   = c(9.21e3, 3.165e10),
  "Virulence-low (9.31e4/9.99e12)"         = c(9.31e4, 9.99e12)
)

bp <- function(D, a, b) 1 - (1 + D/b)^(-a)

# Key dose points (orders of magnitude of CFU per serving)
doses <- 10^(0:8)

tab <- data.frame(Dose=doses)
for (nm in names(dr)) {
  ab <- dr[[nm]]
  tab[[nm]] <- bp(doses, ab[1], ab[2])
}

cat("=== P_ill across DR models at the same dose ===\n")
print(round(tab, 5), row.names=FALSE)

cat("\n=== Cross-model fold (max/min) at each dose --- i.e. upper bound of DR-selection error ===\n")
folds <- sapply(1:nrow(tab), function(i) {
  p <- as.numeric(tab[i, -1]); p <- p[p>0]; max(p)/min(p)
})
names(folds) <- paste0("10^", 0:8, " CFU")
print(round(folds, 1))

cat("\n=== Fold relative to canonical FAO/WHO (P_model / P_FAO) ===\n")
p_fao <- bp(doses, 0.1324, 51.45)
rel <- sapply(names(dr), function(nm){ ab <- dr[[nm]]; bp(doses, ab[1], ab[2]) / p_fao })
rel <- as.data.frame(rel)
rel$Dose <- doses
print(round(rel[, c(ncol(rel), 1:(ncol(rel)-1))], 3), row.names=FALSE)

# ---- Figure: dose-response curves (log scale) ----
pdf("QMRA_dose_response_curves.pdf", width=7.5, height=5.5)
cols <- c("black","#E41A1C","#377EB8","#4DAF4A","#984EA3","#FF7F00")
lwd  <- c(2.6, rep(1.6, 5))
lty  <- c(1, 1, 1, 2, 2, 2)
plot(log10(doses), log10(p_fao), type="l", col=cols[1], lwd=lwd[1], lty=lty[1],
     xlab="log10 ingested dose (CFU/serving)", ylab="log10 P(illness)",
     main="Dose-response model choice dominates risk at realistic (low) doses",
     ylim=c(-8, 0), xlim=c(0, 8), axes=FALSE)
axis(1, at=0:8, labels=parse(text=sprintf("10^%d", 0:8)))
axis(2)
for (i in 2:length(dr)) {
  ab <- dr[[i]]
  lines(log10(doses), log10(bp(doses, ab[1], ab[2])), col=cols[i], lwd=lwd[i], lty=lty[i])
}
legend("bottomright", legend=names(dr), col=cols, lwd=lwd, lty=lty, cex=0.65, bty="n")
box()
dev.off()
cat("\nPlot saved: QMRA_dose_response_curves.pdf\n")
