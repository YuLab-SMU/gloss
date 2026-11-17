#!/usr/bin/env Rscript

# M4 Task 1. Exercise the deterministic M3 operations and projections on the
# development figures. This script never accepts a held-out set.

source("bench/R/harvest.R")
args <- commandArgs(trailingOnly = TRUE)
only <- sub("^--only=", "", grep("^--only=", args, value = TRUE))
args <- args[!grepl("^--only=", args)]
set <- if (length(args)) args[1] else "dev"
stratum <- if (length(args) > 1) args[2] else NULL
if (!identical(set, "dev")) stop("m4_preflight.R runs on development figures only")

reachable <- tryCatch({
  con <- suppressWarnings(socketConnection("cloud.r-project.org", 80, blocking = TRUE, timeout = 5))
  close(con)
  TRUE
}, error = function(e) FALSE)
if (reachable) stop("the network is reachable; run with GLOSS_BENCH_OFFLINE=true bench/docker/run.sh")

preflight <- function(fig, svg, dir) {
  g <- suppressWarnings(gloss::gloss(fig))
  ids <- gloss::gl_elements(g)$id
  if (!length(ids)) stop("the captured figure has no elements")
  target <- ids[1L]
  before <- digest::digest(g$substrate$scene, algo = "sha256")
  projected <- gloss::gl_apply(g, list(
    list(op = "select", target = target),
    list(op = "style", target = target, style = "highlight"),
    list(op = "tooltip", target = target, text = "M4 preflight")
  ))
  after <- digest::digest(projected$substrate$scene, algo = "sha256")
  html <- file.path(dir, "fixture.html")
  gloss::gl_write(projected, html)
  back <- gloss::gl_read(html)
  aria <- gloss::gl_export(projected, "aria")
  text_description <- gloss::gl_export(projected, "text")
  annotation <- gloss::gl_export(projected, "annotation")
  jsonlite::parse_json(aria, simplifyVector = FALSE)
  jsonlite::parse_json(annotation, simplifyVector = FALSE)
  list(
    scene_unchanged = identical(before, after),
    operations = length(projected$operations$specs),
    operation_roundtrip = identical(back$operations, projected$operations),
    aria_parse = TRUE, annotation_parse = TRUE,
    text_bytes = nchar(text_description, type = "bytes"),
    html_bytes = file.size(html),
    runtime_embedded = grepl("GLOSS_RUNTIME_CONFIG", paste(readLines(html, warn = FALSE), collapse = "\n"), fixed = TRUE),
    withheld = {
      w <- projected$status$withheld
      if (is.data.frame(w) && nrow(w)) paste(w$what, collapse = " ") else ""
    }
  )
}

split <- read_csv(file.path(bench_root, "split.csv"))
todo <- set_figures(split, set, stratum)
if (length(only)) todo <- todo[todo$id %in% strsplit(only, ",", fixed = TRUE)[[1]], , drop = FALSE]
stamp <- format(Sys.time(), "%Y-%m-%d-%H%M", tz = "UTC")
gloss_snapshot()
out_dir <- file.path(bench_root, "runs", paste0(stamp, "-m4-preflight-", run_scope(set, stratum)))
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
out_file <- file.path(out_dir, "figures.csv")

rows <- list()
for (k in seq_len(nrow(todo))) {
  id <- todo$id[k]
  dir <- file.path(bench_root, "figures", id)
  work <- file.path(work_root, "m4-preflight", id)
  unlink(work, recursive = TRUE)
  dir.create(work, recursive = TRUE)
  e <- check_eligibility(dir, todo$engine[k], timeout = 900, capture = TRUE,
                         export = normalizePath(work), export_fun = preflight)
  cap <- e$run$capture
  status <- if (!is.null(e$run$error)) {
    if (identical(e$run$error$stage, "timeout")) "timeout" else paste("rerun:", e$run$error$stage)
  } else if (is.null(cap)) "no figure recovered" else if (!identical(e$run$recovered$engine, todo$engine[k])) "rerun: engine changed"
  else if (!identical(cap$status, "captured")) "not captured" else if (!isTRUE(cap$export)) "preflight failed" else "captured"
  r <- cap$export_result %||% list()
  rows[[k]] <- data.frame(
    id = id, stratum = todo$stratum[k], engine = todo$engine[k], status = status,
    message = substr(if (is.character(cap$export)) cap$export else cap$message %||% e$run$error$message %||% "", 1, 300),
    scene_unchanged = r$scene_unchanged %||% NA, operations = r$operations %||% NA,
    operation_roundtrip = r$operation_roundtrip %||% NA, aria_parse = r$aria_parse %||% NA,
    annotation_parse = r$annotation_parse %||% NA, runtime_embedded = r$runtime_embedded %||% NA,
    html_bytes = r$html_bytes %||% NA, text_bytes = r$text_bytes %||% NA,
    withheld = r$withheld %||% "", stringsAsFactors = FALSE
  )
  write_csv(do.call(rbind, rows), out_file)
  cat(sprintf("[%d/%d] %s %s: %s\n", k, nrow(todo), id, todo$engine[k], status))
}

res <- do.call(rbind, rows)
summary <- list(
  set = set, stratum = stratum %||% "v0", figures = nrow(res), started = stamp,
  captured = sum(res$status == "captured"), scene_unchanged = sum(res$scene_unchanged %in% TRUE),
  operation_roundtrip = sum(res$operation_roundtrip %in% TRUE),
  aria_parse = sum(res$aria_parse %in% TRUE), annotation_parse = sum(res$annotation_parse %in% TRUE),
  runtime_embedded = sum(res$runtime_embedded %in% TRUE),
  statuses = as.list(table(res$status)), R = R.version.string,
  gloss_source_digest = gloss_source$digest,
  browser = list(chromium = Sys.which("chromium"), chromium_browser = Sys.which("chromium-browser"),
                 google_chrome = Sys.which("google-chrome"), node = Sys.which("node"))
)
jsonlite::write_json(summary, file.path(out_dir, "summary.json"), auto_unbox = TRUE, pretty = TRUE)
writeLines(c(
  sprintf("M4 preflight: %d figures, %d captured.", summary$figures, summary$captured),
  sprintf("Scene unchanged: %d; operation round trips: %d.", summary$scene_unchanged, summary$operation_roundtrip),
  sprintf("ARIA parsed: %d; annotation parsed: %d; runtime embedded: %d.",
          summary$aria_parse, summary$annotation_parse, summary$runtime_embedded),
  sprintf("Statuses: %s", paste(names(summary$statuses), unlist(summary$statuses), collapse = ", "))
), file.path(out_dir, "README.txt"))
print(summary)
