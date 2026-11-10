# Capture the frozen figures of one set with gloss() (bench v0, Task 6).
# Runs third-party code, so run it in the container:
#   bench/docker/run.sh Rscript bench/R/capture.R dev
# The held-out set only produces reported numbers: running it needs the
# explicit argument "heldout" and is archived like any other run.

source("bench/R/harvest.R")
args <- commandArgs(trailingOnly = TRUE)
set <- if (length(args)) args[1] else "dev"
stopifnot(set %in% c("dev", "heldout"))

split <- read_csv(file.path(bench_root, "split.csv"))
todo <- split[split$set == set, ]
stamp <- format(Sys.time(), "%Y-%m-%d-%H%M", tz = "UTC")
out_file <- file.path(bench_root, "runs", sprintf("%s-capture-%s.csv", stamp, set))

refusal <- function(msg) {
  if (grepl("uses a mask", msg)) return("refused: mask")
  if (grepl("No engine plugin handles", msg)) return("refused: no engine")
  if (grepl("does not support graphics groups", msg)) return("refused: device without groups")
  if (grepl("integrity check failed", msg)) return("refused: integrity check")
  NA_character_
}

rows <- list()
for (k in seq_len(nrow(todo))) {
  id <- todo$id[k]
  dir <- file.path(bench_root, "figures", id)
  e <- check_eligibility(dir, todo$engine[k], capture = TRUE)
  cap <- e$run$capture
  status <- if (!is.null(e$run$error)) paste("rerun:", e$run$error$stage)
            else if (is.null(cap)) "no figure recovered"
            else if (identical(cap$status, "captured")) "captured"
            else refusal(cap$message) %||% "error"
  ls <- cap$leaf_status %||% list()
  rows[[k]] <- data.frame(
    id = id, stratum = todo$stratum[k], engine = todo$engine[k],
    recovered = e$run$recovered$kind %||% NA, status = status,
    message = substr(cap$message %||% e$run$error$message %||% "", 1, 300),
    elements = cap$elements %||% NA, leaves = cap$leaves %||% NA, panels = cap$panels %||% NA,
    leaves_ok = ls$ok %||% 0L, leaves_mismatch = ls$count_mismatch %||% 0L,
    leaf_status = paste(names(ls), unlist(ls), sep = "=", collapse = " "),
    unowned = cap$unowned %||% NA, seconds = cap$seconds %||% NA,
    stringsAsFactors = FALSE)
  write_csv(do.call(rbind, rows), out_file)
  cat(sprintf("[%d/%d] %s %s: %s %s\n", k, nrow(todo), id, todo$engine[k], status, substr(rows[[k]]$message, 1, 70)))
}
env <- list(set = set, figures = nrow(todo), started = stamp, R = R.version.string,
            image = Sys.getenv("GLOSS_BENCH_IMAGE_DIGEST", NA),
            environments = lapply(bench_envs, function(e) list(
              cran = e$cran,
              packages = lapply(setNames(nm = c("gloss", "ggplot2", "ComplexHeatmap", "patchwork", "svglite", "gridGraphics", "grid")),
                                function(p) tryCatch(as.character(utils::packageVersion(p, lib.loc = c(bench_libpaths(e), "."))), error = function(err) NA)))))
jsonlite::write_json(env, sub("\\.csv$", ".json", out_file), auto_unbox = TRUE, pretty = TRUE)
