#!/usr/bin/env Rscript

# M5 material writer. It writes a small, stratified semantic subset for the
# development set and the registered held-out subset. The held-out branch is
# enabled only after the M5 predictions have been committed.

suppressMessages(pkgload::load_all(".", quiet = TRUE, export_all = FALSE, helpers = FALSE))
source("bench/R/harvest.R")
source("bench/agent/material-writer.R")

`%||%` <- function(a, b) if (is.null(a) || !length(a)) b else a

args <- commandArgs(trailingOnly = TRUE)
set_name <- if (length(args)) args[1L] else "dev"
if (!set_name %in% c("dev", "heldout")) stop("usage: Rscript bench/agent/m5-material.R dev|heldout [id ...]")
host_mode <- length(args) > 1L && identical(args[2L], "host")

selected <- list(
  dev = c("gallery-005", "gallery-029", "exts-030", "bioc-016", "patchwork-006", "tree-062"),
  heldout = c("gallery-003", "exts-004", "bioc-012", "patchwork-004", "tree-001", "gallery-009")
)
id_args <- if (host_mode) args[-c(1L, 2L)] else args[-1L]
ids <- if (length(id_args)) id_args else selected[[set_name]]

if (set_name == "heldout" && !file.exists("bench/predictions.md")) {
  stop("held-out material requires the registered predictions")
}

split <- read_csv(file.path(bench_root, "split.csv"))
todo <- split[match(ids, split$id), , drop = FALSE]
if (anyNA(todo$id)) stop("not in bench/split.csv: ", paste(ids[is.na(todo$id)], collapse = ", "))
if (any(todo$set != set_name)) stop("requested ids are not all in the ", set_name, " set")

cache_root <- path.expand(Sys.getenv("GLOSS_BENCH_CACHE", "~/.cache/gloss-bench"))
out_root <- file.path(cache_root, "agent", "m5", set_name)
dir.create(out_root, recursive = TRUE, showWarnings = FALSE)

prepared_view <- function(fig, dir) {
  scene <- fig$substrate$scene
  el <- gloss::gl_elements(fig)
  panels <- gloss::gl_panels(fig)
  w <- fig$meta$width * 72
  h <- fig$meta$height * 72
  keep <- el[!is.na(el$panel), , drop = FALSE]
  keep <- keep[order(keep$panel, keep$y0, keep$x0, keep$id), , drop = FALSE]
  keep <- utils::head(keep, 12L)
  panel_xml <- if (nrow(panels)) paste(vapply(seq_len(nrow(panels)), function(i) {
    p <- panels[i, ]
    paste0('<rect x="', p$x0, '" y="', p$y0, '" width="', p$x1 - p$x0,
           '" height="', p$y1 - p$y0,
           '" fill="none" stroke="#2b6cb0" stroke-width="1.1" stroke-dasharray="4 3" opacity=".7"/>')
  }, ""), collapse = "") else ""
  label_xml <- if (nrow(keep)) paste(vapply(seq_len(nrow(keep)), function(i) {
    e <- keep[i, ]
    cx <- (e$x0 + e$x1) / 2
    cy <- (e$y0 + e$y1) / 2
    paste0('<rect x="', e$x0 - 2, '" y="', e$y0 - 2, '" width="', e$x1 - e$x0 + 4,
           '" height="', e$y1 - e$y0 + 4,
           '" fill="none" stroke="#c53030" stroke-width="1"/>',
           '<text x="', min(w - 20, max(2, cx + 4)), '" y="', min(h - 2, max(12, cy - 4)),
           '" fill="#c53030" font-family="monospace" font-size="8">E', sprintf("%02d", i), '</text>')
  }, ""), collapse = "") else ""
  overlay <- paste0(
    '<g id="gloss-prepared-visual-view" aria-label="prepared visual evidence">',
    '<rect x="0" y="0" width="', w, '" height="18" fill="#fffaf0" opacity=".96"/>',
    '<text x="6" y="12" fill="#744210" font-family="sans-serif" font-size="9">',
    'Prepared view labels locations only. No data rows or bindings are shown.</text>',
    panel_xml, label_xml, '</g>')
  prepared <- sub("</svg>", paste0(overlay, "</svg>"), scene, fixed = TRUE)
  source_path <- file.path(dir, "A", "figure.svg")
  prepared_path <- file.path(dir, "prepared.svg")
  writeLines(scene, source_path, useBytes = TRUE)
  writeLines(prepared, prepared_path, useBytes = TRUE)
  list(
    source_scene_sha256 = digest::digest(scene, algo = "sha256", serialize = FALSE),
    prepared_view_sha256 = digest::digest(prepared, algo = "sha256", serialize = FALSE),
    contains_binding_answers = FALSE,
    labels = nrow(keep)
  )
}

export_m5 <- function(fig, svg, dir) {
  dir.create(file.path(dir, "A", "tables"), recursive = TRUE, showWarnings = FALSE)
  gx <- suppressWarnings(gloss::gloss(fig))
  gloss::gl_write(gx, file.path(dir, "figure.html"))
  bound <- gloss::gl_bindings(gx)
  saveRDS(list(elements = bound, leaves = gloss::gl_bindings(gx, by = "leaf"),
               geometry = gloss::gl_elements(gx)), file.path(dir, "answers.rds"), version = 2)
  writeLines(svg, file.path(dir, "A", "figure.svg"), useBytes = TRUE)
  tabs <- list()
  for (nm in gloss::gl_tables(gx)$name) {
    d <- tryCatch(gloss::gl_table(gx, nm), error = function(e) NULL)
    if (!is.data.frame(d)) next
    tabs[[nm]] <- d
    flat <- d[vapply(d, function(col) is.atomic(col) && is.null(dim(col)), logical(1))]
    utils::write.csv(cbind(row = seq_len(nrow(d)), flat), file.path(dir, "A", "tables", paste0(nm, ".csv")), row.names = FALSE)
  }
  saveRDS(tabs, file.path(dir, "A", "tables.rds"), version = 2)
  out <- list(answers = sum(bound$status %in% "verified"), tables = length(tabs), tree_lines = NA_integer_)
  scene <- gx$substrate$scene
  prepared <- sub(
    "</svg>",
    paste0('<g id="gloss-prepared-visual-view" aria-label="prepared visual evidence">',
           '<rect x="0" y="0" width="', gx$meta$width * 72,
           '" height="18" fill="#fffaf0" opacity=".96"/>',
           '<text x="6" y="12" fill="#744210" font-family="sans-serif" font-size="9">',
           'Prepared view labels locations only. No data rows or bindings are shown.</text></g></svg>'),
    scene, fixed = TRUE)
  writeLines(prepared, file.path(dir, "prepared.svg"), useBytes = TRUE)
  visual <- list(source_scene_sha256 = digest::digest(scene, algo = "sha256", serialize = FALSE),
                 prepared_view_sha256 = digest::digest(prepared, algo = "sha256", serialize = FALSE),
                 contains_binding_answers = FALSE, labels = 0L)
  meta <- list(
    format = "gloss-m5-material",
    version = "0.1.0",
    contains_binding_answers = FALSE,
    visual = visual,
    elements = out$elements,
    leaves = out$leaves,
    tables = out$tables,
    tree_lines = out$tree_lines
  )
  jsonlite::write_json(meta, file.path(dir, "m5-metadata.json"), auto_unbox = TRUE, pretty = TRUE)
  c(out, list(contains_binding_answers = FALSE, source_scene_sha256 = visual$source_scene_sha256,
              prepared_view_sha256 = visual$prepared_view_sha256))
}

stamp <- format(Sys.time(), "%Y-%m-%d-%H%M", tz = "UTC")
gloss_snapshot()
out_file <- file.path(bench_root, "runs", paste0(stamp, "-m5-material-", set_name, ".csv"))
rows <- vector("list", nrow(todo))

for (k in seq_len(nrow(todo))) {
  id <- todo$id[k]
  fig_dir <- file.path(bench_root, "figures", id)
  work <- file.path(out_root, id)
  unlink(work, recursive = TRUE)
  dir.create(work, recursive = TRUE)
  e <- if (!host_mode) {
    check_eligibility(fig_dir, todo$engine[k], timeout = 900, capture = TRUE,
                      export = normalizePath(work), export_fun = export_m5)
  } else {
    meta <- jsonlite::read_json(file.path(fig_dir, "meta.json"))
    r <- run_script(frozen_script(fig_dir), prepare_run_dir(fig_dir), seed = meta$seed,
                    timeout = 900, offline = TRUE, recover = TRUE, capture = TRUE,
                    device = "svg", export = normalizePath(work), export_fun = export_m5)
    list(ok = is.null(r$error) && identical(r$recovered$engine, todo$engine[k]), run = r)
  }
  cap <- e$run$capture
  status <- if (!is.null(e$run$error)) {
    if (identical(e$run$error$stage, "timeout")) "timeout" else paste("rerun:", e$run$error$stage)
  } else if (is.null(cap)) "no figure recovered"
  else if (!identical(e$run$recovered$engine, todo$engine[k])) "rerun: engine changed"
  else if (!identical(cap$status, "captured")) "not captured"
  else if (!isTRUE(cap$export)) "material not written" else "written"
  r <- cap$export_result %||% list()
  files <- if (dir.exists(work)) sort(list.files(work, recursive = TRUE)) else character()
  rows[[k]] <- data.frame(
    id = id, set = set_name, stratum = todo$stratum[k], engine = todo$engine[k], status = status,
    message = substr(if (is.character(cap$export)) cap$export else cap$message %||% e$run$error$message %||% "", 1, 300),
    elements = cap$elements %||% NA, leaves = cap$leaves %||% NA, panels = cap$panels %||% NA,
    tables = cap$export_tables %||% r$tables %||% NA, files = length(files),
    bytes = if (length(files)) sum(file.size(file.path(work, files))) else 0,
    contains_binding_answers = r$contains_binding_answers %||% NA,
    source_scene_sha256 = r$source_scene_sha256 %||% NA,
    prepared_view_sha256 = r$prepared_view_sha256 %||% NA,
    stringsAsFactors = FALSE
  )
  write_csv(do.call(rbind, rows[seq_len(k)]), out_file)
  cat(sprintf("[%d/%d] %s %s: %s | %s elements, %s tables\n", k, nrow(todo), id,
              todo$engine[k], status, rows[[k]]$elements, rows[[k]]$tables))
}

res <- do.call(rbind, rows)
summary <- list(
  set = set_name, figures = nrow(res), written = sum(res$status == "written"),
  contains_binding_answers = sum(res$contains_binding_answers %in% TRUE),
  statuses = as.list(table(res$status)), started = stamp, gloss_source_digest = gloss_source$digest,
  ids = ids
)
jsonlite::write_json(summary, sub("\\.csv$", "-summary.json", out_file), auto_unbox = TRUE, pretty = TRUE)
print(summary)
