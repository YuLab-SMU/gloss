# Score a run of bench/R/alone.R (agent-path plan Task 2):
#   Rscript bench/R/score-alone.R bench/runs/<stamp>-alone-<scope>-leaves.csv
# Reads the archive only. Element counts are reported with per-figure counts
# and verified apart from ambiguous (AGENTS.md, Done means measured).

args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 1L, file.exists(args[1]))
lv <- utils::read.csv(args[1], stringsAsFactors = FALSE)
figs <- utils::read.csv(sub("-leaves\\.csv$", ".csv", args[1]), stringsAsFactors = FALSE)
cat(sprintf("%s\n%d figures: %s\n", basename(args[1]), nrow(figs),
            paste(names(table(figs$status)), table(figs$status), collapse = ", ")))
if (any(figs$status != "rechecked")) print(figs[figs$status != "rechecked", c("id", "engine", "status", "message")], row.names = FALSE)
cat(sprintf("%d claimed leaves in %d figures, %d elements\n\n", nrow(lv), length(unique(lv$id)), sum(lv$n_elements)))

lv$agree <- lv$same == lv$n_elements
share <- function(a, b) if (b > 0) sprintf("%.1f%%", 100 * a / b) else "-"
by_engine <- do.call(rbind, lapply(split(lv, lv$engine), function(d) {
  per_fig <- split(d, d$id)
  checked <- vapply(per_fig, function(f) sum(f$engine_verified + f$engine_ambiguous), 1)
  full <- vapply(per_fig, function(f) {
    k <- f$engine_verified + f$engine_ambiguous > 0
    any(k) && all(f$alone_verified[k] == f$engine_verified[k] & f$alone_ambiguous[k] == f$engine_ambiguous[k])
  }, TRUE)
  data.frame(engine = d$engine[1], figures = length(per_fig), figures_with_checked = sum(checked > 0),
             figures_all_agree = sum(full),
             engine_verified = sum(d$engine_verified), alone_verified = sum(d$alone_verified),
             verified_share = share(sum(d$alone_verified), sum(d$engine_verified)),
             engine_ambiguous = sum(d$engine_ambiguous), alone_ambiguous = sum(d$alone_ambiguous),
             engine_failed = sum(d$engine_failed), alone_failed = sum(d$alone_failed),
             stringsAsFactors = FALSE)
}))
cat("by engine (elements; a figure agrees when every leaf the engine's positions check has the same counts from the figure alone)\n")
print(by_engine, row.names = FALSE)

# leaves where the figure alone verifies or passes more than the engine's positions do
more <- lv[lv$alone_verified > lv$engine_verified | (lv$alone_verified + lv$alone_ambiguous) > (lv$engine_verified + lv$engine_ambiguous), ]
cat(sprintf("\nleaves where the figure alone passes more elements than the engine's positions: %d\n", nrow(more)))
if (nrow(more)) print(more[, c("id", "leaf", "geom", "tag", "coord", "n_elements", "engine_status", "engine_verified", "engine_ambiguous",
                               "alone_status", "alone_verified", "alone_ambiguous", "gap")], row.names = FALSE)

checked <- lv[lv$engine_verified + lv$engine_ambiguous > 0, ]
cat(sprintf("\nleaves the engine's positions check: %d; the same from the figure alone: %d; not placed: %d; placed and different: %d\n",
            nrow(checked), sum(checked$agree), sum(checked$alone_status == "unbound" & is.na(checked$gap)),
            sum(!checked$agree & !is.na(checked$gap))))
why <- function(d) {
  r <- ifelse(is.na(d$gap), sub("'[^']*'", "'..'", sub("\\([0-9]+ rows\\)", "(n rows)", d$alone_reason)),
              ifelse(d$gap > 0.5, "placed elsewhere (gap over 0.5 pt)", "placed at the same place, another status"))
  r[is.na(r)] <- "no reason given"
  r
}
dis <- checked[!checked$agree, ]
if (nrow(dis)) {
  dis$why <- why(dis)
  t <- do.call(rbind, lapply(split(dis, list(dis$engine, dis$why), drop = TRUE), function(d) {
    data.frame(engine = d$engine[1], why = d$why[1], leaves = nrow(d), figures = length(unique(d$id)),
               elements_checked_by_engine = sum(d$engine_verified + d$engine_ambiguous),
               coords = paste(sort(unique(stats::na.omit(d$coord))), collapse = "+"),
               geoms = paste(utils::head(names(sort(table(d$geom), decreasing = TRUE)), 4), collapse = "+"),
               stringsAsFactors = FALSE)
  }))
  t <- t[order(-t$elements_checked_by_engine), ]
  cat("\nleaves that differ, by engine and reason\n")
  print(t, row.names = FALSE)
}
agree <- checked[checked$agree, ]
cat(sprintf("\ngap between the two placements, leaves that agree: median %.4f pt, max %.4f pt\n",
            stats::median(agree$gap, na.rm = TRUE), max(agree$gap, na.rm = TRUE)))
cat(sprintf("rows shifted by one: elements whose place moves by more than 0.5 pt %d; still passing with the engine's positions %d; with the figure's own %d (of %d moved in leaves it places)\n",
            sum(lv$moved, na.rm = TRUE), sum(lv$moved_pass_engine, na.rm = TRUE), sum(lv$moved_pass_alone, na.rm = TRUE),
            sum(lv$moved[!is.na(lv$moved_pass_alone)], na.rm = TRUE)))
per <- do.call(rbind, lapply(split(lv, lv$id), function(f) data.frame(
  id = f$id[1], engine = f$engine[1], leaves = nrow(f), engine_verified = sum(f$engine_verified),
  alone_verified = sum(f$alone_verified), engine_ambiguous = sum(f$engine_ambiguous), alone_ambiguous = sum(f$alone_ambiguous),
  alone_failed = sum(f$alone_failed), not_placed = sum(is.na(f$gap)), stringsAsFactors = FALSE)))
cat("\nper figure\n")
print(per, row.names = FALSE)
if (!is.null(figs$alone_seconds)) cat(sprintf("\nseconds for the recheck (its own capture included): median %.2f, max %.1f (%s)\n",
    stats::median(figs$alone_seconds, na.rm = TRUE), max(figs$alone_seconds, na.rm = TRUE), figs$id[which.max(figs$alone_seconds)]))
