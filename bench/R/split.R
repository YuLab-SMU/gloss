# Split retained figures into development and held-out sets and write the
# freeze manifest (bench v0, Task 5). Run from the repository root:
#   Rscript bench/R/split.R
# Refuses to run once any capture run exists: the split must come first.

source("bench/R/common.R")
RNGkind("Mersenne-Twister", "Inversion", "Rejection")

runs <- list.files(file.path(bench_root, "runs"), pattern = "capture", full.names = TRUE)
if (length(runs)) stop("capture runs already exist; the split must be made before any capture run")

att <- read_csv(file.path(bench_root, "runs", "attempts.csv"))
smp <- read_csv(file.path(bench_root, "sample.csv"))
stopifnot(setequal(att$id, smp$id))
# a figure is eligible only if it also reran in a container with no network
oc_file <- file.path(bench_root, "runs", "offline-check.csv")
if (!file.exists(oc_file)) stop("run bench/R/offline-check.R (no network) before the split")
oc <- read_csv(oc_file)
stopifnot(setequal(oc$id, att$id[att$outcome == "retained"]))
cat("offline check:", sum(oc$ok), "of", nrow(oc), "retained figures rerun with no network\n")
ret <- att[att$outcome == "retained" & att$id %in% oc$id[oc$ok], ]
stopifnot(all(dir.exists(file.path(bench_root, "figures", ret$id))))

strata <- c("gallery", "exts", "bioc", "patchwork", "heatmap")
rows <- list()
for (h in seq_along(strata)) {
  r <- ret[ret$stratum == strata[h], ]
  r <- r[order(r$id), ]
  set.seed(seed + 100L + h)
  r <- r[sample.int(nrow(r)), ]
  n_dev <- ceiling(nrow(r) / 2)   # an odd stratum gives the extra figure to development
  rows[[h]] <- data.frame(id = r$id, stratum = r$stratum, engine = r$engine,
                          set = rep(c("dev", "heldout"), c(n_dev, nrow(r) - n_dev)),
                          stringsAsFactors = FALSE)
}
split <- do.call(rbind, rows)
split <- split[order(match(split$id, smp$id)), ]
write_csv(split, file.path(bench_root, "split.csv"))

files <- c(list.files(file.path(bench_root, "figures"), recursive = TRUE, full.names = TRUE),
           file.path(bench_root, c("sample.csv", "split.csv", "runs/attempts.csv", "runs/offline-check.csv")),
           list.files(file.path(bench_root, "frame"), full.names = TRUE))
files <- sort(files)
rel <- sub(paste0("^", bench_root, "/"), "", files)
writeLines(paste(md5(files), rel, sep = "  "), file.path(bench_root, "MANIFEST.md5"))

cat("retained", nrow(ret), "of", nrow(att), "\n")
print(table(split$stratum, split$set))
print(table(split$engine, split$set))
