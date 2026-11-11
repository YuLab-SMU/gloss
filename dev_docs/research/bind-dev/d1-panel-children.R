# Why a frozen ggplot's panels do not hold background + layers + foreground
# (M1 plan Task 2, development run 2026-11-11-1205: exts-022, ggvolcano).
# Runs third-party code: only in the bench container, with no network:
#   GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript dev_docs/research/bind-dev/d1-panel-children.R exts-022
# Prints, for each panel grob of the gtable, its children; for each layer,
# the class of what its drawing step returns for panel 1 and how many
# children that adds to the panel.

source("bench/R/common.R")
.libPaths(unique(c(bench_envs$cran$lib, .libPaths())))
suppressMessages(library(ggplot2))
id <- commandArgs(trailingOnly = TRUE)[1]
exprs <- parse(file.path("bench/figures", id, "code.R"), keep.source = FALSE)
env <- new.env()
setwd(tempdir())
set.seed(1)
val <- NULL
for (ex in exprs) val <- withVisible(eval(ex, env))$value
b <- ggplot_build(val)
gt <- ggplot_gtable(b)
cat("ggplot2", as.character(packageVersion("ggplot2")), "| layers:", length(b$data), "\n")
for (j in grep("^panel", gt$layout$name)) {
  g <- gt$grobs[[j]]
  cat(sprintf("%s: %d children\n  %s\n", g$name, length(g$children), paste(names(g$children), collapse = " | ")))
}
for (i in seq_along(b$plot$layers)) {
  l <- b$plot$layers[[i]]
  gr <- l$draw_geom(b$data[[i]], b$layout)[[1]]
  n <- if (inherits(gr, "gList")) length(gr) else 1L
  cat(sprintf("layer %d %s: draws a %s, adding %d child%s\n", i, class(l$geom)[1], class(gr)[1], n, if (n == 1L) "" else "ren"))
}
