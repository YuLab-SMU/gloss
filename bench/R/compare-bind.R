# Compare two binding runs leaf by leaf (plan 2026-11-11-tree-binding: every
# binder change is checked against the run before it, on the stratum and on
# v0's development set).
#   Rscript bench/R/compare-bind.R bench/runs/<old>-bind-dev.csv bench/runs/<new>-bind-dev.csv
# Reads both runs' -leaves.csv. Draws nothing, runs no figure code.
#
# A leaf is keyed by its figure and its id (L001, ...), which capture gives in
# drawing order, so a leaf is the same leaf in both runs when the capture of
# its figure did not change; the leaf's path is printed with each move so
# that a renumbering would show. Per leaf, its elements fall in one class
# each: verified, ambiguous, failed (paired leaves), or the leaf's status
# for all of them (unbound, count_mismatch, outside, not_paired). A leaf
# "regresses" when it has fewer elements verified or ambiguous than before.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) stop("usage: Rscript bench/R/compare-bind.R <old-run.csv> <new-run.csv>")
read_leaves <- function(f) {
  lv <- utils::read.csv(sub("\\.csv$", "-leaves.csv", f), stringsAsFactors = FALSE)
  lv$key <- paste(lv$id, lv$leaf)
  lv
}
old <- read_leaves(args[1])
new <- read_leaves(args[2])
line <- function(...) cat(sprintf(...), "\n", sep = "")

classes <- c("verified", "ambiguous", "failed", "unbound", "count_mismatch", "outside", "not_paired")
by_class <- function(lv) {
  m <- matrix(0, nrow(lv), length(classes), dimnames = list(lv$key, classes))
  m[, "verified"] <- lv$verified
  m[, "ambiguous"] <- lv$ambiguous
  m[, "failed"] <- lv$failed
  for (s in c("unbound", "count_mismatch", "outside", "not_paired")) {
    hit <- lv$status == s
    m[hit, s] <- lv$n_elements[hit]
  }
  m[is.na(m)] <- 0
  m
}

figs_old <- unique(old$id)
figs_new <- unique(new$id)
line("== figures: %d in both, %d only in the old run, %d only in the new", length(intersect(figs_old, figs_new)),
     length(setdiff(figs_old, figs_new)), length(setdiff(figs_new, figs_old)))
if (length(setdiff(figs_old, figs_new))) line("   only old: %s", paste(setdiff(figs_old, figs_new), collapse = ", "))
if (length(setdiff(figs_new, figs_old))) line("   only new: %s", paste(setdiff(figs_new, figs_old), collapse = ", "))

both <- intersect(old$key, new$key)
o <- old[match(both, old$key), ]
n <- new[match(both, new$key), ]
same_path <- o$path == n$path
cols <- c("status", "n_elements", "verified", "ambiguous", "failed", "reason")
same <- Reduce(`&`, lapply(cols, function(cl) {
  a <- o[[cl]]
  b <- n[[cl]]
  (is.na(a) & is.na(b)) | (!is.na(a) & !is.na(b) & a == b)
}))
line("\n== leaves of figures in both runs: %d in both, %d only old, %d only new",
     length(both), sum(old$id %in% figs_new & !old$key %in% both), sum(new$id %in% figs_old & !new$key %in% both))
line("   same path in both: %d of %d", sum(same_path), length(both))
line("   status, counts and reason unchanged: %d; changed: %d", sum(same), sum(!same))

mo <- by_class(o)
mn <- by_class(n)
line("\n== elements of the leaves in both runs, by class")
tot <- rbind(old = colSums(mo), new = colSums(mn))
print(tot)

chk_o <- mo[, "verified"] + mo[, "ambiguous"]
chk_n <- mn[, "verified"] + mn[, "ambiguous"]
reg <- which(chk_n < chk_o)
line("\nregressions (leaves with fewer elements verified or ambiguous): %d leaves, %d elements",
     length(reg), sum(chk_o[reg] - chk_n[reg]))
show <- function(idx) {
  if (!length(idx)) return(invisible())
  d <- data.frame(figure = o$id[idx], leaf = o$leaf[idx], geom = n$geom[idx], tag = n$tag[idx],
                  old = paste(o$status[idx], chk_o[idx], sep = ":"), new = paste(n$status[idx], chk_n[idx], sep = ":"),
                  reason = substr(ifelse(is.na(n$reason[idx]), "", n$reason[idx]), 1, 70), stringsAsFactors = FALSE)
  print(d, row.names = FALSE)
}
show(reg)

chg <- which(!same & chk_n >= chk_o)
line("\nother changed leaves: %d (by figure below; old status:checked -> new)", length(chg))
if (length(chg)) {
  if (length(chg) <= 40) show(chg) else {
    agg <- stats::aggregate(cbind(leaves = 1, gained = chk_n[chg] - chk_o[chg]) ~ figure,
                            data.frame(figure = o$id[chg]), sum)
    print(agg, row.names = FALSE)
  }
}

only_new <- new[new$id %in% setdiff(figs_new, figs_old), ]
if (nrow(only_new)) {
  line("\n== figures only in the new run: elements by class")
  m <- by_class(only_new)
  print(do.call(rbind, lapply(split(seq_len(nrow(only_new)), only_new$id), function(i) colSums(m[i, , drop = FALSE]))))
}
