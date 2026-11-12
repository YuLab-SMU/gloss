# Split a stratum added after v0 into development and held-out halves and
# extend the manifest (bench v1, plan 2026-11-11-bench-tree-stratum, Task 4):
#   Rscript bench/R/split-tree.R
# As split.R does for the five strata of v0, for one more: seeded by stratum
# number, the odd figure to development, only figures that reran with no
# network. The rows of v0 in split.csv are not touched, and the stratum must
# not have been captured: its figures may appear in no capture run.
source("bench/R/common.R")
RNGkind("Mersenne-Twister", "Inversion", "Rejection")
stratum <- "tree"; h <- 6L
att <- read_csv(file.path(bench_root, "runs", "attempts.csv"))
smp <- read_csv(file.path(bench_root, "sample.csv"))
split <- read_csv(file.path(bench_root, "split.csv"))
stopifnot(setequal(att$id, smp$id), !any(split$stratum == stratum))
runs <- list.files(file.path(bench_root, "runs"), pattern = "capture.*\\.csv$", full.names = TRUE)
seen <- unlist(lapply(runs, function(f) { x <- tryCatch(read_csv(f), error = function(e) NULL); if (is.null(x$id)) character() else x$id }))
tree_ids <- att$id[att$stratum == stratum]
if (any(tree_ids %in% seen)) stop("figures of the stratum appear in a capture run; the split must come first")
oc <- read_csv(file.path(bench_root, "runs", "offline-check.csv"))
ret <- att[att$stratum == stratum & att$outcome == "retained", ]
stopifnot(all(ret$id %in% oc$id))
cat("offline check:", sum(oc$ok[oc$id %in% ret$id]), "of", nrow(ret), "retained figures of the stratum rerun with no network\n")
r <- ret[ret$id %in% oc$id[oc$ok], ]
stopifnot(all(dir.exists(file.path(bench_root, "figures", r$id))))
r <- r[order(r$id), ]
set.seed(seed + 100L + h)
r <- r[sample.int(nrow(r)), ]
n_dev <- ceiling(nrow(r) / 2)
add <- data.frame(id = r$id, stratum = r$stratum, engine = r$engine,
                  set = rep(c("dev", "heldout"), c(n_dev, nrow(r) - n_dev)), stringsAsFactors = FALSE)
add <- add[order(match(add$id, smp$id)), ]
write_csv(rbind(split, add), file.path(bench_root, "split.csv"))

files <- c(list.files(file.path(bench_root, "figures"), recursive = TRUE, full.names = TRUE),
           file.path(bench_root, c("sample.csv", "split.csv", "runs/attempts.csv", "runs/offline-check.csv")),
           list.files(file.path(bench_root, "frame"), full.names = TRUE))
files <- sort(files)
rel <- sub(paste0("^", bench_root, "/"), "", files)
writeLines(paste(md5(files), rel, sep = "  "), file.path(bench_root, "MANIFEST.md5"))
cat("stratum", stratum, ": retained", nrow(ret), "of", sum(att$stratum == stratum), "; split", n_dev, "development,", nrow(r) - n_dev, "held-out\n")
print(table(add$engine, add$set))
