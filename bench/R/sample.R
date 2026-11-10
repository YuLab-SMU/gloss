# Draw the PSU sample (bench v0, Task 2). Run from the repository root:
#   Rscript bench/R/sample.R
# Each stratum gets its own seed (seed + stratum number) and a full random
# permutation of its frame; the sample is the first n of that permutation,
# skipping PSUs already drawn in an earlier stratum and PSUs the frame marks
# out of scope. A later round continues down the same permutations, so
# earlier draws never change.

source("bench/R/common.R")
RNGkind("Mersenne-Twister", "Inversion", "Rejection")

allocation <- c(gallery = 70L, exts = 30L, bioc = 30L, patchwork = 15L, heatmap = 15L)

frames <- list(
  gallery = transform(read_csv(file.path(bench_root, "frame/gallery.csv"))[, "psu", drop = FALSE], kind = "gallery"),
  exts = transform(read_csv(file.path(bench_root, "frame/exts.csv")), kind = "examples"),
  bioc = transform(read_csv(file.path(bench_root, "frame/bioc.csv"))[, "psu", drop = FALSE], kind = "vignette"),
  patchwork = read_csv(file.path(bench_root, "frame/patchwork.csv")),
  heatmap = read_csv(file.path(bench_root, "frame/heatmap.csv"))
)
frames$heatmap$kind[frames$heatmap$kind == "bioc"] <- "vignette"
# a PSU is identified by kind plus name; a Gallery post is the same PSU in
# the gallery and patchwork strata, a Bioconductor package the same in bioc
# and heatmap
key <- function(f) paste(f$kind, f$psu)

drawn <- character()
rows <- list()
for (h in seq_along(allocation)) {
  stratum <- names(allocation)[h]
  f <- frames[[stratum]]
  if (is.null(f$in_scope)) f$in_scope <- TRUE
  f <- f[order(f$psu), , drop = FALSE]
  set.seed(seed + h)
  perm <- f[sample.int(nrow(f)), , drop = FALSE]
  perm$rank <- seq_len(nrow(perm))
  # out-of-scope rows stay in the permutation (ranks do not move) but are skipped
  perm <- perm[perm$in_scope & !key(perm) %in% drawn, , drop = FALSE]
  n_in <- sum(f$in_scope)
  take <- perm[seq_len(min(allocation[[stratum]], nrow(perm))), , drop = FALSE]
  drawn <- c(drawn, key(take))
  rows[[stratum]] <- data.frame(
    id = sprintf("%s-%03d", stratum, take$rank),
    stratum = stratum,
    rank = take$rank,
    kind = take$kind,
    psu = take$psu,
    frame_size = n_in,
    out_of_scope = nrow(f) - n_in,
    n_stratum = allocation[[stratum]],
    stratum_seed = seed + h,
    weight = n_in / allocation[[stratum]],
    stringsAsFactors = FALSE
  )
}
smp <- do.call(rbind, rows)
rownames(smp) <- NULL
write_csv(smp, file.path(bench_root, "sample.csv"))
cat("sampled", nrow(smp), "PSUs\n"); print(table(smp$stratum, smp$kind))
