#!/usr/bin/env Rscript

# M6 material parity gate. Runs the existing material writer in the pinned
# container under a separate cache namespace, then compares source and
# prepared-scene hashes with the host-generated M5 materials.

args <- commandArgs(trailingOnly = TRUE)
set_name <- if (length(args)) args[1L] else "dev"
if (!set_name %in% c("dev", "heldout")) stop("usage: Rscript bench/semantic/m6_env.R dev|heldout")

cache_root <- path.expand(Sys.getenv("GLOSS_BENCH_CACHE", "~/.cache/gloss-bench"))
out_dir <- file.path("bench", "runs", "m6-environment")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

image_manifest <- file.path("bench", "docker", "image-manifest.json")
if (!file.exists(image_manifest)) stop("missing image manifest: ", image_manifest)
manifest <- jsonlite::read_json(image_manifest, simplifyVector = TRUE)
have_svg <- requireNamespace("svglite", quietly = TRUE)
svg_version <- if (have_svg) as.character(utils::packageVersion("svglite")) else NA_character_

selected <- list(
  dev = c("gallery-005", "gallery-029", "exts-030", "bioc-016", "patchwork-006", "tree-062"),
  heldout = c("gallery-016", "gallery-033", "gallery-060", "patchwork-014", "tree-001", "gallery-064")
)[[set_name]]

run_log <- tempfile(fileext = ".log")
status <- system2(
  "Rscript",
  c("bench/agent/m5-material.R", set_name, selected),
  stdout = run_log,
  stderr = run_log,
  env = "GLOSS_MATERIAL_NAMESPACE=m6-container"
)
if (status != 0L) {
  cat(readLines(run_log, warn = FALSE), sep = "\n")
  stop("material writer failed with status ", status)
}

historical_root <- file.path(cache_root, "agent", "m5", set_name)
container_root <- file.path(cache_root, "agent", "m6-container", set_name)
`%||%` <- function(a, b) if (is.null(a) || !length(a)) b else a
digest_meta <- function(path) {
  if (!file.exists(path)) return(NULL)
  x <- jsonlite::read_json(path, simplifyVector = FALSE)
  list(
    source_scene_sha256 = x$visual$source_scene_sha256 %||% x$source_scene_sha256 %||% NA_character_,
    prepared_view_sha256 = x$visual$prepared_view_sha256 %||% x$prepared_view_sha256 %||% NA_character_,
    contains_binding_answers = isTRUE(x$contains_binding_answers) || isTRUE(x$visual$contains_binding_answers),
    format = x$format %||% NA_character_
  )
}

rows <- lapply(selected, function(id) {
  old <- digest_meta(file.path(historical_root, id, "m5-metadata.json"))
  c <- digest_meta(file.path(container_root, id, "m5-metadata.json"))
  status <- if (is.null(old)) "historical_missing" else if (is.null(c)) "container_missing" else if (isTRUE(c$contains_binding_answers)) {
    "answer_leak"
  } else if (!identical(old$source_scene_sha256, c$source_scene_sha256)) {
    "source_changed_from_m5"
  } else "same_source_scene"
  data.frame(
    set = set_name, id = id, status = status,
    historical_source_scene_sha256 = old$source_scene_sha256 %||% NA_character_,
    container_source_scene_sha256 = c$source_scene_sha256 %||% NA_character_,
    historical_prepared_view_sha256 = old$prepared_view_sha256 %||% NA_character_,
    container_prepared_view_sha256 = c$prepared_view_sha256 %||% NA_character_,
    container_contains_binding_answers = c$contains_binding_answers %||% NA,
    stringsAsFactors = FALSE
  )
})
rows <- do.call(rbind, rows)
stamp <- format(Sys.time(), "%Y-%m-%d-%H%M", tz = "UTC")
csv <- file.path(out_dir, paste0(stamp, "-", set_name, ".csv"))
utils::write.csv(rows, csv, row.names = FALSE, na = "")
summary <- list(
  set = set_name, selected = length(selected),
  same_source_scene = sum(rows$status == "same_source_scene"),
  source_changed_from_m5 = sum(rows$status == "source_changed_from_m5"),
  prepared_answer_leaks = sum(rows$container_contains_binding_answers %in% TRUE),
  statuses = as.list(table(rows$status)),
  image = manifest$image_id %||% Sys.getenv("GLOSS_BENCH_IMAGE_DIGEST", NA_character_),
  svglite = svg_version,
  source = manifest$base %||% NA_character_,
  run_log = readLines(run_log, warn = FALSE),
  csv = csv
)
json <- sub("[.]csv$", "-summary.json", csv)
jsonlite::write_json(summary, json, auto_unbox = TRUE, pretty = TRUE)
print(summary)
if (any(!rows$status %in% c("same_source_scene", "source_changed_from_m5")) ||
    any(rows$container_contains_binding_answers %in% TRUE))
  quit(status = 2L)
