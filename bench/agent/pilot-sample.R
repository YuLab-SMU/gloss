# The pilot's figures (agent-path plan 2026-11-12, Task 5): a seeded sample of
# the development figures that have circles or rectangles verified one for
# one row, by stratum in proportion. Reads archived bind runs only; runs no
# figure code and no model.
#   Rscript bench/agent/pilot-sample.R
# Writes bench/agent/pilot-figures.csv: every figure of the population with
# its place in its stratum's seeded order; the first `take` of a stratum are
# the sample, and the next in order stands in for one whose material cannot
# be made (reported when it happens).

runs <- c("bench/runs/2026-11-12-1116-bind-dev-leaves.csv", "bench/runs/2026-11-12-1107-bind-dev-tree-leaves.csv")
seed <- 20261113L
n_figures <- 10L

lv <- do.call(rbind, lapply(runs, utils::read.csv, stringsAsFactors = FALSE))
lv <- lv[lv$engine %in% c("ggplot", "patchwork"), ]
figures_all <- length(unique(lv$id))
ok <- lv$mode %in% c("row", "symbol") & lv$verified > 0 & lv$tag %in% c("circle", "rect") & grepl("built_layer", lv$table)
one <- lv[ok, ]
pop <- do.call(rbind, lapply(split(one, one$id), function(d) {
  data.frame(id = d$id[1], stratum = d$stratum[1], engine = d$engine[1], leaves = nrow(d),
             tables = length(unique(d$table)), elements = sum(d$verified),
             tags = paste(sort(unique(d$tag)), collapse = "+"), stringsAsFactors = FALSE)
}))
pop <- pop[order(pop$stratum, pop$id), ]
# largest remainders, so the shares add up to n_figures
share <- n_figures * table(pop$stratum) / nrow(pop)
take <- floor(share)
left <- n_figures - sum(take)
if (left > 0) {
  up <- names(sort(share - take, decreasing = TRUE))[seq_len(left)]
  take[up] <- take[up] + 1L
}
set.seed(seed)
pop$order <- NA_integer_
for (s in sort(unique(pop$stratum))) {
  k <- which(pop$stratum == s)
  pop$order[k[sample.int(length(k))]] <- seq_along(k)
}
pop$sampled <- pop$order <= as.integer(take[pop$stratum])
pop <- pop[order(pop$stratum, pop$order), ]
utils::write.csv(pop, "bench/agent/pilot-figures.csv", row.names = FALSE)
cat(sprintf("population: %d of %d ggplot and patchwork development figures; by stratum: %s\n", nrow(pop), figures_all,
            paste(names(table(pop$stratum)), table(pop$stratum), collapse = ", ")))
cat(sprintf("sample of %d (seed %d): %s\n", sum(pop$sampled), seed,
            paste(names(take), as.integer(take), collapse = ", ")))
print(pop[pop$sampled, c("stratum", "id", "engine", "leaves", "tables", "elements", "tags")], row.names = FALSE)
