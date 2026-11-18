#!/usr/bin/env Rscript

# Add the package-environment field to material-v1 written before the field
# was introduced.  This changes public metadata only, never the scene or the
# hidden oracle.

source("bench/R/harvest.R")
source("bench/agent/binding-material.R")
source("bench/agent/binding-checker.R")

args <- commandArgs(trailingOnly = TRUE)
if (length(args) && !identical(args[1L], "dev")) stop("only the development set can be migrated")
namespace <- Sys.getenv("GLOSS_BINDING_NAMESPACE", "binding-v1")
cache_root <- path.expand(Sys.getenv("GLOSS_BENCH_CACHE", "~/.cache/gloss-bench"))
root <- file.path(cache_root, "agent", namespace, "dev")
split <- read_csv(file.path(bench_root, "split.csv"))
todo <- split[split$set == "dev", , drop = FALSE]
rows <- list()
for (k in seq_len(nrow(todo))) {
  id <- todo$id[k]
  dir <- file.path(root, id)
  if (!file.exists(file.path(dir, "public", "facts.json"))) next
  facts <- jsonlite::read_json(file.path(dir, "public", "facts.json"), simplifyVector = FALSE)
  expected <- env_for_stratum(todo$stratum[k])$name
  old <- facts$environment %||% NA_character_
  if (identical(as.character(old), expected)) {
    rows[[length(rows) + 1L]] <- data.frame(id = id, status = "already_present", environment = expected, stringsAsFactors = FALSE)
    next
  }
  facts$environment <- expected
  jsonlite::write_json(facts, file.path(dir, "public", "facts.json"), auto_unbox = TRUE, pretty = TRUE,
                       null = "null", na = "null", dataframe = "rows")
  manifest_path <- file.path(dir, "public", "manifest.json")
  if (file.exists(manifest_path)) {
    manifest <- jsonlite::read_json(manifest_path, simplifyVector = FALSE)
    file.rename(manifest_path, paste0(manifest_path, ".old"))
    manifest$environment <- expected
    manifest$public <- binding_files_hash(dir, TRUE)
    jsonlite::write_json(manifest, manifest_path, auto_unbox = TRUE, pretty = TRUE, null = "null")
    unlink(paste0(manifest_path, ".old"))
  }
  rows[[length(rows) + 1L]] <- data.frame(id = id, status = "migrated", environment = expected, stringsAsFactors = FALSE)
}
out <- if (length(rows)) do.call(rbind, rows) else data.frame(id = character(), status = character(), environment = character())
print(out)
cat(sprintf("material metadata migration: %d figures, %d changed\n", nrow(out), sum(out$status == "migrated")))
