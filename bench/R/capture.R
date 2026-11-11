# Capture the frozen figures of one set with gloss() (bench v0, Task 6).
# Runs third-party code, so run it in the container, with no network, as the
# no-network pass that made the figures eligible:
#   GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/capture.R dev
# The held-out set only produces reported numbers: running it needs the
# explicit argument "heldout" and is archived like any other run.
# A set is v0's. A stratum added after v0 is run on its own, by its name
# after the set, and writes <stamp>-capture-<set>-<stratum>.csv:
#   GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/capture.R dev tree

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
out_file <- file.path(bench_root, "runs", sprintf("%s-capture-%s.csv", stamp, run_scope(set, stratum)))

refusal <- function(msg) {
  if (grepl("uses a mask", msg)) return("refused: mask")
  if (grepl("No engine plugin handles", msg)) return("refused: no engine")
  if (grepl("does not support graphics groups", msg)) return("refused: device without groups")
  if (grepl("integrity check failed", msg)) return("refused: integrity check")
  if (grepl("not a built ggplot", msg)) return("refused: not a static ggplot")
  if (grepl("custom print method", msg)) return("refused: custom print method")  # engine route only
  if (grepl("drew nothing", msg)) return("refused: empty page")
  if (grepl("mixes base graphics and grid", msg)) return("refused: mixed page")
  if (grepl("cannot capture", msg) && grepl("base graphics page", msg)) return("refused: base page")
  # not a refusal: gloss's self-check found that capture changed the figure
  if (grepl("Capture changed the figure", msg)) return("aborted: capture changed the figure")
  NULL  # not a refusal: the caller falls back to "error" (NA here labelled 4 errors NA, run 2026-11-10-1131)
}

# The repository commit the run used (no git in the container: read .git).
git_head <- function() {
  h <- tryCatch(readLines(".git/HEAD", warn = FALSE)[1], error = function(e) NA_character_)
  if (is.na(h) || !startsWith(h, "ref: ")) return(h)
  ref <- sub("^ref: ", "", h)
  if (file.exists(file.path(".git", ref))) return(readLines(file.path(".git", ref), warn = FALSE)[1])
  packed <- tryCatch(readLines(".git/packed-refs", warn = FALSE), error = function(e) character())
  hit <- grep(paste0(" ", ref, "$"), packed, value = TRUE)
  if (length(hit)) sub(" .*$", "", hit[1]) else NA_character_
}

# Every figure of the set reran within 300 s without capture (no-network
# pass); capture gets 900 s, and a timeout is a capture outcome of its own.
capture_timeout <- 900

rows <- list()
for (k in seq_len(nrow(todo))) {
  id <- todo$id[k]
  dir <- file.path(bench_root, "figures", id)
  e <- check_eligibility(dir, todo$engine[k], timeout = capture_timeout, capture = TRUE)
  cap <- e$run$capture
  status <- if (!is.null(e$run$error)) {
              if (identical(e$run$error$stage, "timeout")) "timeout" else paste("rerun:", e$run$error$stage)
            }
            else if (is.null(cap)) "no figure recovered"
            else if (!identical(e$run$recovered$engine, todo$engine[k])) "rerun: engine changed"
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
    unowned = cap$unowned %||% NA, unowned_bg = cap$unowned_bg %||% NA,
    unowned_other = cap$unowned_other %||% NA,
    faithful = cap$faithful %||% NA, prims_scene = cap$prims_scene %||% NA, prims_ref = cap$prims_ref %||% NA,
    prims_differ = cap$prims_differ %||% NA, verdict = cap$verdict %||% NA,
    exception = cap$exception %||% NA, dense_leaves = cap$dense_leaves %||% NA,
    mismatch_leaves = cap$mismatch_leaves %||% NA,
    diff_scene = substr(cap$diff_scene %||% "", 1, 240), diff_ref = substr(cap$diff_ref %||% "", 1, 240),
    # page route (page-capture plan Task 4): the bench's own proof of
    # determinism, the page the code left against the object alone, and
    # gloss's own account of the page
    deterministic = cap$deterministic %||% NA, self_differ = cap$self_differ %||% NA,
    code_faithful = cap$code_faithful %||% NA, code_differ = cap$code_differ %||% NA,
    gloss_verdict = cap$gloss_verdict %||% NA, gloss_differ = cap$gloss_differ %||% NA,
    page_kind = cap$page_kind %||% NA, drawn_by = cap$drawn_by %||% NA, pages = cap$pages %||% NA,
    withheld = cap$withheld %||% NA, vector_recapture = cap$vector_recapture %||% NA,
    leaf_names = substr(cap$leaf_names %||% "", 1, 600),
    warnings = substr(cap$warnings %||% "", 1, 240),
    seconds = cap$seconds %||% NA,
    stringsAsFactors = FALSE)
  write_csv(do.call(rbind, rows), out_file)
  cat(sprintf("[%d/%d] %s %s: %s %s\n", k, nrow(todo), id, todo$engine[k], status, substr(rows[[k]]$message, 1, 70)))
}
env <- list(set = set, stratum = stratum %||% "v0", figures = nrow(todo), started = stamp, commit = git_head(), timeout = capture_timeout,
            R = R.version.string,
            image = Sys.getenv("GLOSS_BENCH_IMAGE_DIGEST", NA),
            environments = lapply(bench_envs, function(e) list(
              cran = e$cran,
              packages = lapply(setNames(nm = c("gloss", "ggplot2", "ComplexHeatmap", "patchwork", "ggtree", "aplot", "svglite", "gridGraphics", "grid")),
                                function(p) tryCatch(as.character(utils::packageVersion(p, lib.loc = c(bench_libpaths(e), "."))), error = function(err) NA)))))
jsonlite::write_json(env, sub("\\.csv$", ".json", out_file), auto_unbox = TRUE, pretty = TRUE)
