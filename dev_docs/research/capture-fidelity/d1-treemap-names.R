# D1 (2026-11-10): why gallery-056 (treemap) cannot be captured from a grid.grab().
# Runs third-party code (a development figure): container only.
#   bench/docker/run.sh Rscript dev_docs/research/capture-fidelity/d1-treemap-names.R
source("bench/R/harvest.R")
use_env(bench_envs$cran); .libPaths(bench_libpaths())
suppressMessages(pkgload::load_all(".", quiet = TRUE, export_all = TRUE, helpers = FALSE))
dir <- file.path(figures_root, "gallery-056"); meta <- jsonlite::read_json(file.path(dir, "meta.json"))
s <- svglite::svgstring(width = 7, height = 5); dev.control("enable")
set.seed(meta$seed); env <- new.env()
for (e in parse(file.path(dir, "code.R"))) withVisible(eval(e, env))
ls1 <- grid::grid.ls(print = FALSE, viewports = TRUE, fullNames = TRUE)
cat("display list items:", length(ls1$name), "\n")
print(table(ls1$type))
idx <- .Call(grid:::C_getDLindex)
cat("DL index:", idx, "\n")
for (i in seq_len(idx - 1L)) {
  elt <- .Call(grid:::C_getDLelt, as.integer(i))
  if (!inherits(elt, "grob")) { cat(sprintf("[%2d] %s\n", i, paste(class(elt), collapse = "/"))); next }
  kids <- if (inherits(elt, "gTree")) elt$children else NULL
  cat(sprintf("[%2d] %-30s name=%-20s children=%d names(children)=%d childrenOrder=%d | kid names: %s\n", i,
              paste(class(elt), collapse = "/"), elt$name, length(kids), length(names(kids)), length(elt$childrenOrder),
              paste(utils::head(vapply(kids, function(k) k$name, ""), 5), collapse = ",")))
}
