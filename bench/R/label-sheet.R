# Label sheets for the bench figures (M1 plan 2026-11-11-m1-roles-and-binding,
# Task 1). Two steps, because the figures' code runs only in the container:
#
#   1. capture, in the container with no network: each figure is captured as
#      capture.R does and its substrate saved under runs/<stamp>-sheets-<set>/
#      (the .rds files stay out of git), with an index of what was captured:
#        GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/label-sheet.R capture dev [id ...]
#   2. draw, anywhere (it reads saved substrates only, runs no figure code):
#        Rscript bench/R/label-sheet.R draw bench/runs/<stamp>-sheets-dev [out dir]
#      writes <id>.csv, <id>.svg and the PNGs to bench/labels/sheets/ (default).

args <- commandArgs(trailingOnly = TRUE)
if (!length(args) || !args[1] %in% c("capture", "draw")) stop("usage: label-sheet.R capture <set> [id ...] | draw <dir> [out]")

if (args[1] == "capture") {
  source("bench/R/harvest.R")
  set <- if (length(args) > 1) args[2] else "dev"
  stopifnot(set %in% c("dev", "heldout"))
  if (set == "heldout") stop("label sheets for the held-out set belong to the next plan's annotation protocol")
  reachable <- tryCatch({
    con <- suppressWarnings(socketConnection("cloud.r-project.org", 80, blocking = TRUE, timeout = 5))
    close(con); TRUE
  }, error = function(e) FALSE)
  if (reachable) stop("the network is reachable; run with GLOSS_BENCH_OFFLINE=true bench/docker/run.sh")
  split <- read_csv(file.path(bench_root, "split.csv"))
  todo <- split[split$set == set, ]
  if (length(args) > 2) todo <- todo[todo$id %in% args[-(1:2)], ]
  stamp <- format(Sys.time(), "%Y-%m-%d-%H%M", tz = "UTC")
  out <- normalizePath(file.path(bench_root, "runs", sprintf("%s-sheets-%s", stamp, set)), mustWork = FALSE)
  dir.create(out, recursive = TRUE)
  head_file <- tryCatch(readLines(".git/HEAD", warn = FALSE)[1], error = function(e) NA)
  commit <- if (!is.na(head_file) && startsWith(head_file, "ref: ")) {
    ref <- file.path(".git", sub("^ref: ", "", head_file))
    if (file.exists(ref)) readLines(ref, warn = FALSE)[1] else NA
  } else head_file
  rows <- list()
  for (k in seq_len(nrow(todo))) {
    id <- todo$id[k]
    keep <- file.path(out, paste0(id, ".rds"))
    e <- check_eligibility(file.path(bench_root, "figures", id), todo$engine[k], timeout = 900,
                           capture = TRUE, keep = keep)
    cap <- e$run$capture
    st <- if (file.exists(keep)) "captured" else cap$status %||% e$run$error$stage %||% "not captured"
    rows[[k]] <- data.frame(id = id, engine = todo$engine[k], status = st,
                            message = substr(cap$message %||% e$run$error$message %||% "", 1, 200),
                            leaves = cap$leaves %||% NA, elements = cap$elements %||% NA,
                            commit = commit, stringsAsFactors = FALSE)
    write_csv(do.call(rbind, rows), file.path(out, "index.csv"))
    cat(sprintf("[%d/%d] %s %s: %s\n", k, nrow(todo), id, todo$engine[k], st))
  }
} else {
  source("bench/R/sheet.R")
  dir <- args[2]
  out <- if (length(args) > 2) args[3] else "bench/labels/sheets"
  idx <- utils::read.csv(file.path(dir, "index.csv"), stringsAsFactors = FALSE)
  for (id in idx$id[idx$status == "captured"]) {
    x <- readRDS(file.path(dir, paste0(id, ".rds")))
    tab <- write_sheet(x$substrate, id, out)
    cat(sprintf("%s: %d leaves, %d elements\n", id, nrow(tab), sum(tab$n_elements)))
  }
  file.copy(file.path(dir, "index.csv"), file.path(out, "index.csv"), overwrite = TRUE)
}
