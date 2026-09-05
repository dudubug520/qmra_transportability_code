#!/usr/bin/env Rscript
# -*- coding: utf-8 -*-
# Generate three figures for the paper (Fig 2 uses the existing QMRA_selection_diagram.pdf):
#   Fig 1 : PRISMA screening flow + context distribution of the 39 studies
#   Fig 3 : extrapolation error vs context distance (real LOCO, the core negative result)
#   Fig 4 : China pork QMRA risk forest plot (RQ4)
# All labels in English (for Food Research International).

cov  <- read.csv("data/QMRA_context_covariates.csv", stringsAsFactors=FALSE, fileEncoding="UTF-8")
loco <- read.csv("data/QMRA_LOCO_risk_normalized.csv", stringsAsFactors=FALSE, fileEncoding="UTF-8")

# ======================================================================
# Fig 1 : PRISMA + context coverage
# ======================================================================
pdf("Fig1_PRISMA_context_distribution.pdf", width=11.5, height=7.5)

layout(matrix(c(1,2, 1,3, 1,4), nrow=3, byrow=TRUE), widths=c(1, 1.45))

# ---- left: PRISMA flow ----
par(mar=c(0.4,0.4,0.4,0.4))
plot(NA, xlim=c(0,10), ylim=c(0,10), axes=FALSE, xlab="", ylab="")
box <- function(x1,y1,x2,y2,lab,cex=0.8,fill="#FFFFFF",border="black") {
  rect(x1,y1,x2,y2,col=fill,border=border,lwd=1.4)
  text((x1+x2)/2,(y1+y2)/2,lab,cex=cex)
}
box(0.6,9.15,4.0,9.95, "Database search\n(PubMed)\nn = 152", cex=0.78)
box(4.4,9.15,7.8,9.95, "Database search\n(Web of Science)\nn = 356", cex=0.78)
box(8.2,9.15,9.9,9.95, "Other sources\nn = 1", cex=0.78)
arrows(2.3,9.15,2.3,8.4,length=0.1,lwd=1.4)
arrows(6.1,9.15,6.1,8.4,length=0.1,lwd=1.4)
box(0.6,7.6,7.8,8.4, "Records after duplicates removed\nn = 380", cex=0.8)
arrows(4.2,7.6,4.2,7.1,length=0.1,lwd=1.4)
arrows(9.05,9.15,9.05,7.1,length=0.1,lwd=1.4)
box(0.6,6.3,9.9,7.1, "Records screened\nn = 381", cex=0.85)
arrows(5,6.3,5,5.8,length=0.1,lwd=1.4)
text(8.8,6.0, "title/abstract screening", cex=0.7, adj=0)
box(0.6,2.9,9.9,5.8, "Excluded n = 342\nnon-QMRA / no quantified parameters /\nno stated context", fill="#F0F0F0", cex=0.75)
arrows(5,2.9,5,2.2,length=0.1,lwd=1.4)
box(0.6,1.4,9.9,2.2, "Included studies\nn = 39", fill="#E8F4E8", cex=0.9)
text(5,1.05, "10 commodities  5 climate zones  6 production systems",
     cex=0.72, font=3)

# ---- right panels: distributions ----
draw_bar <- function(tab, title, horiz=TRUE, las=1) {
  par(mar=c(3,6.5,2.2,0.6))
  tab <- sort(tab)
  if (horiz) {
    bp <- barplot(tab, horiz=TRUE, las=las, xlab="n studies", col="#4C72B0",
                  cex.names=0.82, cex.axis=0.8, border=NA)
    mtext(title, side=3, line=0.3, cex=0.95, font=2)
  } else {
    bp <- barplot(tab, horiz=FALSE, las=las, ylab="n studies", col="#4C72B0",
                  cex.names=0.82, cex.axis=0.8, border=NA)
    mtext(title, side=3, line=0.3, cex=0.95, font=2)
  }
}

commodity_lab <- c(poultry_meat="poultry meat", pork="pork", eggs="eggs",
                   offal="offal", egg_product="egg product", mixed="mixed",
                   seafood="seafood", nuts="nuts", beef="beef", vegetables="vegetables")
climate_lab   <- c(temperate="temperate", tropical="tropical", subtropical="subtropical",
                   arid="arid", mediterranean="Mediterranean")
prodsys_lab   <- c(retail="retail", processing="processing", intensive="intensive",
                   food_service="food service", smallholder="smallholder", aquaculture="aquaculture")

t1 <- table(factor(cov$commodity_group, levels=names(commodity_lab)))
names(t1) <- commodity_lab[names(t1)]
draw_bar(t1, "Commodity group", horiz=TRUE, las=2)

t2 <- table(factor(cov$climate_zone, levels=names(climate_lab)))
names(t2) <- climate_lab[names(t2)]
draw_bar(t2, "Climate zone", horiz=TRUE, las=2)

t3 <- table(factor(cov$production_sys, levels=names(prodsys_lab)))
names(t3) <- prodsys_lab[names(t3)]
draw_bar(t3, "Production system", horiz=TRUE, las=2)

dev.off()
cat("Saved: Fig1_PRISMA_context_distribution.pdf\n")

# ======================================================================
# Fig 3 : extrapolation error vs context distance (real LOCO)
# ======================================================================
covs <- c("commodity_group","climate_zone","production_sys","cold_chain","population","dr_family")
n <- nrow(loco)
G <- matrix(0, n, n)
for (j in covs) {
  v <- loco[[j]]
  G <- G + outer(v, v, function(a,b) as.numeric(a != b))
}
G <- G / length(covs)

eps <- 1e-4; p <- 1
res <- data.frame(mean_dist=NA, naive=NA, wgt=NA)
for (k in 1:n) {
  o <- setdiff(1:n, k)
  pred_naive <- mean(loco$log10_risk[o])
  dist <- G[k, o]; w <- 1/(dist+eps)^p
  pred_w <- sum(w*loco$log10_risk[o])/sum(w)
  res[k,] <- c(mean(dist), abs(pred_naive-loco$log10_risk[k]), abs(pred_w-loco$log10_risk[k]))
}
ratio <- mean(res$wgt)/mean(res$naive)

pdf("Fig3_extrapolation_error_vs_distance.pdf", width=7.2, height=5.4)
par(mar=c(4.2,4.2,2.6,1))
plot(res$mean_dist, res$naive, col="#E41A1C", pch=16, cex=1.3,
     xlim=c(0.3, max(res$mean_dist)*1.1),
     ylim=c(0, max(c(res$naive,res$wgt))*1.22),
     xlab="Mean Gower distance (held-out vs remaining contexts)",
     ylab="|log10 extrapolation error|", main="Leave-one-context-out: naive vs distance-weighted transfer")
points(res$mean_dist, res$wgt, col="#377EB8", pch=17, cex=1.3)
abline(lm(res$naive~res$mean_dist), col="#E41A1C", lty=2)
abline(lm(res$wgt~res$mean_dist),   col="#377EB8", lty=2)
text(res$mean_dist, res$naive, loco$label, pos=3, cex=0.5, col="#E41A1C")
text(res$mean_dist, res$wgt,   loco$label, pos=1, cex=0.5, col="#377EB8")
legend("topright",
       legend=c(sprintf("naive mean (log10 err = %.2f)", mean(res$naive)),
                sprintf("distance-weighted (log10 err = %.2f)", mean(res$wgt)),
                sprintf("error ratio = %.2f", ratio)),
       col=c("#E41A1C","#377EB8","grey20"), pch=c(16,17,NA), lty=c(2,2,NA),
       pt.cex=1.3, cex=0.78, bty="n", text.col=c("#E41A1C","#377EB8","grey20"))
dev.off()
cat(sprintf("Saved: Fig3_extrapolation_error_vs_distance.pdf  (error ratio = %.2f)\n", ratio))

# ======================================================================
# Fig 4 : China pork QMRA risk forest plot (RQ4)
# ======================================================================
china <- data.frame(
  study = c("Chengdu ground pork (Li Bai 2023)",
            "Retail pork, multi-province (Li Bai 2026)",
            "Household pork, national (Zhang 2026)",
            "National meta+QMRA (Xu 2026)"),
  est = c(3442, 2526, 2643, 2471),
  lo  = c(3218, 2475, 2498, NA),
  hi  = c(3666, 2578, 2790, NA),
  hasCI = c(TRUE, TRUE, TRUE, FALSE)
)

pdf("Fig4_China_pork_risk.pdf", width=7.6, height=4.8)
par(mar=c(4.5,13,3,1))
xr <- c(2200, 3900)
plot(NA, xlim=xr, ylim=c(0.5, nrow(china)+0.5), axes=FALSE,
     xlab="Pork-attributable salmonellosis (cases per million per year)", ylab="")
axis(1, at=seq(2200,3800,200), cex.axis=0.85)
abline(v=seq(2200,3800,200), col="grey92", lwd=0.6)
for (i in 1:nrow(china)) {
  y <- nrow(china) - i + 1
  if (china$hasCI[i]) {
    segments(china$lo[i], y, china$hi[i], y, lwd=6, col="#A6CEE3")
    points(china$est[i], y, pch=19, cex=1.5, col="#1F78B4")
    text(china$lo[i], y, format(china$lo[i],big.mark=","), pos=2, cex=0.62, col="grey35")
    text(china$hi[i], y, format(china$hi[i],big.mark=","), pos=4, cex=0.62, col="grey35")
  } else {
    points(china$est[i], y, pch=15, cex=1.6, col="#E41A1C")
  }
}
axis(2, at=1:nrow(china), labels=china$study, las=2, cex.axis=0.82, tick=FALSE, line=-1)
text(china$est, 1:nrow(china), format(china$est,big.mark=","),
     pos=3, cex=0.72, font=2, col="#1F78B4")
mtext("Study (all FAO/WHO 2002 dose-response)", side=2, line=12, cex=0.78, font=2)
legend("bottomright",
       legend=c("95% CI (3 studies)", "point only (meta, no CI reported)"),
       col=c("#A6CEE3","#E41A1C"), pch=c(19,15), pt.cex=c(1.3,1.4), cex=0.75, bty="n")
dev.off()
cat("Saved: Fig4_China_pork_risk.pdf\n")
