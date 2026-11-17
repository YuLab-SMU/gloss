#!/usr/bin/env Rscript

# M6 development sizing: raw material, checked gloss, SVG-only and prepared
# visual conditions. One model/repeat is intentional: this is the cost gate
# before any repeated or cross-model held-out run.

source("bench/R/runner.R")
.libPaths(unique(c(bench_libpaths(), .libPaths())))
suppressMessages(pkgload::load_all(".", quiet = TRUE, export_all = FALSE, helpers = FALSE))
if (!requireNamespace("ggplot2", quietly = TRUE)) stop("ggplot2 is required")
if (!requireNamespace("rsvg", quietly = TRUE)) stop("rsvg is required for the visual condition")

`%||%` <- function(a, b) if (is.null(a) || !length(a)) b else a
args <- commandArgs(trailingOnly = TRUE)
mode <- if (length(args)) args[1L] else "run"
if (!mode %in% c("materials", "run")) stop("usage: Rscript bench/agent/m6-pilot.R materials|run")

cache_root <- path.expand(Sys.getenv("GLOSS_BENCH_CACHE", "~/.cache/gloss-bench"))
namespace <- Sys.getenv("GLOSS_MATERIAL_NAMESPACE", "m6-container")
task_file <- Sys.getenv("GLOSS_M6_TASK_FILE", "bench/agent/m6-tasks-dev.csv")
material_root <- file.path(cache_root, "agent", namespace, "dev")
out_dir <- file.path("bench", "runs", "m6-model")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

tasks <- utils::read.csv(task_file, stringsAsFactors = FALSE)
if (!nrow(tasks)) stop("no tasks in ", task_file)

load_material <- function(id) {
  dir <- file.path(material_root, id)
  if (!file.exists(file.path(dir, "figure.html"))) stop("missing material for ", id)
  fig <- gloss::gl_read(file.path(dir, "figure.html"))
  meta <- jsonlite::read_json(file.path(dir, "m5-metadata.json"), simplifyVector = FALSE)
  list(id = id, dir = dir, fig = fig, meta = meta)
}

make_visual <- function(m) {
  png <- file.path(out_dir, "visual", paste0(m$id, ".png"))
  dir.create(dirname(png), recursive = TRUE, showWarnings = FALSE)
  prepared <- readChar(file.path(m$dir, "prepared.svg"), file.info(file.path(m$dir, "prepared.svg"))$size, useBytes = TRUE)
  rsvg::rsvg_png(charToRaw(prepared), png, width = 1008, height = 720)
  list(path = normalizePath(png), data_uri = paste0("data:image/png;base64,", base64enc::base64encode(png)))
}

json_line <- function(x) as.character(jsonlite::toJSON(x, auto_unbox = TRUE, null = "null", na = "null", digits = NA))
model_id <- Sys.getenv("GLOSS_M6_MODEL", "auto/glm-5.3-flash")
gateway <- Sys.getenv("GLOSS_M6_GATEWAY", "http://127.0.0.1:3425/v1")
request_timeout <- 180L
max_steps <- 4L

tool_spec <- function(name, description, properties, required) list(
  type = "function", `function` = list(
    name = name, description = description,
    parameters = list(type = "object", properties = properties, required = required)
  )
)

chat_request <- function(messages, tools) {
  payload <- jsonlite::toJSON(list(model = model_id, messages = messages, temperature = 0,
                                   tools = tools), auto_unbox = TRUE, null = "null", digits = NA)
  h <- curl::new_handle()
  curl::handle_setheaders(h, Authorization = paste("Bearer", Sys.getenv("ANTHROPIC_AUTH_TOKEN", "local")),
                          `Content-Type` = "application/json")
  curl::handle_setopt(h, copypostfields = payload, timeout = request_timeout)
  res <- tryCatch(curl::curl_fetch_memory(paste0(gateway, "/chat/completions"), handle = h), error = function(e) e)
  if (inherits(res, "error")) return(list(error = conditionMessage(res)))
  txt <- rawToChar(res$content); Encoding(txt) <- "UTF-8"
  parsed <- tryCatch(jsonlite::fromJSON(txt, simplifyVector = FALSE), error = function(e) NULL)
  if (res$status_code != 200L || is.null(parsed$choices[[1L]]$message)) {
    return(list(error = sprintf("HTTP %d: %s", res$status_code, substr(txt, 1L, 300L))))
  }
  list(message = parsed$choices[[1L]]$message, usage = parsed$usage %||% list())
}

run_loop <- function(system, user_content, tools, runner, visual_uri = NULL) {
  user <- if (is.null(visual_uri)) list(role = "user", content = user_content) else list(
    role = "user", content = list(
      list(type = "text", text = user_content),
      list(type = "image_url", image_url = list(url = visual_uri))
    )
  )
  messages <- list(list(role = "system", content = system), user)
  usage <- list(prompt_tokens = 0, completion_tokens = 0, total_tokens = 0)
  calls <- list(); finish <- NA_character_; error <- NULL; text <- NULL
  for (step in seq_len(max_steps)) {
    r <- chat_request(messages, tools)
    if (!is.null(r$error)) { error <- r$error; finish <- "request error"; break }
    for (nm in names(usage)) usage[[nm]] <- as.numeric(usage[[nm]] %||% 0) + as.numeric(r$usage[[nm]] %||% 0)
    msg <- r$message
    tc <- msg$tool_calls %||% list()
    if (!length(tc)) { text <- msg$content %||% ""; finish <- "stop"; break }
    assistant_calls <- lapply(tc, function(x) list(
      id = x$id, type = "function",
      `function` = list(name = x$`function`$name, arguments = x$`function`$arguments %||% "{}")
    ))
    messages[[length(messages) + 1L]] <- list(role = "assistant", content = msg$content %||% "", tool_calls = assistant_calls)
    for (x in tc) {
      fn <- x$`function`$name %||% ""
      raw <- x$`function`$arguments %||% "{}"
      parsed <- tryCatch(jsonlite::fromJSON(raw, simplifyVector = FALSE), error = function(e) list())
      result <- tryCatch(runner(fn, parsed), error = function(e) list(error = conditionMessage(e)))
      calls[[length(calls) + 1L]] <- list(name = fn, arguments = parsed, result = result)
      messages[[length(messages) + 1L]] <- list(role = "tool", tool_call_id = x$id,
                                                content = json_line(result))
    }
  }
  if (is.na(finish)) finish <- "step limit"
  list(text = text, finish = finish, error = error, usage = usage, calls = calls)
}

task_prompt <- function(task, condition) {
  paste(
    "Decide whether the following directional claim is supported by the captured R figure.",
    sprintf("Claim: `%s` in `%s` has a %s trend as `%s` increases.", task$response, task$table, task$claim_expect, task$predictor),
    sprintf("Use exact table and column names. The expected answer must be a single verdict: true or false."),
    switch(condition,
      A_raw = "Read the supplied raw table with read_table, compute the trend, then call submit.",
      B_check = "Call submit with the exact table and columns. The checked tool returns verified or failed.",
      D_svg = "Use read_svg to inspect the SVG only. The SVG has no tables; submit only what it supports.",
      V_prepared = "Inspect the prepared visual. It marks locations only and contains no data rows; submit only what it supports."
    )
  )
}

run_condition <- function(m, task, condition) {
  checked <- identical(condition, "B_check")
  state <- new.env(parent = emptyenv()); state$submission <- NULL
  tables <- sort(list.files(file.path(m$dir, "A", "tables"), pattern = "[.]csv$", full.names = TRUE))
  table_path <- file.path(m$dir, "A", "tables", paste0(task$table, ".csv"))
  props <- list(
    table = list(type = "string", description = "exact table name"),
    predictor = list(type = "string", description = "exact predictor column"),
    response = list(type = "string", description = "exact response column"),
    expect = list(type = "string", description = "positive or negative"),
    verdict = list(type = "string", description = "true or false")
  )
  submit_tool <- tool_spec("submit", "Submit the final directional verdict.", props,
                           c("table", "predictor", "response", "expect", "verdict"))
  read_tool <- tool_spec("read_table", "Read the requested raw table CSV.",
                         list(table = list(type = "string", description = "table name")), c("table"))
  svg_tool <- tool_spec("read_svg", "Read the captured SVG scene as text.", list(), character())
  tools <- switch(condition, A_raw = list(read_tool, submit_tool), D_svg = list(svg_tool, submit_tool),
                  V_prepared = list(submit_tool), B_check = list(submit_tool))
  runner <- function(name, a) {
    if (identical(name, "read_table")) {
      if (!identical(as.character(a$table %||% ""), task$table)) return(list(error = "unknown table"))
      txt <- paste(readLines(table_path, warn = FALSE), collapse = "\n")
      return(list(table = task$table, csv = substr(txt, 1L, 12000)))
    }
    if (identical(name, "read_svg")) {
      txt <- paste(readLines(file.path(m$dir, "A", "figure.svg"), warn = FALSE), collapse = "\n")
      return(list(svg = substr(txt, 1L, 50000), contains_binding_answers = FALSE))
    }
    if (!identical(name, "submit")) return(list(error = "unknown tool"))
    state$submission <- a
    if (!checked) return(list(recorded = TRUE, status = "unvalidated"))
    d <- gloss::gl_table(m$fig, task$table)
    check <- tryCatch(gloss::gl_check(d, "trend", list(response = a$response, predictor = a$predictor, expect = a$expect)),
                      error = function(e) list(status = "refused", reason = conditionMessage(e)))
    list(recorded = TRUE, status = check$status %||% "refused", reason = check$reason %||% NULL)
  }
  visual <- if (identical(condition, "V_prepared")) make_visual(m) else NULL
  system <- paste("You are a careful figure analyst. Use the available tools and submit exactly one final verdict.",
                  "Do not invent a table, row or binding. A checked status is evidence; an unsupported or refused claim is not factual.")
  t0 <- Sys.time()
  out <- run_loop(system, task_prompt(task, condition), tools, runner, if (is.null(visual)) NULL else visual$data_uri)
  seconds <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  submission <- state$submission %||% list()
  verdict <- tolower(as.character(submission$verdict %||% ""))
  last_result <- if (length(out$calls)) out$calls[[length(out$calls)]]$result %||% list() else list()
  status <- if (checked) as.character(last_result$status %||% "none") else "unvalidated"
  truth <- isTRUE(task$truth)
  correct <- if (checked) identical(status, if (truth) "verified" else "failed") else identical(verdict, if (truth) "true" else "false")
  list(model = model_id, condition = condition, figure = task$figure, task = task$task,
       truth = truth, correct = correct, covered = length(state$submission) > 0L,
       false_accept = !truth && (if (checked) identical(status, "verified") else identical(verdict, "true")),
       false_reject = truth && (if (checked) identical(status, "failed") else identical(verdict, "false")),
       verdict = if (nzchar(verdict)) verdict else NULL, status = status,
       seconds = round(seconds, 2), finish = out$finish, error = out$error %||% NULL,
       usage = out$usage, tool_calls = out$calls,
       source_scene_sha256 = m$meta$visual$source_scene_sha256 %||% NA_character_,
       prepared_view_sha256 = m$meta$visual$prepared_view_sha256 %||% NA_character_,
       contains_binding_answers = FALSE)
}

if (identical(mode, "materials")) {
  invisible(lapply(unique(tasks$figure), function(id) make_visual(load_material(id))))
  print(list(figures = length(unique(tasks$figure)), namespace = namespace, visual_dir = file.path(out_dir, "visual")))
  quit(status = 0L)
}

stamp <- format(Sys.time(), "%Y-%m-%d-%H%M", tz = "UTC")
archive <- file.path(out_dir, paste0(stamp, "-dev.jsonl"))
writeLines(json_line(list(meta = TRUE, script = "bench/agent/m6-pilot.R", model = model_id,
                          conditions = c("A_raw", "B_check", "D_svg", "V_prepared"),
                          tasks = tasks$task, namespace = namespace, max_steps = max_steps,
                          request_timeout = request_timeout, visual_answers = FALSE)), archive)
rows <- list()
materials <- lapply(unique(tasks$figure), load_material)
names(materials) <- vapply(materials, `[[`, "", "id")
for (i in seq_len(nrow(tasks))) {
  task <- tasks[i, , drop = FALSE]
  m <- materials[[task$figure]]
  for (condition in c("A_raw", "B_check", "D_svg", "V_prepared")) {
    row <- run_condition(m, task, condition)
    rows[[length(rows) + 1L]] <- row
    cat(json_line(row), "\n", file = archive, append = TRUE)
    cat(sprintf("%-12s %-24s correct=%s covered=%s %.1fs\n", condition, task$task, row$correct, row$covered, row$seconds))
  }
}
summary_rows <- do.call(rbind, lapply(split(rows, vapply(rows, `[[`, "", "condition")), function(x) data.frame(
  condition = x[[1]]$condition, runs = length(x), correct = mean(vapply(x, `[[`, logical(1), "correct")),
  coverage = mean(vapply(x, `[[`, logical(1), "covered")), false_accept = mean(vapply(x, `[[`, logical(1), "false_accept")),
  false_reject = mean(vapply(x, `[[`, logical(1), "false_reject")), median_seconds = stats::median(vapply(x, `[[`, numeric(1), "seconds")),
  median_tokens = stats::median(vapply(x, function(z) as.numeric(z$usage$total_tokens %||% NA_real_), numeric(1)), na.rm = TRUE),
  errors = sum(vapply(x, function(z) !is.null(z$error) && nzchar(z$error), logical(1))), stringsAsFactors = FALSE
)))
utils::write.csv(summary_rows, sub("[.]jsonl$", "-summary.csv", archive), row.names = FALSE, na = "")
jsonlite::write_json(list(archive = archive, model = model_id, summary = summary_rows), sub("[.]jsonl$", "-summary.json", archive), auto_unbox = TRUE, pretty = TRUE, null = "null")
print(summary_rows)
