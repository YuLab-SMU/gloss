# Recheck the engines' claims from the figure alone on the frozen figures of
# one set (agent-path plan 2026-11-12, Task 2): capture each figure, then
# check every claim of its engine twice, with the engine's positions and with
# the table's position columns put through the panel's scales, and archive
# one row per figure and one row per claimed leaf.
# Runs third-party code, so run it in the container, with no network:
#   GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/alone.R dev
#   GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/alone.R dev tree
# Development sets only: this script refuses the held-out set.
#
# Output: runs/<stamp>-alone-<set>[-<stratum>].csv (figures), -leaves.csv (claimed leaves), .json.

source("bench/R/harvest.R")
args <- commandArgs(trailingOnly = TRUE)
set <- if (length(args)) args[1] else "dev"
stratum <- if (length(args) > 1) args[2] else NULL
if (!identical(set, "dev")) stop("alone.R runs on the development sets only")

reachable <- tryCatch({
  con <- suppressWarnings(socketConnection("cloud.r-project.org", 80, blocking = TRUE, timeout = 5))
  close(con); TRUE
}, error = function(e) FALSE)
if (reachable) stop("the network is reachable; run with GLOSS_BENCH_OFFLINE=true bench/docker/run.sh")

split <- read_csv(file.path(bench_root, "split.csv"))
todo <- set_figures(split, set, stratum)
stamp <- format(Sys.time(), "%Y-%m-%d-%H%M", tz = "UTC")
gloss_snapshot()
out_file <- file.path(bench_root, "runs", sprintf("%s-alone-%s.csv", stamp, run_scope(set, stratum)))
leaf_file <- sub("\\.csv$", "-leaves.csv", out_file)

git_head <- function() {
  h <- tryCatch(readLines(".git/HEAD", warn = FALSE)[1], error = function(e) NA_character_)
  if (is.na(h) || !startsWith(h, "ref: ")) return(h)
  ref <- sub("^ref: ", "", h)
  if (file.exists(file.path(".git", ref))) return(readLines(file.path(".git", ref), warn = FALSE)[1])
  packed <- tryCatch(readLines(".git/packed-refs", warn = FALSE), error = function(e) character())
  hit <- grep(paste0(" ", ref, "$"), packed, value = TRUE)
  if (length(hit)) sub(" .*$", "", hit[1]) else NA_character_
}
commit_at_start <- git_head()

timeout <- 900
rows <- list()
leaf_rows <- list()
for (k in seq_len(nrow(todo))) {
  id <- todo$id[k]
  dir <- file.path(bench_root, "figures", id)
  e <- check_eligibility(dir, todo$engine[k], timeout = timeout, capture = TRUE, alone = TRUE)
  cap <- e$run$capture
  status <- if (!is.null(e$run$error)) {
              if (identical(e$run$error$stage, "timeout")) "timeout" else paste("rerun:", e$run$error$stage)
            }
            else if (is.null(cap)) "no figure recovered"
            else if (!identical(e$run$recovered$engine, todo$engine[k])) "rerun: engine changed"
            else if (!identical(cap$status, "captured")) "not captured"
            else if (!is.null(cap$alone_error)) "alone error"
            else "rechecked"
  lv <- cap$alone_leaves
  tot <- function(col) if (is.null(lv)) NA_integer_ else sum(lv[[col]], na.rm = TRUE)
  row <- data.frame(
    id = id, stratum = todo$stratum[k], engine = todo$engine[k], status = status,
    message = substr(cap$alone_error %||% cap$message %||% e$run$error$message %||% "", 1, 300),
    claimed_leaves = if (is.null(lv)) NA else nrow(lv), elements = tot("n_elements"),
    engine_verified = tot("engine_verified"), engine_ambiguous = tot("engine_ambiguous"), engine_failed = tot("engine_failed"),
    alone_verified = tot("alone_verified"), alone_ambiguous = tot("alone_ambiguous"), alone_failed = tot("alone_failed"),
    same = tot("same"),
    leaves_not_placed = if (is.null(lv)) NA else sum(lv$alone_status == "unbound" & lv$engine_status != "unbound"),
    seconds = cap$seconds %||% NA, alone_seconds = cap$alone_seconds %||% NA,
    stringsAsFactors = FALSE)
  rows[[k]] <- row
  if (!is.null(lv) && nrow(lv)) {
    lv$id <- id
    lv$stratum <- todo$stratum[k]
    lv$engine <- todo$engine[k]
    leaf_rows[[length(leaf_rows) + 1L]] <- lv[, c("id", "stratum", "engine", setdiff(names(lv), c("id", "stratum", "engine")))]
  }
  write_csv(do.call(rbind, rows), out_file)
  if (length(leaf_rows)) write_csv(do.call(rbind, leaf_rows), leaf_file)
  cat(sprintf("[%d/%d] %s %s: %s | engine verified %s ambiguous %s | alone verified %s ambiguous %s | same %s of %s %s\n",
              k, nrow(todo), id, todo$engine[k], status, row$engine_verified, row$engine_ambiguous,
              row$alone_verified, row$alone_ambiguous, row$same, row$elements, substr(row$message, 1, 60)))
}
env <- list(set = set, stratum = stratum %||% "v0", figures = nrow(todo), started = stamp, commit = commit_at_start, commit_at_end = git_head(),
            gloss_source_digest = gloss_source$digest, timeout = timeout,
            tolerance_pt = 0.5, R = R.version.string,
            image = Sys.getenv("GLOSS_BENCH_IMAGE_DIGEST", NA),
            environments = lapply(bench_envs, function(e) list(
              cran = e$cran,
              packages = lapply(setNames(nm = c("gloss", "ggplot2", "ComplexHeatmap", "patchwork", "ggtree", "aplot", "svglite", "grid")),
                                function(p) tryCatch(as.character(utils::packageVersion(p, lib.loc = c(bench_libpaths(e), "."))), error = function(err) NA)))))
jsonlite::write_json(env, sub("\\.csv$", ".json", out_file), auto_unbox = TRUE, pretty = TRUE)
