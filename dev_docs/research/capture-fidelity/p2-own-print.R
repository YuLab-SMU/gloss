# P2b (2026-11-11): page-capture plan, Task 2, second measurement.
# The two development figures whose objects print through their own method:
# what do the engine's tables() and panels() say against the page print()
# draws? Development figures only. First run at 19f39d7 (after Task 1, before
# the table rule): p2-own-print.out. Second run after the table rule of Task 2
# (the withheld lines were added for it): p2-own-print-t2.out.
#
# Runs third-party code: container only, no network.
#   GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript dev_docs/research/capture-fidelity/p2-own-print.R
source("bench/R/harvest.R")
.libPaths(bench_libpaths())
ids <- c("exts-018", "gallery-052")  # development set; fixed, not an argument

last_object <- function(id) {
  env <- new.env(parent = globalenv())
  meta <- jsonlite::fromJSON(file.path("bench/figures", id, "meta.json"))
  set.seed(meta$seed)
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off())
  exprs <- parse(file.path("bench/figures", id, "code.R"), keep.source = FALSE)
  last <- NULL
  for (e in exprs) {
    res <- withVisible(eval(e, env))
    if (res$visible && !is.null(res$value)) last <- res$value
  }
  last
}

suppressMessages(pkgload::load_all(".", quiet = TRUE, export_all = TRUE, helpers = FALSE))
for (id in ids) {
  x <- suppressWarnings(suppressMessages(last_object(id)))
  cat(sprintf("== %s: class %s ==\n", id, paste(class(x), collapse = " ")))
  fig <- tryCatch(suppressWarnings(gloss(x, width = 7, height = 5, context = FALSE)), error = function(e) e)
  if (inherits(fig, "error")) {
    cat("  gloss() error:", conditionMessage(fig), "\n")
    next
  }
  s <- fig$substrate
  pg <- fig$meta$page
  cat(sprintf("  engine %s | page %s drawn by %s, verdict %s | %d elements, %d leaves\n",
              fig$meta$engine, pg$kind, pg$drawn_by, pg$verdict, nrow(s$elements), nrow(s$leaves)))
  cat(sprintf("  panels returned: %d\n", nrow(s$panels)))
  vps <- unique(unlist(lapply(strsplit(s$leaves$vp, "::", fixed = TRUE), function(parts) {
    grep("^panel(-[0-9]+)*\\.[0-9-]+$|^panel\\.[0-9-]+$", parts, value = TRUE)
  })))
  cat(sprintf("  panel viewports on the page: %d (%s)\n", length(vps), paste(utils::head(vps, 6), collapse = ", ")))
  w <- fig$status$withheld
  if (is.data.frame(w)) for (i in seq_len(nrow(w))) cat(sprintf("  withheld %-12s %s\n", w$what[i], substr(w$reason[i], 1, 110)))
  for (t in fig$tables) {
    cat(sprintf("  table %-14s %4d rows (%s)\n", t$name, nrow(t$data), t$description))
  }
  if (fig$meta$engine == "ggplot") {
    built <- ggplot2::ggplot_build(x)
    cat(sprintf("  built layout: %d panel(s); built layer 1: %d rows\n", nrow(built$layout$layout), nrow(built$data[[1]])))
    geom <- s$leaves[grepl("geom_", s$leaves$path), c("path", "class", "n_expected", "n_drawn", "status")]
    geom$path <- substr(geom$path, 1, 60)
    cat("  geom leaves on the page:\n")
    print(geom, row.names = FALSE)
  }
}
