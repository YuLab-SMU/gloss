# Score a run of bench/R/bundle.R (agent-path plan 2026-11-12, Task 5b):
#   Rscript bench/R/score-bundle.R bench/runs/<stamp>-bundle-dev.csv
# Reads the run's file. Draws nothing, runs no figure code.

args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 1L, file.exists(args[1]))
d <- utils::read.csv(args[1], stringsAsFactors = FALSE)
cap <- d[d$status == "captured", ]
cat(sprintf("%s | %d figures, %d captured with a round trip (others: %s)\n\n", basename(args[1]), nrow(d), nrow(cap),
            paste(names(table(d$status[d$status != "captured"])), table(d$status[d$status != "captured"]), collapse = ", ")))
show <- function(stage_col, msg_col, what) {
  st <- cap[[stage_col]]
  cat(sprintf("%s: %s\n", what, paste(names(table(st)), table(st), collapse = ", ")))
  for (s in setdiff(unique(st), "identical")) {
    x <- cap[st == s, ]
    by <- split(x$id, x[[msg_col]])
    for (m in names(by)) cat(sprintf("  %s | %s: %d (%s)\n", s, substr(m, 1, 110), length(by[[m]]), paste(by[[m]], collapse = " ")))
  }
}
show("all_stage", "all_message", "everything embedded")
show("default_stage", "default_message", "default embedding")
both <- table(all = cap$all_stage, default = cap$default_stage)
cat("\neverything embedded (rows) against the default embedding (columns)\n")
print(both)
cat("\nby engine: written with everything embedded, of captured\n")
print(do.call(rbind, lapply(split(cap, cap$engine), function(x) {
  data.frame(engine = x$engine[1], captured = nrow(x), written = sum(x$all_stage != "not written"),
             identical = sum(x$all_stage == "identical"), default_written = sum(x$default_stage != "not written"))
})), row.names = FALSE)
ok <- cap[!is.na(cap$all_kb), ]
if (nrow(ok)) cat(sprintf("\nsize, everything embedded: median %.0f KB, largest %.0f KB (%s); default: median %.0f KB, largest %.0f KB\n",
                          stats::median(ok$all_kb), max(ok$all_kb), ok$id[which.max(ok$all_kb)],
                          stats::median(cap$default_kb, na.rm = TRUE), max(cap$default_kb, na.rm = TRUE)))
p <- cap[cap$tried > 0, ]
cat(sprintf("\ngl_propose() on the default bundle read back: %d figures with a pairing to try, %d pairings; accepted %d, rejected %d, refused %d, errors %d\n",
            nrow(p), sum(p$tried), sum(p$accepted), sum(p$rejected), sum(p$refused), sum(p$propose_errors)))
not_all <- p[p$accepted < p$tried, c("id", "engine", "tried", "accepted", "rejected", "refused", "reasons")]
if (nrow(not_all)) {
  not_all$reasons <- substr(not_all$reasons, 1, 150)
  print(not_all, row.names = FALSE)
}
cat(sprintf("captured figures with no pairing to try (no element bound one for one row and verified): %d\n", sum(cap$tried == 0)))
