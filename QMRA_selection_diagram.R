#!/usr/bin/env Rscript
# -*- coding: utf-8 -*-
# Maximum common causal DAG + selection diagram
# The 39 QMRA studies' DAGs share a single causal backbone; the Pearl-Bareinboim selection diagram marks
# which nodes are context-specific (S, require transfer) vs which edges are invariant mechanisms (shareable).
#
# Convention: red = S-pointed (context-dependent root inputs); dark blue = invariant mechanism (dilution /
#        growth-inactivation kinetics / dose-response); thick blue edge dose->illness = the invariant mechanism.

pdf("QMRA_selection_diagram.pdf", width=10, height=5.5)

par(mar=c(0.4,0.4,1.6,0.4))
plot(NA, xlim=c(0,15), ylim=c(0,6), axes=FALSE, xlab="", ylab="",
     main="Maximum common QMRA DAG as a selection diagram (Pearl-Bareinboim)")

# ---- Node coordinates (main chain y=1.8, upstream drivers y=4.2) ----
N <- list(
  production    = c(1.0, 4.2),
  prevalence    = c(1.0, 1.8),
  climate       = c(5.2, 4.2),
  growth        = c(5.2, 1.8),
  concentration = c(3.1, 1.8),
  inactivation  = c(7.3, 1.8),
  crosscontam   = c(9.4, 1.8),
  serving       = c(11.5, 4.2),
  dose          = c(11.5, 1.8),
  suscept       = c(13.6, 4.2),
  illness       = c(13.6, 1.8)
)
LAB <- c(production="production\nsystem", prevalence="prevalence",
         climate="climate /\ncold chain", growth="growth",
         concentration="concentration", inactivation="inactivation\n(cooking)",
         crosscontam="cross-\ncontam.", serving="serving\nsize",
         dose="dose", suscept="susceptibility", illness="illness")
S_FLAG   <- c("production","prevalence","climate","crosscontam","serving","suscept")
INVARIANT <- c("concentration","growth","inactivation","dose","illness")

# causal edges (grey)
edges <- list(
  c("production","prevalence"),
  c("prevalence","concentration"),
  c("climate","growth"),
  c("concentration","growth"),
  c("growth","inactivation"),
  c("inactivation","crosscontam"),
  c("crosscontam","dose"),
  c("serving","dose"),
  c("suscept","illness")
)

draw_node <- function(nm) {
  xy <- N[[nm]]
  col <- if (nm %in% S_FLAG) "#E41A1C" else "#2166AC"
  rect(xy[1]-0.8, xy[2]-0.6, xy[1]+0.8, xy[2]+0.6, col="#F7F7F7", border=col, lwd=2.2)
  text(xy[1], xy[2], LAB[[nm]], cex=0.58)
}
arrow <- function(a, b, col="grey45", lwd=1.6, lty=1) {
  pa <- N[[a]]; pb <- N[[b]]
  d <- pb - pa; u <- d / sqrt(sum(d^2))
  p1 <- pa + u*0.60; p2 <- pb - u*0.60
  arrows(p1[1], p1[2], p2[1], p2[2], col=col, lwd=lwd, lty=lty, length=0.11)
}

for (e in edges) arrow(e[1], e[2], col="grey45", lwd=1.6)
arrow("dose","illness", col="#2166AC", lwd=3.2)   # invariant mechanism
for (nm in names(N)) draw_node(nm)

# selection variable S (red box, points to all red nodes; draw 3 nearby arrows as representatives)
rect(0.15, 4.6, 0.95, 5.3, col="#E41A1C", border="#E41A1C")
text(0.55, 4.95, "S", col="white", cex=1.2, font=2)
arrows(0.95, 4.95, 1.78, 4.75, col="#E41A1C", lwd=1.5, lty=2, length=0.11)  # -> production
arrows(0.95, 4.95, 1.78, 2.15,  col="#E41A1C", lwd=1.5, lty=2, length=0.11)  # -> prevalence
text(3.0, 4.9, "S -> every red node\n(context-dependent input)", col="#E41A1C", cex=0.62, adj=0)

legend("bottomright",
       legend=c("context-dependent input (S-flagged): transport via covariates",
                "invariant mechanism (shared): dilution / kinetics / dose-response",
                "invariant dose-response: dose -> illness"),
       col=c("#E41A1C","#2166AC","#2166AC"), lwd=c(2,2,3.2), lty=c(1,1,1),
       pch=c(22,22,NA), pt.bg=c("#E41A1C","#2166AC",NA), cex=0.60, bty="n")
box()
dev.off()
cat("Plot saved: QMRA_selection_diagram.pdf\n")
