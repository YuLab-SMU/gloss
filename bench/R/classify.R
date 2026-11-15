# Run deterministic role rules on the captured development or held-out set.
#
#   GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/classify.R dev
#
# The worker saves the derived role tables beside the captured substrate. This
# script archives one element table, one leaf table, one checks table and one
# summary row per figure; it does not read the label files while running.

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
scope <- run_scope(set, stratum)
prefix <- file.path(bench_root, "runs", sprintf("%s-classify-%s", stamp, scope))
gloss_snapshot()

summary_rows <- list()
element_rows <- list()
leaf_rows <- list()
check_rows <- list()

for (k in seq_len(nrow(todo))) {
  id <- todo$id[k]
  keep <- tempfile(pattern = paste0("gloss-role-", id, "-"), fileext = ".rds")
  e <- check_eligibility(file.path(bench_root, "figures", id), todo$engine[k], timeout = 900,
                         capture = TRUE, bind = FALSE, keep = keep)
  cap <- e$run$capture
  status <- if (!is.null(e$run$error)) {
    if (identical(e$run$error$stage, "timeout")) "timeout" else paste("error:", e$run$error$stage)
  } else if (is.null(cap)) "no capture" else cap$status %||% "error"
  roles <- if (file.exists(keep)) tryCatch(readRDS(keep)$roles, error = function(err) NULL) else NULL
  if (identical(status, "captured") && is.null(roles)) status <- "no roles"
  if (!is.null(roles)) {
    add_meta <- function(x) {
      if (!nrow(x)) return(x)
      x$id <- id; x$stratum <- todo$stratum[k]; x$engine <- todo$engine[k]
      x[c("id", "stratum", "engine", setdiff(names(x), c("id", "stratum", "engine")))]
    }
    element_rows[[length(element_rows) + 1L]] <- add_meta(roles$tables$elements)
    leaf_rows[[length(leaf_rows) + 1L]] <- add_meta(roles$tables$leaves)
    if (!is.null(roles$tables$checks)) check_rows[[length(check_rows) + 1L]] <- add_meta(roles$tables$checks)
  }
  summary_rows[[k]] <- data.frame(
    id = id, stratum = todo$stratum[k], engine = todo$engine[k], status = status,
    message = substr(cap$message %||% e$run$error$message %||% "", 1, 300),
    leaves = if (is.null(roles)) NA_integer_ else nrow(roles$tables$leaves),
    elements = if (is.null(roles)) NA_integer_ else nrow(roles$tables$elements),
    classified = if (is.null(roles)) NA_integer_ else sum(roles$tables$elements$status == "classified"),
    residue = if (is.null(roles)) NA_integer_ else sum(roles$tables$elements$status == "residue"),
    flagged = if (is.null(roles)) NA_integer_ else sum(roles$tables$elements$flagged %in% TRUE),
    seconds = cap$seconds %||% NA_real_, stringsAsFactors = FALSE
  )
  if (file.exists(keep)) unlink(keep)
  write_csv(do.call(rbind, summary_rows), paste0(prefix, ".csv"))
  if (length(element_rows)) write_csv(do.call(rbind, element_rows), paste0(prefix, "-elements.csv"))
  if (length(leaf_rows)) write_csv(do.call(rbind, leaf_rows), paste0(prefix, "-leaves.csv"))
  if (length(check_rows)) write_csv(do.call(rbind, check_rows), paste0(prefix, "-checks.csv"))
  cat(sprintf("[%d/%d] %s %s: %s\n", k, nrow(todo), id, todo$engine[k], status))
}

jsonlite::write_json(list(
  set = set, stratum = stratum %||% "v0", figures = nrow(todo), started = stamp,
  commit = git_head(), commit_at_end = git_head(), gloss_source_digest = gloss_source$digest,
  R = R.version.string, image = Sys.getenv("GLOSS_BENCH_IMAGE_DIGEST", NA)
), paste0(prefix, ".json"), auto_unbox = TRUE, pretty = TRUE)
