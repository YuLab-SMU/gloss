#!/usr/bin/env Rscript

# Write the complete development material for the agent-first binding path.
# Run in the pinned image:
#   GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/agent/material-v1.R dev
#
# The script refuses held-out ids and never writes an oracle into the public
# directory.  The two directories are siblings under the bench cache so the
# checker can be given both while an agent sandbox receives only public/.

suppressMessages(pkgload::load_all(".", quiet = TRUE, export_all = FALSE, helpers = FALSE))
source("bench/R/harvest.R")
source("bench/agent/binding-material.R")

args <- commandArgs(trailingOnly = TRUE)
set_name <- if (length(args)) args[1L] else "dev"
if (!identical(set_name, "dev")) stop("material-v1 only writes the development set")

split <- read_csv(file.path(bench_root, "split.csv"))
ids <- if (length(args) > 1L) args[-1L] else split$id[split$set == "dev"]
todo <- split[match(ids, split$id), , drop = FALSE]
if (anyNA(todo$id)) stop("unknown figure id: ", paste(ids[is.na(todo$id)], collapse = ", "))
if (any(todo$set != "dev")) stop("held-out ids are refused by material-v1")

cache_root <- path.expand(Sys.getenv("GLOSS_BENCH_CACHE", "~/.cache/gloss-bench"))
namespace <- Sys.getenv("GLOSS_BINDING_NAMESPACE", "binding-v1")
if (!grepl("^[A-Za-z][A-Za-z0-9_-]*$", namespace)) stop("invalid GLOSS_BINDING_NAMESPACE")
out_root <- file.path(cache_root, "agent", namespace, "dev")
dir.create(out_root, recursive = TRUE, showWarnings = FALSE)
stamp <- format(Sys.time(), "%Y-%m-%d-%H%M%S", tz = "UTC")
run_file <- file.path("bench", "runs", paste0(stamp, "-binding-material-dev.csv"))
dir.create(dirname(run_file), recursive = TRUE, showWarnings = FALSE)

copy_source <- function(id, target) {
  source <- file.path(bench_root, "figures", id)
  file.copy(file.path(source, "code.R"), file.path(target, "code.R"), overwrite = TRUE)
  data <- file.path(source, "data")
  if (dir.exists(data)) file.copy(data, target, recursive = TRUE, overwrite = TRUE)
  meta <- jsonlite::read_json(file.path(source, "meta.json"), simplifyVector = FALSE)
  # The public metadata describes provenance and environment only.  It does
  # not contain bindings or checker output.
  meta[c("binding", "answers", "oracle", "geometry", "checker")] <- NULL
  jsonlite::write_json(meta, file.path(target, "source-meta.json"), auto_unbox = TRUE, pretty = TRUE, null = "null")
}

write_row <- function(id, row, status, message, started, work) {
  public <- file.path(work, "public")
  pub <- if (dir.exists(public)) binding_files_hash(work, TRUE) else list(files = character(), manifest = NA_character_)
  ora <- if (dir.exists(file.path(work, "oracle"))) binding_files_hash(work, FALSE) else list(files = character(), manifest = NA_character_)
  data.frame(
    id = id, set = "dev", stratum = row$stratum, engine = row$engine, status = status,
    message = substr(as.character(message %||% ""), 1L, 500L),
    seconds = round(as.numeric(difftime(Sys.time(), started, units = "secs")), 2),
    public_manifest = pub$manifest %||% NA_character_, oracle_manifest = ora$manifest %||% NA_character_,
    public_files = length(pub$files), oracle_files = length(ora$files),
    stringsAsFactors = FALSE
  )
}

rows <- vector("list", nrow(todo))
for (k in seq_len(nrow(todo))) {
  id <- todo$id[k]
  started <- Sys.time()
  work <- file.path(out_root, id)
  unlink(work, recursive = TRUE)
  dir.create(work, recursive = TRUE)
  export <- function(fig, svg, dir) binding_write_material(fig, svg, dir, figure_id = figure_id)
  export_helpers <- binding_export_helpers()
  export_helpers$figure_id <- id
  result <- tryCatch(check_eligibility(file.path(bench_root, "figures", id), todo$engine[k],
                                       timeout = 900, capture = TRUE, export = normalizePath(work),
                                       export_fun = export, export_helpers = export_helpers), error = function(e) e)
  if (inherits(result, "error")) {
    rows[[k]] <- write_row(id, todo[k, ], "operational_failure", conditionMessage(result), started, work)
    cat(sprintf("[%d/%d] %s operational_failure: %s\n", k, nrow(todo), id, conditionMessage(result)))
    next
  }
  run <- result$run
  cap <- run$capture
  status <- if (!is.null(run$error)) {
    if (identical(run$error$stage, "timeout")) "operational_failure" else paste0("replay_", run$error$stage)
  } else if (is.null(cap)) "operational_failure"
  else if (!identical(run$recovered$engine, todo$engine[k])) "replay_engine_changed"
  else if (!identical(cap$status, "captured")) "replay_not_captured"
  else if (!isTRUE(cap$export)) "material_not_written" else "written"
  message <- if (!is.null(run$error)) run$error$message else cap$message %||% ""
  if (identical(status, "written")) {
    copy_source(id, file.path(work, "public"))
    public_check <- binding_check_public_material(work)
    if (!isTRUE(public_check$ok)) {
      status <- "public_material_invalid"
      message <- public_check$reason
    } else {
      public_manifest <- list(format = "gloss-agent-binding-material", version = binding_material_version,
                              figure = id, set = "dev", public = public_check$manifest)
      jsonlite::write_json(public_manifest, file.path(work, "public", "manifest.json"), auto_unbox = TRUE, pretty = TRUE)
    }
  } else {
    # No partial material is allowed to look like a usable figure.
    unlink(work, recursive = TRUE)
    dir.create(work, recursive = TRUE)
  }
  rows[[k]] <- write_row(id, todo[k, ], status, message, started, work)
  write_csv(do.call(rbind, rows[seq_len(k)]), run_file)
  cat(sprintf("[%d/%d] %s %s in %.1fs\n", k, nrow(todo), id, status, rows[[k]]$seconds))
}

res <- do.call(rbind, rows)
write_csv(res, run_file)
summary <- list(format = "gloss-agent-binding-material-run", version = binding_material_version,
                run = basename(run_file), set = "dev", figures = nrow(res),
                written = sum(res$status == "written"), statuses = as.list(table(res$status)), ids = ids)
jsonlite::write_json(summary, sub("\\.csv$", "-summary.json", run_file), auto_unbox = TRUE, pretty = TRUE)
print(summary)
