# The pilot's 5 figures (M1 plan Task 1): one development figure per engine,
# drawn by seed from the figures captured in run 2026-11-11-1220.
#   Rscript bench/labels/pilot/select.R   -> bench/labels/pilot/figures.csv
run <- utils::read.csv("bench/runs/2026-11-11-1220-capture-dev.csv", stringsAsFactors = FALSE)
run <- run[run$status == "captured", ]
set.seed(20261111)
engines <- c("ggplot", "patchwork", "heatmap", "grid", "base")
pick <- do.call(rbind, lapply(engines, function(e) {
  ids <- sort(run$id[run$engine == e])
  data.frame(engine = e, candidates = length(ids), id = ids[sample.int(length(ids), 1L)])
}))
utils::write.csv(pick, "bench/labels/pilot/figures.csv", row.names = FALSE)
print(pick)
