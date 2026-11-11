# The second batch for the label workbench (M1 plan Task 1, Scope change of
# 2026-11-11): two development figures per engine, drawn by seed from the
# figures captured in run 2026-11-11-1220 that are not in the pilot and have
# at most 80 leaves to label. The cap was fixed before the draw: the owner
# labelled the pilot at about 17 s a leaf, so 80 leaves are some 20 minutes;
# the five larger figures (129 to 4011 leaves) need a sample of leaves, which
# the workbench cannot yet show.
#   Rscript bench/labels/batch2/select.R   -> bench/labels/batch2/figures.csv
run <- utils::read.csv("bench/runs/2026-11-11-1220-capture-dev.csv", stringsAsFactors = FALSE)
run <- run[run$status == "captured", ]
pilot <- utils::read.csv("bench/labels/pilot/figures.csv", stringsAsFactors = FALSE)$id
run$leaves <- vapply(run$id, function(i) sum(utils::read.csv(file.path("bench/labels/sheets", paste0(i, ".csv")))$n_elements > 0), 1L)
cap <- 80L
set.seed(20261112)
engines <- c("ggplot", "patchwork", "heatmap", "grid", "base")
pick <- do.call(rbind, lapply(engines, function(e) {
  rest <- run[run$engine == e & !run$id %in% pilot, ]
  ok <- rest[rest$leaves <= cap, ]
  ids <- sort(ok$id)
  take <- ids[sample.int(length(ids), min(2L, length(ids)))]
  data.frame(engine = e, not_in_pilot = nrow(rest), over_cap = nrow(rest) - nrow(ok), candidates = length(ids),
             id = take, leaves = ok$leaves[match(take, ok$id)])
}))
utils::write.csv(pick, "bench/labels/batch2/figures.csv", row.names = FALSE)
print(pick)
cat("leaves to label:", sum(pick$leaves), "\n")
