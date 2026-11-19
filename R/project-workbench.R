# Projection plugin: standalone single-file HTML gloss Workbench.
# Embeds the exact same `<script type="application/json" id="gloss-bundle">`
# payload as `gl_write()`, so every exported workbench HTML remains 100%
# lossless and readable via `gl_read()`.

register_projection_workbench <- function() {
  gl_register(
    "projection", name = "workbench", version = "0.1.0", package = "gloss",
    description = "standalone interactive HTML workbench with embedded gloss bundle",
    formats = "workbench", write = write_workbench
  )
}

workbench_template_path <- function(mode = c("full", "lite"), template = NULL) {
  mode <- match.arg(mode)
  if (!is.null(template)) {
    if (!file.exists(template)) {
      cli::cli_abort("Workbench template {.path {template}} does not exist.")
    }
    return(template)
  }

  local_rel <- if (identical(mode, "lite")) {
    file.path("workbench", "dist-lite", "index.html")
  } else {
    file.path("workbench", "dist-singlefile", "index.html")
  }
  if (file.exists(local_rel)) return(local_rel)

  gz_name <- sprintf("workbench-%s.html.gz", mode)
  installed_gz <- system.file("workbench", gz_name, package = "gloss")
  if (nzchar(installed_gz) && file.exists(installed_gz)) return(installed_gz)
  local_gz <- file.path("inst", "workbench", gz_name)
  if (file.exists(local_gz)) return(local_gz)

  cli::cli_abort(c(
    "No compiled gloss Workbench shell found for mode {.val {mode}}.",
    i = if (identical(mode, "lite")) {
      "Build it with `pnpm --dir workbench run build:lite` or use `mode = \"full\"`."
    } else {
      "Build it with `pnpm --dir workbench run build:singlefile`."
    }
  ))
}

read_workbench_template <- function(path) {
  if (grepl("\\.gz$", path, ignore.case = TRUE)) {
    con <- gzfile(path, open = "rb")
    on.exit(close(con), add = TRUE)
    chunks <- list()
    repeat {
      buf <- readBin(con, what = "raw", n = 262144L)
      if (!length(buf)) break
      chunks[[length(chunks) + 1L]] <- buf
    }
    txt <- rawToChar(unlist(chunks, use.names = FALSE))
    Encoding(txt) <- "UTF-8"
    return(txt)
  }
  raw <- readBin(path, what = "raw", n = file.size(path))
  txt <- rawToChar(raw)
  Encoding(txt) <- "UTF-8"
  txt
}

workbench_config_script <- function(title, theme, initial_stage, view = "reader") {
  cfg <- list(title = title, theme = theme, view = view)
  if (!is.null(initial_stage)) cfg$initialStage <- initial_stage
  json <- json_write(cfg, pretty = FALSE)
  # Escape closing script sequences so user/model strings cannot break out.
  json <- gsub("</", "<\\/", json, fixed = TRUE)
  paste0("<script>window.__GLOSS_WORKBENCH_CONFIG__=", json, ";</script>")
}

replace_literal_once <- function(haystack, needle, replacement) {
  pos <- regexpr(needle, haystack, fixed = TRUE)
  if (pos < 0L) {
    cli::cli_abort("Workbench template is missing required injection marker {.val {needle}}.")
  }
  prefix <- substr(haystack, 1L, pos - 1L)
  suffix <- substring(haystack, pos + nchar(needle), nchar(haystack))
  paste0(prefix, replacement, suffix)
}

write_workbench <- function(fig, path, embed = "all", mode = "full",
                            view = "reader", theme = "paper", initial_stage = NULL,
                            title = NULL, template = NULL, ...) {
  embed <- match.arg(embed, embed_modes)
  mode <- match.arg(mode, c("full", "lite"))
  view <- match.arg(view, c("reader", "inspector"))
  theme <- match.arg(theme, c("paper", "obsidian"))
  if (!is.null(initial_stage)) {
    initial_stage <- match.arg(
      initial_stage,
      c("raw", "structure", "binding", "analytical", "contextual",
        "relation", "claim", "narrative", "behavior")
    )
  }

  tpl_path <- workbench_template_path(mode = mode, template = template)
  html <- read_workbench_template(tpl_path)
  title <- title %||% fig$context$doc$value$caption %||% basename(path)

  # Safely replace the <title> text and inject the bundle + workbench config.
  html <- sub(
    "<title>[^<]*</title>",
    sprintf("<title>%s - gloss Workbench</title>", html_escape(title)),
    html
  )
  html <- replace_literal_once(
    html,
    "<!-- __GLOSS_BUNDLE_SLOT__ -->",
    embed_script(fig, embed)
  )
  html <- replace_literal_once(
    html,
    "<!-- __GLOSS_WORKBENCH_CONFIG_SLOT__ -->",
    workbench_config_script(title = title, theme = theme, initial_stage = initial_stage, view = view)
  )

  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeBin(as_bytes(html), path)
  invisible(path)
}

#' Write a standalone browser Workbench for a gloss figure
#'
#' Writes a self-contained HTML Workbench that opens directly in any modern
#' browser without an R session or external client. The Workbench embeds the
#' exact same `gloss-bundle` payload written by [gl_write()], so the resulting
#' HTML file can also be restored losslessly with [gl_read()].
#'
#' @param fig A `gloss_figure`.
#' @param path Output `.html` file path. Defaults to a temporary `.html` file.
#' @param embed Which data to embed in the bundle (`"all"`, `"default"`,
#'   `"summary"`, or `"none"`). Defaults to `"all"` so the AG Grid data tables
#'   and raw entity lookups have full fidelity.
#' @param mode `"full"` (includes the Rive canvas state-machine runtime) or
#'   `"lite"` (smaller single file using the native SVG fallback).
#' @param view Initial presentation mode: `"reader"` (calm Scientific Reader
#'   designed for statisticians, biologists and domain reviewers) or
#'   `"inspector"` (full engineering audit view with 9-stage rail, code/JSONL,
#'   and SVG/Grob tree). Users can switch between both in the browser.
#' @param theme Initial visual theme: `"paper"` (light) or `"obsidian"` (dark).
#' @param initial_stage Optional initial semantic stage (`"raw"`, `"structure"`,
#'   `"binding"`, `"analytical"`, `"contextual"`, `"relation"`, `"claim"`,
#'   `"narrative"`, or `"behavior"`). When `NULL`, the workbench selects the
#'   richest populated stage automatically.
#' @param title Optional page title.
#' @param template Optional custom prebuilt workbench HTML shell path.
#' @param overwrite Replace an existing file.
#' @param open Open the generated file in the default browser.
#' @return `path`, invisibly.
#' @export
gl_workbench <- function(fig,
                         path = tempfile("gloss-workbench-", fileext = ".html"),
                         embed = c("all", "default", "summary", "none"),
                         mode = c("full", "lite"),
                         view = c("reader", "inspector"),
                         theme = c("paper", "obsidian"),
                         initial_stage = NULL,
                         title = NULL,
                         template = NULL,
                         overwrite = TRUE,
                         open = FALSE) {
  check_figure(fig)
  embed <- match.arg(embed)
  mode <- match.arg(mode)
  view <- match.arg(view)
  theme <- match.arg(theme)
  if (file.exists(path) && !overwrite) {
    cli::cli_abort("{.path {path}} exists; use {.code overwrite = TRUE}.")
  }
  write_workbench(
    fig = fig, path = path, embed = embed, mode = mode, view = view,
    theme = theme, initial_stage = initial_stage, title = title,
    template = template
  )
  if (isTRUE(open) && interactive()) utils::browseURL(path)
  invisible(path)
}
