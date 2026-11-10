# D2 (2026-11-10): what makes gallery-059 (gghighlight) draw differently each time.
# Runs third-party code (a development figure): container only.
#   bench/docker/run.sh Rscript dev_docs/research/capture-fidelity/d2-gghighlight-rng.R
source("bench/R/harvest.R")
use_env(bench_envs$cran); .libPaths(bench_libpaths())
suppressMessages(pkgload::load_all(".", quiet = TRUE, export_all = TRUE, helpers = FALSE))
source("dev_docs/research/capture-fidelity/page-capture.R")
dir <- file.path(figures_root, "gallery-059"); meta <- jsonlite::read_json(file.path(dir, "meta.json"))
exprs <- parse(file.path(dir, "code.R"))
env <- new.env(); pdf(NULL); set.seed(meta$seed)
for (e in exprs) v <- withVisible(eval(e, env))
invisible(dev.off())
p <- v$value
cat("class:", class(p), "\n")
cat("layers:", paste(vapply(p$layers, function(l) class(l$geom)[1], ""), collapse = ", "), "\n")
lab <- p$layers[[length(p$layers)]]
cat("label layer seed param:", deparse(lab$geom_params$seed %||% lab$aes_params$seed %||% lab$stat_params$seed), "\n")
draw <- function(seed = NULL) { if (!is.null(seed)) set.seed(seed); scene_signatures(plain_svg(function() print(p), 7, 5)) }
a <- draw(); b <- draw()
cat(sprintf("two plain prints, RNG not pinned: identical=%s differ=%d\n", identical(a, b), diffn(a, b)))
a <- draw(1); b <- draw(1)
cat(sprintf("two plain prints, same seed before each: identical=%s differ=%d\n", identical(a, b), diffn(a, b)))
# in-place capture with the RNG state restored before the redraw
cap <- function(restore) {
  s <- svglite::svgstring(width = 7, height = 5); dev.control("enable")
  set.seed(7); rs <- .Random.seed
  print(p)
  A <- last_page(s)
  if (restore) assign(".Random.seed", rs, envir = globalenv())
  sub <- capture_grid_page(s)
  x <- scene_signatures(sub$scene); y <- scene_signatures(A)
  sprintf("identical=%s differ=%d", identical(x, y), diffn(x, y))
}
cat("in-place capture, RNG not restored :", cap(FALSE), "\n")
cat("in-place capture, RNG restored     :", cap(TRUE), "\n")
# does the drawing consume the RNG at all?
set.seed(3); r0 <- .Random.seed; invisible(plain_svg(function() print(p), 7, 5)); cat("print() consumes RNG:", !identical(r0, .Random.seed), "\n")
