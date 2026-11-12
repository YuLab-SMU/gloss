# Compare two runs of bench/R/alone.R figure by figure:
#   Rscript bench/R/compare-alone.R <old>-leaves.csv <new>-leaves.csv
# Reads the archives only. A figure "moved" when any of its sums differs.

args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 2L, all(file.exists(args)))
cols <- c("n_elements", "engine_verified", "engine_ambiguous", "engine_failed",
          "alone_verified", "alone_ambiguous", "alone_failed", "same")
per <- function(f) {
  d <- utils::read.csv(f, stringsAsFactors = FALSE)
  s <- stats::aggregate(d[cols], d["id"], sum)
  s$leaves <- as.integer(table(d$id)[s$id])
  s$not_placed <- as.integer(tapply(is.na(d$gap), d$id, sum)[s$id])
  s
}
a <- per(args[1])
b <- per(args[2])
cat(sprintf("%s -> %s\nfigures: %d -> %d; only in the old run: %s; only in the new: %s\n", basename(args[1]), basename(args[2]),
            nrow(a), nrow(b), paste(setdiff(a$id, b$id), collapse = " ") , paste(setdiff(b$id, a$id), collapse = " ")))
m <- merge(a, b, by = "id", suffixes = c(".old", ".new"))
all_cols <- c(cols, "leaves", "not_placed")
engine_cols <- c("n_elements", "engine_verified", "engine_ambiguous", "engine_failed", "leaves")
differs <- function(cs) Reduce(`|`, lapply(cs, function(cn) m[[paste0(cn, ".old")]] != m[[paste0(cn, ".new")]]))
moved <- differs(all_cols)
cat(sprintf("figures whose counts under the engine's positions differ (should be none): %d %s\n",
            sum(differs(engine_cols)), paste(m$id[differs(engine_cols)], collapse = " ")))
cat(sprintf("figures with any count that differs: %d\n", sum(moved)))
if (any(moved)) {
  show <- m[moved, c("id", unlist(lapply(c("alone_verified", "alone_ambiguous", "alone_failed", "same", "not_placed"),
                                         function(cn) paste0(cn, c(".old", ".new")))))]
  print(show, row.names = FALSE)
}
tot <- function(s, cn) sum(s[[cn]])
cat(sprintf("\ntotals, alone verified: %d -> %d; alone ambiguous: %d -> %d; alone failed: %d -> %d; same: %d -> %d of %d\n",
            tot(a, "alone_verified"), tot(b, "alone_verified"), tot(a, "alone_ambiguous"), tot(b, "alone_ambiguous"),
            tot(a, "alone_failed"), tot(b, "alone_failed"), tot(a, "same"), tot(b, "same"), tot(b, "n_elements")))
