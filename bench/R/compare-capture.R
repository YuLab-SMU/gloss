# Compare two capture runs figure by figure, cell by cell, over every column
# both have but `seconds` (plan 2026-11-11-tree-binding: a change to capture
# is checked against the run before it). Used since Task 5 from a scratch
# copy; archived here for Task 6.
#   Rscript bench/R/compare-capture.R bench/runs/<old>-capture-dev.csv bench/runs/<new>-capture-dev.csv
# Draws nothing, runs no figure code.

a <- commandArgs(trailingOnly = TRUE)
if (length(a) != 2L) stop("usage: Rscript bench/R/compare-capture.R <old-run.csv> <new-run.csv>")
o <- read.csv(a[1], stringsAsFactors = FALSE)
n <- read.csv(a[2], stringsAsFactors = FALSE)
cat("figures:", nrow(o), "old,", nrow(n), "new; same ids:", identical(sort(o$id), sort(n$id)), "\n")
n <- n[match(o$id, n$id), ]
cols <- setdiff(intersect(names(o), names(n)), "seconds")
cat("columns compared:", length(cols), "| only old:", paste(setdiff(names(o), names(n)), collapse = ","),
    "| only new:", paste(setdiff(names(n), names(o)), collapse = ","), "\n")
same <- function(x, y) (is.na(x) & is.na(y)) | (!is.na(x) & !is.na(y) & as.character(x) == as.character(y))
n_diff <- 0L
for (cl in cols) {
  d <- which(!same(o[[cl]], n[[cl]]))
  n_diff <- n_diff + length(d)
  for (i in d) cat(sprintf("  %s %s: %s -> %s\n", o$id[i], cl, substr(as.character(o[[cl]][i]), 1, 160), substr(as.character(n[[cl]][i]), 1, 160)))
}
cat("cells that differ:", n_diff, "\n")
cat("mismatch leaves:", sum(o$leaves_mismatch, na.rm = TRUE), "->", sum(n$leaves_mismatch, na.rm = TRUE), "\n")
