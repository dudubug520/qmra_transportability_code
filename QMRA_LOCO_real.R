#!/usr/bin/env Rscript
# -*- coding: utf-8 -*-
# QMRA transportability LOCO --- real-data version
# Leave-one-context-out over the studies that can be normalized to a per-serving illness-probability scale:
#   naive transfer             = mean of the log10 risk of the remaining studies
#   distance-weighted transfer = weighted by Gower context distance
# Compare the two prediction errors for the held-out context.
# Honest statement: this is a proof-of-concept, not definitive; see QMRA_LOCO_risk_normalized.csv for the risk-normalization assumptions.

# Run from the directory containing this file (or set csv_path to an absolute path)
csv_path <- "QMRA_LOCO_risk_normalized.csv"
d <- read.csv(csv_path, stringsAsFactors = FALSE, fileEncoding = "UTF-8")

covs <- c("commodity_group","climate_zone","production_sys","cold_chain","population","dr_family")

# ---- Gower distance (all-categorical covariates) ----
gower <- function(d, covs) {
  n <- nrow(d)
  D <- matrix(0, n, n)
  for (j in covs) {
    v <- d[[j]]
    D <- D + outer(v, v, function(a,b) as.numeric(a != b))
  }
  D / length(covs)
}
G <- gower(d, covs)

# ---- LOCO ----
n <- nrow(d); eps <- 1e-4; p <- 1
out <- data.frame(pmid=d$pmid, label=d$label, country=d$country,
                  mean_dist=NA, naive_err_log10=NA, wgt_err_log10=NA, stringsAsFactors=FALSE)
for (k in 1:n) {
  o <- setdiff(1:n, k)
  pred_naive <- mean(d$log10_risk[o])
  dist <- G[k, o]
  w <- 1 / (dist + eps)^p
  pred_w <- sum(w * d$log10_risk[o]) / sum(w)
  out$mean_dist[k] <- mean(dist)
  out$naive_err_log10[k] <- abs(pred_naive - d$log10_risk[k])
  out$wgt_err_log10[k]   <- abs(pred_w   - d$log10_risk[k])
}

# relative error on the linear scale (comparable to the synthetic demo)
out$naive_rel <- 10^out$naive_err_log10 - 1
out$wgt_rel   <- 10^out$wgt_err_log10   - 1

cat("=== LOCO per-context results (log10 absolute error = multiplicative error on linear scale) ===\n")
print(out[, c("label","country","mean_dist","naive_err_log10","wgt_err_log10","naive_rel","wgt_rel")], digits=3, row.names=FALSE)
cat("\n=== Summary ===\n")
cat(sprintf("Naive transfer    mean log10 error = %.3f  (median linear relative error %.1f%%)\n",
            mean(out$naive_err_log10), median(out$naive_rel)*100))
cat(sprintf("Distance-weighted mean log10 error = %.3f  (median linear relative error %.1f%%)\n",
            mean(out$wgt_err_log10), median(out$wgt_rel)*100))
cat(sprintf("Error ratio (weighted/naive) = %.2f\n", mean(out$wgt_err_log10)/mean(out$naive_err_log10)))

# ---- Risk by dose-response family (a more informative diagnostic) ----
cat("\n=== Risk (log10/serving) by dose-response family ===\n")
for (fam in sort(unique(d$dr_family))) {
  v <- d$log10_risk[d$dr_family == fam]
  cat(sprintf("  %-22s n=%d  spread=%s\n", fam, length(v),
      ifelse(length(v)>=2, sprintf("%.2f", diff(range(v))), "-")))
}

# ---- Figure: error vs context distance ----
pdf("QMRA_extrapolation_error_vs_distance_real.pdf", width=7, height=5)
plot(out$mean_dist, out$naive_err_log10, col="red", pch=16, cex=1.2,
     xlim=c(0, max(out$mean_dist)*1.15), ylim=c(0, max(c(out$naive_err_log10,out$wgt_err_log10))*1.2),
     xlab="Mean Gower distance (held-out vs others)", ylab="log10 prediction error (=multiplicative)",
     main="Real-data LOCO: naive vs distance-weighted transfer")
points(out$mean_dist, out$wgt_err_log10, col="blue", pch=17, cex=1.2)
text(out$mean_dist, out$naive_err_log10, labels=out$label, pos=3, cex=0.55, col="red")
text(out$mean_dist, out$wgt_err_log10, labels=out$label, pos=1, cex=0.55, col="blue")
abline(lm(out$naive_err_log10 ~ out$mean_dist), col="red", lty=2)
abline(lm(out$wgt_err_log10 ~ out$mean_dist), col="blue", lty=2)
legend("topleft", legend=c("naive (mean)","distance-weighted"), col=c("red","blue"), pch=c(16,17), lty=2)
dev.off()
cat("\nPlot saved: QMRA_extrapolation_error_vs_distance_real.pdf\n")
