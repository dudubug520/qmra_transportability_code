# ============================================================
# Transportable QMRA --- leave-one-context-out error quantification (synthetic demo)
# Output: extrapolation error vs context distance --- the logic behind Fig 3
# Note: uses synthetic "contexts" to demonstrate the method; for real data, replace the
#       simulate step (step 2) with "literature-extracted parameters + each context's official
#       surveillance burden".
# Dependencies: base R only (no bnlearn).
# ============================================================

# ---- 1. Invariant-mechanism CPT + exact risk function (same as QMRA_bn_skeleton.R) ----
p_conc_high_given_prev_low  <- 0.10
p_conc_high_given_prev_high <- 0.60
p_growth_given_temp_cold    <- 0.10
p_growth_given_temp_warm    <- 0.60
dose_cpt <- rbind(
  c(0.85, 0.12, 0.03),  # Conc=low,  Growth=no
  c(0.40, 0.40, 0.20),  # Conc=high, Growth=no
  c(0.50, 0.30, 0.20),  # Conc=low,  Growth=yes
  c(0.10, 0.35, 0.55)   # Conc=high, Growth=yes
)
p_ill_given_dose <- c(low = 0.001, med = 0.005, high = 0.030)

risk <- function(p_prev_high, p_temp_warm) {
  p_conc_high  <- p_conc_high_given_prev_low * (1 - p_prev_high) +
                  p_conc_high_given_prev_high * p_prev_high
  p_growth_yes <- p_growth_given_temp_cold * (1 - p_temp_warm) +
                  p_growth_given_temp_warm * p_temp_warm
  w <- c((1-p_conc_high)*(1-p_growth_yes), p_conc_high*(1-p_growth_yes),
         (1-p_conc_high)*p_growth_yes,     p_conc_high*p_growth_yes)
  p_dose <- numeric(3)
  for (i in 1:4) p_dose <- p_dose + w[i] * dose_cpt[i, ]
  sum(p_dose * p_ill_given_dose)
}

# ---- 2. Synthetic contexts: covariates + true parameters + true risk ----
# Covariates: x1 = cold-chain quality (higher is better), x2 = biosecurity/intensification (higher is stricter)
# True parameter generation: p_temp_warm = 0.5 - 0.4*x1; p_prev_high = 0.5 - 0.4*x2
contexts <- data.frame(
  name = c("US","EU","S.Korea","Australia","Brazil","China","India","Nigeria"),
  x1 = c(0.90, 0.85, 0.80, 0.90, 0.50, 0.40, 0.20, 0.15),
  x2 = c(0.85, 0.80, 0.70, 0.75, 0.40, 0.30, 0.15, 0.20)
)
contexts$p_temp <- 0.5 - 0.4 * contexts$x1   # poorer cold chain -> higher warm probability
contexts$p_prev <- 0.5 - 0.4 * contexts$x2   # poorer biosecurity -> higher prevalence
contexts$r_true <- mapply(risk, contexts$p_prev, contexts$p_temp)

# ---- 3. Context distance (Euclidean distance on standardized covariates) ----
Z <- scale(contexts[, c("x1", "x2")])
dist_ij <- as.matrix(dist(Z))

# ---- 4. Naive transfer: apply the source-context parameters to every context ----
src <- which(contexts$name == "US")
naive_r   <- risk(contexts$p_prev[src], contexts$p_temp[src])
naive_err <- abs(naive_r - contexts$r_true) / contexts$r_true
naive_d   <- dist_ij[src, ]          # distance to source (source itself has distance=0, error=0)

# ---- 5. Transportable (covariate-adjusted) LOCO ----
# For each held-out context k: fit logit(p) ~ x on the remaining contexts, predict k, compute the error
logit <- function(p) log(p / (1 - p))
invlogit <- function(z) 1 / (1 + exp(-z))
loco_err <- numeric(nrow(contexts)); loco_d <- numeric(nrow(contexts))
for (k in seq_len(nrow(contexts))) {
  tr <- setdiff(seq_len(nrow(contexts)), k)
  m1 <- lm(logit(p_temp) ~ x1, data = contexts[tr, ])   # temperature <- cold-chain quality
  m2 <- lm(logit(p_prev) ~ x2, data = contexts[tr, ])   # prevalence <- biosecurity
  p_temp_hat <- invlogit(predict(m1, newdata = contexts[k, ]))
  p_prev_hat <- invlogit(predict(m2, newdata = contexts[k, ]))
  r_hat      <- risk(p_prev_hat, p_temp_hat)
  loco_err[k] <- abs(r_hat - contexts$r_true[k]) / contexts$r_true[k]
  loco_d[k]   <- min(dist_ij[k, tr])   # distance to nearest "training context"
}

# ---- 6. Plot: error vs distance (naive red vs transportable blue) ----
pdf("QMRA_extrapolation_error_vs_distance.pdf", width = 8.5, height = 4.5)
par(mfrow = c(1, 2), mar = c(4,4,3,1))
ylim <- range(c(naive_err, loco_err), 0)
plot(naive_d, naive_err, pch = 19, col = "#d9534f",
     main = "Naive transfer (fixed source params)",
     xlab = "Distance to source", ylab = "Relative error", ylim = ylim)
abline(lm(naive_err ~ naive_d), col = "#d9534f", lty = 2)
text(naive_d, naive_err, contexts$name, pos = 3, cex = 0.75)

plot(loco_d, loco_err, pch = 19, col = "#0275d8",
     main = "Transportability-corrected (LOCO)",
     xlab = "Distance to nearest training context",
     ylab = "Relative error", ylim = ylim)
abline(lm(loco_err ~ loco_d), col = "#0275d8", lty = 2)
text(loco_d, loco_err, contexts$name, pos = 3, cex = 0.75)
dev.off()

# ---- 7. Print the numerical comparison ----
cat("context     true risk    naive error   LOCO error\n")
for (i in seq_len(nrow(contexts))) {
  cat(sprintf("%-10s %8.5f   %8.3f   %8.3f\n",
      contexts$name[i], contexts$r_true[i], naive_err[i], loco_err[i]))
}
cat(sprintf("\nMean relative error: naive = %.3f, LOCO = %.4f\n",
            mean(naive_err), mean(loco_err)))
cat("Figure saved: QMRA_extrapolation_error_vs_distance.pdf\n")
