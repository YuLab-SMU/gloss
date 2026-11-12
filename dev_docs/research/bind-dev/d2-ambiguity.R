# Can what an element shows besides its place (colour, fill, size) tell
# apart the rows that lie within 0.5 pt of it? (M1 plan, scope change
# "Most bindings the development set can check are ambiguous"; the two
# figures that hold 15173 of 15328 ambiguous elements in run 2026-11-11-1231.)
# Runs third-party code: only in the bench container, with no network:
#   GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript dev_docs/research/bind-dev/d2-ambiguity.R exts-022
# For each ambiguous element of a ggplot layer: the rows of its layer and
# panel within the tolerance (its candidates), whether they differ in colour,
# fill, size or shape at all, and how many of them show the element's own
# stroke and fill colours. A candidate set whose rows are all alike cannot be
# separated by any aesthetic; one where exactly one row matches the element
# could be.

source("bench/R/common.R")
.libPaths(unique(c(bench_envs$cran$lib, .libPaths())))
suppressMessages(pkgload::load_all(".", quiet = TRUE, export_all = TRUE, helpers = FALSE))
id <- commandArgs(trailingOnly = TRUE)[1]
exprs <- parse(file.path("bench/figures", id, "code.R"), keep.source = FALSE)
env <- new.env()
setwd(file.path(tempdir()))
for (f in list.files(file.path("/gloss/bench/figures", id), full.names = TRUE)) file.copy(f, ".", recursive = TRUE)
set.seed(as.integer(jsonlite::read_json(file.path("/gloss/bench/figures", id, "meta.json"))$seed))
grDevices::pdf(NULL)
val <- NULL
for (ex in exprs) {
  v <- withVisible(eval(ex, env))
  if (inherits(v$value, "ggplot")) val <- v$value
}
grDevices::dev.off()
eng <- gl_plugin("engine", "ggplot")
res <- suppressWarnings(capture_figure(val, eng, context = FALSE))
sub <- res$fig$substrate
b <- bind_figure(res$fig, eng, res$state)
stated <- eng$bind(res$state, sub)
geo <- scene_geometry(sub)
built <- res$state$built
same <- function(a, b) {
  ok <- !is.na(a) & !is.na(b) & a != "none" & b != "none"
  out <- rep(NA, length(a))
  if (any(ok)) {
    ca <- grDevices::col2rgb(a[ok]); cb <- grDevices::col2rgb(b[ok])
    out[ok] <- colSums(abs(ca - cb)) == 0
  }
  out
}
rows_out <- list()
for (cl in stated$claims) {
  el <- b$elements[b$elements$leaf == cl$leaf & b$elements$status == "ambiguous", , drop = FALSE]
  if (!nrow(el)) next
  i <- as.integer(sub("^built_layer", "", cl$table))
  d <- built$data[[i]]
  g <- geo[match(el$element, geo$id), , drop = FALSE]
  ex <- if (all(g$tag == "circle")) g$cx else (g$x0 + g$x1) / 2
  ey <- if (all(g$tag == "circle")) g$cy else (g$y0 + g$y1) / 2
  pr <- pairs_within(ex, ey, cl$pred$x, cl$pred$y, bind_tolerance)
  for (k in seq_len(nrow(el))) {
    cand <- cl$pred$row[pr$q[pr$p == k]]
    a <- d[cand, intersect(c("colour", "fill", "size", "shape", "alpha", "label"), names(d)), drop = FALSE]
    alike <- nrow(unique(a)) == 1L
    col_match <- if (!is.null(a$colour)) sum(same(rep(g$stroke[k], nrow(a)), as.character(a$colour)) |
                                              same(rep(g$fill[k], nrow(a)), as.character(a$colour)), na.rm = TRUE) else NA
    rows_out[[length(rows_out) + 1L]] <- data.frame(layer = i, geom = class(res$state$built$plot$layers[[i]]$geom)[1],
                                                    tag = g$tag[k], candidates = length(cand), alike = alike,
                                                    colour_matches = col_match)
  }
}
o <- do.call(rbind, rows_out)
cat(sprintf("%s: %d ambiguous elements\n", id, nrow(o)))
o$elements <- 1L
print(stats::aggregate(elements ~ layer + geom + tag + alike, o, sum))
cat("\ncandidate rows per ambiguous element (quantiles):", stats::quantile(o$candidates, c(0, .5, .9, 1)), "\n")
cat("elements whose candidates differ in some aesthetic:", sum(!o$alike), "\n")
cat("of those, elements whose own colour matches exactly one candidate:", sum(!o$alike & o$colour_matches %in% 1L), "\n")
