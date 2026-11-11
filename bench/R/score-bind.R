# Score a binding run (M1 plan 2026-11-11-m1-roles-and-binding, Task 2).
#   Rscript bench/R/score-bind.R bench/runs/<stamp>-bind-dev.csv
# Reads the run's figure file and its -leaves.csv. Draws nothing.
#
# Layer elements: elements of leaves the engine attributes to a layer or a
# heatmap body or annotation, that is every leaf except `outside` (axes,
# legends, strips, titles, panel backgrounds and grid lines) and except the
# leaves of figures whose engine states no bindings at all (patchwork, grid,
# base: `unbound` with "states no bindings", reported apart). Their elements
# are verified, ambiguous, failed (in a paired leaf), or in a leaf that is
# unbound or count_mismatch.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) stop("usage: Rscript bench/R/score-bind.R <run.csv>")
fig <- utils::read.csv(args[1], stringsAsFactors = FALSE)
lv <- utils::read.csv(sub("\\.csv$", "-leaves.csv", args[1]), stringsAsFactors = FALSE)
pct <- function(a, b) if (b == 0) "-" else sprintf("%.1f%%", 100 * a / b)
line <- function(...) cat(sprintf(...), "\n", sep = "")

line("== figures")
print(table(fig$engine, fig$status))

no_bind <- grepl("states no bindings", lv$reason %||% "")
layer <- lv[lv$status != "outside" & !no_bind, ]
line("\n== layer elements by engine (leaves attributed to a layer, body or track)")
agg <- function(d) {
  el <- d$n_elements
  data.frame(
    figures = length(unique(d$id)), leaves = nrow(d), elements = sum(el, na.rm = TRUE),
    verified = sum(d$verified), ambiguous = sum(d$ambiguous), failed = sum(d$failed),
    unbound = sum(el[d$status == "unbound"], na.rm = TRUE),
    count_mismatch = sum(el[d$status == "count_mismatch"], na.rm = TRUE))
}
by_engine <- do.call(rbind, lapply(split(layer, layer$engine), agg))
by_engine$checked <- mapply(function(v, a, n) pct(v + a, n), by_engine$verified, by_engine$ambiguous, by_engine$elements)
print(by_engine)
tot <- agg(layer)
line("all: %d elements; verified %d, ambiguous %d (verified or ambiguous %s); failed %d; unbound %d; count_mismatch %d",
     tot$elements, tot$verified, tot$ambiguous, pct(tot$verified + tot$ambiguous, tot$elements), tot$failed,
     tot$unbound, tot$count_mismatch)

line("\n== ggplot layer elements by stratum")
gg <- layer[layer$engine == "ggplot", ]
if (nrow(gg)) {
  s <- do.call(rbind, lapply(split(gg, gg$stratum), agg))
  s$checked <- mapply(function(v, a, n) pct(v + a, n), s$verified, s$ambiguous, s$elements)
  print(s)
}

line("\n== engines that state no bindings (leaves, elements)")
nb <- lv[no_bind, ]
if (nrow(nb)) print(stats::aggregate(cbind(leaves = 1, elements = n_elements) ~ engine, nb, sum))

line("\n== paired leaves by geom and tag (ggplot), elements")
pg <- layer[layer$engine == "ggplot" & !is.na(layer$geom), ]
if (nrow(pg)) {
  pg$key <- paste(pg$geom, pg$tag, sep = " / ")
  t <- do.call(rbind, lapply(split(pg, pg$key), function(d) data.frame(
    figures = length(unique(d$id)), leaves = nrow(d), elements = sum(d$n_elements, na.rm = TRUE),
    verified = sum(d$verified), ambiguous = sum(d$ambiguous), failed = sum(d$failed),
    unbound = sum(d$n_elements[d$status == "unbound"], na.rm = TRUE),
    count_mismatch = sum(d$n_elements[d$status == "count_mismatch"], na.rm = TRUE))))
  print(t[order(-t$elements), ])
}

line("\n== unbound reasons (leaves, elements), layer leaves")
ub <- layer[layer$status == "unbound", ]
if (nrow(ub)) {
  ub$why <- sub("[0-9]+ elements? for [0-9]+ rows? in [0-9]+ groups?", "k elements for m rows in n groups", ub$reason)
  r <- stats::aggregate(cbind(leaves = 1, elements = n_elements) ~ engine + why, ub, sum)
  print(r[order(-r$elements), ], right = FALSE)
}

line("\n== figures with failed elements")
fl <- layer[layer$failed > 0, ]
if (nrow(fl)) {
  print(fl[, c("id", "engine", "leaf", "table", "geom", "tag", "mode", "status", "n_elements", "verified",
               "ambiguous", "failed", "max_dev")], row.names = FALSE)
} else line("none")

line("\n== ambiguous elements: in dense leaves / elsewhere")
line("%d / %d", sum(layer$ambiguous[layer$dense %in% TRUE]), sum(layer$ambiguous[!layer$dense %in% TRUE]))

line("\n== time: binding (a second capture plus the bind step) against capture, per figure")
ok <- fig$status == "bound" & !is.na(fig$seconds) & !is.na(fig$bind_seconds)
if (any(ok)) {
  line("median capture %.2f s, median capture + bind %.2f s, maximum capture + bind %.2f s",
       stats::median(fig$seconds[ok]), stats::median(fig$bind_seconds[ok]), max(fig$bind_seconds[ok]))
}
