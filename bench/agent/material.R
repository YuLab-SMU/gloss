# The material of the pilot's figures (agent-path plan 2026-11-12, Task 4):
# for each figure, what each arm of the pilot works on.
# Runs third-party figure code, so run it in the container, with no network:
#   GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/agent/material.R pilot
#   GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/agent/material.R <name> <id> [<id> ...]
# With no ids, the sampled figures of bench/agent/pilot-figures.csv.
# Development figures only: this script refuses any other.
#
# Written under the bench cache, <cache>/agent/<name>/<id>/ (third-party code
# and data stay out of the repository's history beyond bench/figures):
#   figure.html     the bundle gloss writes, with the bindings made at capture;
#                   condition B and the enumeration read it with gl_read()
#   answers.rds     the bindings and the elements' geometry: the answers,
#                   which no model is shown
#   A/              condition A's material, the sandbox's working directory:
#     code.R, data/     the figure's frozen code and the data it reads
#     tables/<n>.csv    the tables gloss holds (the plot's raw data, each
#                       layer's built data), a column `row` first; columns
#                       that are lists are left out
#     tables.rds        the same tables whole, a named list
#     grob_tree.txt     the grob tree, as grid lists it
#     figure.svg        the figure drawn alone on svglite, 7 x 5 in
# and bench/runs/<stamp>-material-<name>.csv: one row per figure, with the
# md5 of every file an arm reads.

source("bench/R/harvest.R")
source("bench/agent/material-writer.R")
args <- commandArgs(trailingOnly = TRUE)
if (!length(args)) stop("usage: Rscript bench/agent/material.R <name> [<id> ...]")
name <- args[1]
ids <- args[-1]
if (!length(ids)) {
  pf <- read_csv(file.path(bench_root, "agent", "pilot-figures.csv"))
  ids <- pf$id[pf$sampled %in% TRUE]
}
reachable <- tryCatch({
  con <- suppressWarnings(socketConnection("cloud.r-project.org", 80, blocking = TRUE, timeout = 5))
  close(con); TRUE
}, error = function(e) FALSE)
if (reachable) stop("the network is reachable; run with GLOSS_BENCH_OFFLINE=true bench/docker/run.sh")

split <- read_csv(file.path(bench_root, "split.csv"))
todo <- split[match(ids, split$id), , drop = FALSE]
if (anyNA(todo$id)) stop("not in bench/split.csv: ", paste(ids[is.na(todo$id)], collapse = ", "))
if (any(todo$set != "dev")) stop("material.R makes the material of development figures only: ", paste(todo$id[todo$set != "dev"], collapse = ", "))

stamp <- format(Sys.time(), "%Y-%m-%d-%H%M", tz = "UTC")
gloss_snapshot()
out_root <- file.path(cache_root, "agent", name)
dir.create(out_root, recursive = TRUE, showWarnings = FALSE)
rows <- list()
for (k in seq_len(nrow(todo))) {
  id <- todo$id[k]
  fig_dir <- file.path(bench_root, "figures", id)
  out <- file.path(out_root, id)
  unlink(out, recursive = TRUE)
  dir.create(file.path(out, "A"), recursive = TRUE)
  e <- check_eligibility(fig_dir, todo$engine[k], timeout = 900, capture = TRUE, export = normalizePath(out))
  cap <- e$run$capture
  status <- if (!is.null(e$run$error)) paste("rerun:", e$run$error$stage)
            else if (is.null(cap)) "no figure recovered"
            else if (!identical(e$run$recovered$engine, todo$engine[k])) "rerun: engine changed"
            else if (!identical(cap$status, "captured")) "not captured"
            else if (!isTRUE(cap$export)) "material not written"
            else "written"
  if (identical(status, "written")) {
    file.copy(file.path(fig_dir, "code.R"), file.path(out, "A", "code.R"))
    if (dir.exists(file.path(fig_dir, "data"))) file.copy(file.path(fig_dir, "data"), file.path(out, "A"), recursive = TRUE)
  } else unlink(out, recursive = TRUE)
  files <- if (dir.exists(out)) sort(list.files(out, recursive = TRUE)) else character()
  sums <- if (length(files)) unname(tools::md5sum(file.path(out, files))) else character()
  rows[[k]] <- data.frame(
    id = id, stratum = todo$stratum[k], engine = todo$engine[k], status = status,
    message = substr(if (is.character(cap$export)) cap$export else cap$message %||% e$run$error$message %||% "", 1, 300),
    elements = cap$elements %||% NA, leaves = cap$leaves %||% NA, panels = cap$panels %||% NA,
    answers = cap$export_answers %||% NA, tables = cap$export_tables %||% NA,
    files = length(files), bytes = if (length(files)) sum(file.size(file.path(out, files))) else 0,
    md5 = paste(sprintf("%s=%s", files, sums), collapse = " "), stringsAsFactors = FALSE)
  cat(sprintf("[%d/%d] %s %s: %s | %s elements, %s with an answer, %s tables, %d files, %.0f KB\n", k, nrow(todo), id, todo$engine[k],
              status, rows[[k]]$elements, rows[[k]]$answers, rows[[k]]$tables, length(files), rows[[k]]$bytes / 1024))
}
res <- do.call(rbind, rows)
out_file <- file.path(bench_root, "runs", sprintf("%s-material-%s.csv", stamp, name))
write_csv(res, out_file)
cat(sprintf("written: %d of %d figures | %s | gloss source %s\n", sum(res$status == "written"), nrow(res), out_file,
            gloss_source$digest))
