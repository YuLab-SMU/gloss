# Bind the frozen figures of one set (M1 plan 2026-11-11-m1-roles-and-binding,
# Task 2): capture each figure as capture.R does, then run gloss's internal
# bind step on it, and archive one row per figure and one row per leaf.
# Runs third-party code, so run it in the container, with no network:
#   GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/bind.R dev
# The held-out set only produces reported numbers: running it needs the
# explicit argument "heldout", predictions committed before, and is archived
# like any other run.
# A set is v0's. A stratum added after v0 is run on its own, by its name
# after the set (bind.R dev tree), and its files carry the name.
#
# Output: runs/<stamp>-bind-<set>[-<stratum>].csv (figures), -leaves.csv (leaves), .json.

source("bench/R/harvest.R")
args <- commandArgs(trailingOnly = TRUE)
set <- if (length(args)) args[1] else "dev"
stratum <- if (length(args) > 1) args[2] else NULL
stopifnot(set %in% c("dev", "heldout"))

reachable <- tryCatch({
  con <- suppressWarnings(socketConnection("cloud.r-project.org", 80, blocking = TRUE, timeout = 5))
  close(con); TRUE
}, error = function(e) FALSE)
if (reachable) stop("the network is reachable; run with GLOSS_BENCH_OFFLINE=true bench/docker/run.sh")

split <- read_csv(file.path(bench_root, "split.csv"))
todo <- set_figures(split, set, stratum)
stamp <- format(Sys.time(), "%Y-%m-%d-%H%M", tz = "UTC")
out_file <- file.path(bench_root, "runs", sprintf("%s-bind-%s.csv", stamp, run_scope(set, stratum)))
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

statuses <- c("verified", "ambiguous", "partly_failed", "failed", "unbound", "count_mismatch", "outside", "not_paired")
timeout <- 900
rows <- list()
leaf_rows <- list()
for (k in seq_len(nrow(todo))) {
  id <- todo$id[k]
  dir <- file.path(bench_root, "figures", id)
  e <- check_eligibility(dir, todo$engine[k], timeout = timeout, capture = TRUE, bind = TRUE)
  cap <- e$run$capture
  status <- if (!is.null(e$run$error)) {
              if (identical(e$run$error$stage, "timeout")) "timeout" else paste("rerun:", e$run$error$stage)
            }
            else if (is.null(cap)) "no figure recovered"
            else if (!identical(e$run$recovered$engine, todo$engine[k])) "rerun: engine changed"
            else if (!identical(cap$status, "captured")) "not captured"
            else if (!is.null(cap$bind_error)) "bind error"
            else "bound"
  lv <- cap$bind_leaves
  count <- function(col, st) if (is.null(lv)) NA_integer_ else sum(lv[[col]][lv$status %in% st])
  by_status <- if (is.null(lv)) setNames(rep(NA_integer_, length(statuses)), statuses)
               else vapply(statuses, function(st) sum(lv$status == st), 1L)
  row <- data.frame(
    id = id, stratum = todo$stratum[k], engine = todo$engine[k], status = status,
    message = substr(cap$bind_error %||% cap$message %||% e$run$error$message %||% "", 1, 300),
    gloss_verdict = cap$gloss_verdict %||% NA, leaves = if (is.null(lv)) NA else nrow(lv),
    elements = if (is.null(lv)) NA else sum(lv$n_elements, na.rm = TRUE),
    el_verified = count("verified", statuses), el_ambiguous = count("ambiguous", statuses),
    el_failed = count("failed", statuses),
    el_unbound = count("n_elements", "unbound"), el_count_mismatch = count("n_elements", "count_mismatch"),
    el_outside = count("n_elements", "outside"), el_not_paired = count("n_elements", "not_paired"),
    stringsAsFactors = FALSE)
  for (st in statuses) row[[paste0("leaves_", st)]] <- by_status[[st]]
  row$seconds <- cap$seconds %||% NA
  row$bind_seconds <- cap$bind_seconds %||% NA
  rows[[k]] <- row
  if (!is.null(lv)) {
    lv$id <- id
    lv$stratum <- todo$stratum[k]
    lv$engine <- todo$engine[k]
    leaf_rows[[length(leaf_rows) + 1L]] <- lv[, c("id", "stratum", "engine", setdiff(names(lv), c("id", "stratum", "engine")))]
  }
  write_csv(do.call(rbind, rows), out_file)
  if (length(leaf_rows)) write_csv(do.call(rbind, leaf_rows), leaf_file)
  cat(sprintf("[%d/%d] %s %s: %s | verified %s ambiguous %s failed %s %s\n", k, nrow(todo), id, todo$engine[k], status,
              row$el_verified, row$el_ambiguous, row$el_failed, substr(row$message, 1, 60)))
}
env <- list(set = set, stratum = stratum %||% "v0", figures = nrow(todo), started = stamp, commit = git_head(), timeout = timeout,
            tolerance_pt = 0.5, R = R.version.string,
            image = Sys.getenv("GLOSS_BENCH_IMAGE_DIGEST", NA),
            environments = lapply(bench_envs, function(e) list(
              cran = e$cran,
              packages = lapply(setNames(nm = c("gloss", "ggplot2", "ComplexHeatmap", "patchwork", "ggtree", "aplot", "svglite", "grid")),
                                function(p) tryCatch(as.character(utils::packageVersion(p, lib.loc = c(bench_libpaths(e), "."))), error = function(err) NA)))))
jsonlite::write_json(env, sub("\\.csv$", ".json", out_file), auto_unbox = TRUE, pretty = TRUE)
