#!/usr/bin/env Rscript

# M4 Task 6. A development-only semantic pilot for the checked claim stage.
# It exercises the scripted path, then compares text-only and prepared-visual
# context on six figures with two gateway models and two repeats.

suppressMessages(pkgload::load_all(".", quiet = TRUE, export_all = FALSE, helpers = FALSE))
options(aisdk.skip_internet_check = TRUE)

models <- c("westlakehpc/glm-5.3-flash", "auto/gemini-4-argon")
figures <- c("gallery-005", "gallery-002", "gallery-029", "exts-027", "bioc-016", "tree-062")
conditions <- c("text_only", "prepared_visual")
repeats <- 2L
max_steps <- 8L
gateway <- "http://127.0.0.1:3425/v1"
cache_root <- path.expand(Sys.getenv("GLOSS_BENCH_CACHE", "~/.cache/gloss-bench"))
material_root <- file.path(cache_root, "agent", "pilot")
out_dir <- file.path("bench", "runs", "2026-11-17-m4-pilot")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

json_line <- function(x) as.character(jsonlite::toJSON(x, auto_unbox = TRUE, null = "null", na = "null", digits = NA))
model_label <- function(x) gsub("[^A-Za-z0-9.-]", "-", x)

load_figure <- function(id) {
  path <- file.path(material_root, id, "figure.html")
  if (!file.exists(path)) stop("missing pilot material for ", id, ": ", path)
  gloss::gl_read(path)
}

escape_xml <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  gsub('"', "&quot;", x, fixed = TRUE)
}

prepared_view <- function(fig, id) {
  dir <- file.path(out_dir, "visual", id)
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  scene <- fig$substrate$scene
  el <- gloss::gl_elements(fig)
  panels <- gloss::gl_panels(fig)
  keep <- el[!is.na(el$panel), , drop = FALSE]
  keep <- keep[order(keep$panel, keep$y0, keep$x0, keep$id), , drop = FALSE]
  keep <- utils::head(keep, 12L)
  w <- fig$meta$width * 72
  h <- fig$meta$height * 72
  panel_xml <- if (nrow(panels)) paste(vapply(seq_len(nrow(panels)), function(i) {
    p <- panels[i, ]
    paste0('<rect x="', p$x0, '" y="', p$y0, '" width="', p$x1 - p$x0,
           '" height="', p$y1 - p$y0, '" fill="none" stroke="#2b6cb0" stroke-width="1.1" stroke-dasharray="4 3" opacity=".7"/>')
  }, ""), collapse = "") else ""
  label_xml <- if (nrow(keep)) paste(vapply(seq_len(nrow(keep)), function(i) {
    e <- keep[i, ]
    cx <- (e$x0 + e$x1) / 2
    cy <- (e$y0 + e$y1) / 2
    label <- sprintf("E%02d", i)
    paste0('<rect x="', e$x0 - 2, '" y="', e$y0 - 2, '" width="', e$x1 - e$x0 + 4,
           '" height="', e$y1 - e$y0 + 4, '" fill="none" stroke="#c53030" stroke-width="1"/>',
           '<text x="', min(w - 20, max(2, cx + 4)), '" y="', min(h - 2, max(12, cy - 4)),
           '" fill="#c53030" font-family="monospace" font-size="8">', label, '</text>')
  }, ""), collapse = "") else ""
  overlay <- paste0('<g id="gloss-prepared-visual-view" aria-label="prepared visual evidence">',
                    '<rect x="0" y="0" width="', w, '" height="18" fill="#fffaf0" opacity=".96"/>',
                    '<text x="6" y="12" fill="#744210" font-family="sans-serif" font-size="9">Prepared view labels locations only. No data rows or bindings are shown.</text>',
                    panel_xml, label_xml, '</g>')
  prepared <- sub("</svg>", paste0(overlay, "</svg>"), scene, fixed = TRUE)
  source_path <- file.path(dir, "source.svg")
  prepared_path <- file.path(dir, "prepared.svg")
  png_path <- file.path(dir, "prepared.png")
  writeLines(scene, source_path, useBytes = TRUE)
  writeLines(prepared, prepared_path, useBytes = TRUE)
  if (requireNamespace("rsvg", quietly = TRUE)) rsvg::rsvg_png(charToRaw(prepared), png_path, width = 1008, height = 720)
  meta <- list(format = "gloss-prepared-visual-view", version = "0.1.0",
               source_scene_sha256 = digest::digest(scene, algo = "sha256", serialize = FALSE),
               prepared_view_sha256 = digest::digest(prepared, algo = "sha256", serialize = FALSE),
               contains_binding_answers = FALSE, labels = nrow(keep))
  jsonlite::write_json(meta, file.path(dir, "metadata.json"), auto_unbox = TRUE, pretty = TRUE)
  list(path = if (file.exists(png_path)) normalizePath(png_path) else normalizePath(prepared_path), metadata = meta)
}

scripted <- function() {
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  fig <- gloss::gloss(p, context = FALSE)
  element <- gloss::gl_elements(fig)$id[1]
  model <- R6::R6Class("m4_pilot_scripted", inherit = aisdk::LanguageModelV1,
    public = list(seen = 0L, initialize = function() super$initialize(provider = "scripted", model_id = "m4-pilot"),
      format_tool_result = function(tool_call_id, tool_name, result_content) list(role = "tool", tool_call_id = tool_call_id, name = tool_name, content = result_content),
      do_generate = function(params) {
        self$seen <- self$seen + 1L
        usage <- list(prompt_tokens = 3, completion_tokens = 2, total_tokens = 5)
        if (self$seen == 1L) return(list(text = "", finish_reason = "tool_calls", usage = usage,
          tool_calls = list(list(id = "m4-scripted-1", name = "propose", arguments = list(layer = "claim", anchor = element,
            body = list(text = "weight and fuel economy trend down together", check = list(kind = "trend", table = "built_layer1", args = list(response = "y", predictor = "x", expect = "negative"))))))))
        list(text = "done", tool_calls = NULL, finish_reason = "stop", usage = usage)
      }))$new()
  result <- gloss:::run_stage(fig, "claim", model = model, max_steps = 3L)
  rows <- gl_records(result$fig, "claim")
  out <- list(fixture = "mtcars", stage = "claim", committed = length(result$report$committed),
              status = if (nrow(rows)) rows$status[1] else NA_character_,
              factual = if (nrow(rows)) gloss:::record_is_factual(attr(rows, "records")[[1]]) else FALSE,
              substrate_unchanged = identical(fig$substrate$scene, result$fig$substrate$scene))
  jsonlite::write_json(out, file.path(out_dir, "scripted.json"), auto_unbox = TRUE, pretty = TRUE)
  out
}

run_real <- function() {
  key <- Sys.getenv("ANTHROPIC_AUTH_TOKEN", "local")
  provider <- aisdk::create_openai(api_key = key, base_url = gateway, api_format = "chat", name = "magpie",
                                   total_timeout_seconds = 180)
  views <- lapply(figures, function(id) {
    fig <- load_figure(id)
    list(id = id, fig = fig, visual = prepared_view(fig, id))
  })
  out_file <- file.path(out_dir, "runs.jsonl")
  writeLines(json_line(list(meta = TRUE, script = "bench/agent/m4-pilot.R", models = models,
                            figures = figures, conditions = conditions, repeats = repeats,
                            max_steps = max_steps, task = "claim-stage", visual_answers = FALSE)), out_file)
  rows <- list()
  for (model_id in models) for (view in views) for (condition in conditions) for (rep in seq_len(repeats)) {
    model <- provider$language_model(model_id)
    context <- list(condition = condition, figure = view$id,
                    task = "Propose one claim about the plotted data. Attach a closed check when the tools can decide it. Keep open-world meaning speculative.")
    if (condition == "prepared_visual") context$image <- view$visual$path
    t0 <- Sys.time()
    result <- tryCatch(gloss:::run_stage(view$fig, "claim", model = model, context = context,
                                          max_steps = max_steps), error = function(e) e)
    seconds <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
    if (inherits(result, "error")) {
      row <- list(model = model_id, figure = view$id, condition = condition, repeat_n = rep,
                  error = substr(conditionMessage(result), 1L, 300), seconds = round(seconds, 2), committed = 0L)
    } else {
      report <- result$report
      statuses <- vapply(report$committed %||% list(), function(c) c$record$status %||% NA_character_, "")
      row <- list(model = model_id, figure = view$id, condition = condition, repeat_n = rep,
                  error = NULL, seconds = round(seconds, 2), committed = length(report$committed %||% list()),
                  rejected = length(report$rejected %||% list()), statuses = statuses,
                  usage = report$usage %||% NULL, cache_hit = isTRUE(report$cache_hit),
                  visual_source_sha256 = if (condition == "prepared_visual") view$visual$metadata$source_scene_sha256 else NULL,
                  contains_binding_answers = if (condition == "prepared_visual") view$visual$metadata$contains_binding_answers else NULL)
    }
    rows[[length(rows) + 1L]] <- row
    cat(sprintf("%-30s %-14s %-16s r%d committed %d rejected %d %.1fs%s\n", model_id, view$id, condition, rep,
                row$committed %||% 0L, row$rejected %||% 0L, row$seconds,
                if (is.null(row$error)) "" else paste0(" error: ", row$error)))
    cat(json_line(row), "\n", file = out_file, append = TRUE)
  }
  jsonlite::write_json(rows, file.path(out_dir, "summary.json"), auto_unbox = TRUE, pretty = TRUE, null = "null")
  invisible(rows)
}

args <- commandArgs(trailingOnly = TRUE)
mode <- if (length(args)) args[1] else "scripted"
if (identical(mode, "scripted")) print(scripted()) else if (identical(mode, "run")) run_real() else stop("usage: m4-pilot.R scripted|run")
