#!/usr/bin/env Rscript

# M5 semantic comparison runner. It builds deterministic directional tasks from
# archived material, runs the four structure/check cells with one fixed loop,
# and writes JSONL traces. Scoring is performed by score-m5.R.

suppressMessages(pkgload::load_all(".", quiet = TRUE, export_all = FALSE, helpers = FALSE))
source("bench/agent/sandbox.R")
options(aisdk.skip_internet_check = TRUE)

`%||%` <- function(a, b) if (is.null(a) || !length(a)) b else a
material_namespace <- Sys.getenv("GLOSS_MATERIAL_NAMESPACE", "m5")
task_prefix <- Sys.getenv("GLOSS_TASK_PREFIX", "m5")
run_prefix <- Sys.getenv("GLOSS_RUN_PREFIX", "m5")

gateway <- "http://127.0.0.1:3425/v1"
models_default <- c("auto/glm-5.3-flash", "auto/gemini-4-argon")
conditions <- c("A", "A_check", "B_no_check", "B_check")
request_timeout <- 180L
sandbox_timeout <- 120L
max_steps_default <- 4L
output_limit <- 4000L

json_line <- function(x) as.character(jsonlite::toJSON(x, auto_unbox = TRUE, null = "null", na = "null", digits = NA))
git_head <- function() system("git rev-parse --short HEAD", intern = TRUE)
utc_stamp <- function() format(Sys.time(), "%Y-%m-%d-%H%M", tz = "UTC")

material_root <- function(set_name) {
  path.expand(file.path(Sys.getenv("GLOSS_BENCH_CACHE", "~/.cache/gloss-bench"), "agent", material_namespace, set_name))
}

load_material <- function(set_name, id) {
  dir <- file.path(material_root(set_name), id)
  if (!file.exists(file.path(dir, "figure.html"))) stop("missing M5 material for ", set_name, "/", id)
  list(
    id = id, dir = dir, fig = gloss::gl_read(file.path(dir, "figure.html")),
    answers = readRDS(file.path(dir, "answers.rds")),
    metadata = jsonlite::read_json(file.path(dir, "m5-metadata.json"), simplifyVector = FALSE)
  )
}

numeric_columns <- function(d) {
  keep <- vapply(d, is.numeric, logical(1))
  setdiff(names(d)[keep], c("row", "PANEL", "group", "xend", "yend", "xmin", "xmax", "ymin", "ymax"))
}

choose_task <- function(m, ordinal = 1L) {
  table_files <- sort(list.files(file.path(m$dir, "A", "tables"), pattern = "^built_.*[.]csv$", full.names = TRUE))
  candidates <- list()
  for (file in table_files) {
    d <- tryCatch(utils::read.csv(file, stringsAsFactors = FALSE), error = function(e) NULL)
    if (!is.data.frame(d) || nrow(d) < 3L) next
    nums <- numeric_columns(d)
    if (length(nums) < 2L) next
    for (predictor in nums) for (response in setdiff(nums, predictor)) {
      ok <- is.finite(d[[predictor]]) & is.finite(d[[response]])
      if (sum(ok) < 3L || stats::sd(d[[predictor]][ok]) == 0) next
      fit <- tryCatch(stats::lm(d[[response]][ok] ~ d[[predictor]][ok]), error = function(e) NULL)
      if (is.null(fit)) next
      slope <- unname(stats::coef(fit)[2L])
      if (!is.finite(slope) || slope == 0) next
      candidates[[length(candidates) + 1L]] <- list(
        table = sub("[.]csv$", "", basename(file)), predictor = predictor,
        response = response, actual_expect = if (slope > 0) "positive" else "negative",
        slope = slope, n = sum(ok)
      )
    }
  }
  if (!length(candidates)) return(NULL)
  candidates[[min(ordinal, length(candidates))]]
}

build_tasks <- function(set_name, ids = NULL, out_file = NULL) {
  if (is.null(ids)) {
    split <- utils::read.csv("bench/split.csv", stringsAsFactors = FALSE)
    ids <- split$id[split$set == set_name & split$id %in% basename(list.dirs(material_root(set_name), recursive = FALSE, full.names = FALSE))]
  }
  rows <- list()
  for (i in seq_along(ids)) {
    m <- load_material(set_name, ids[i])
    cand <- choose_task(m, ordinal = 1L)
    if (is.null(cand)) next
    b <- m$answers$elements
    anchor <- if (is.data.frame(b) && nrow(b)) b$element[match(cand$table, b$table)] else NA_character_
    if (is.na(anchor) || !nzchar(anchor)) anchor <- gloss::gl_elements(m$fig)$id[1L]
    actual <- cand$actual_expect
    truth <- (i %% 2L == 1L)
    claim_expect <- if (truth) actual else if (actual == "positive") "negative" else "positive"
    rows[[length(rows) + 1L]] <- data.frame(
      task = paste(set_name, ids[i], sep = "-"), set = set_name, figure = ids[i],
      stratum = jsonlite::read_json(file.path("bench", "figures", ids[i], "meta.json"), simplifyVector = TRUE)$stratum,
      table = cand$table, predictor = cand$predictor, response = cand$response,
      actual_expect = actual, claim_expect = claim_expect, truth = truth,
      slope = cand$slope, n = cand$n, anchor = anchor,
      source_scene_sha256 = m$metadata$visual$source_scene_sha256 %||% NA_character_,
      prepared_view_sha256 = m$metadata$visual$prepared_view_sha256 %||% NA_character_,
      stringsAsFactors = FALSE
    )
  }
  tasks <- if (length(rows)) do.call(rbind, rows) else data.frame()
  if (!is.null(out_file)) utils::write.csv(tasks, out_file, row.names = FALSE, na = "")
  tasks
}

z_string <- function(description) aisdk::z_string(description)
z_any <- function(description) aisdk::z_any(description)

claim_parameters <- function() aisdk::z_object(
  table = z_string("built table name"), predictor = z_string("predictor column"),
  response = z_string("response column"), expect = z_string("positive or negative"),
  verdict = z_string("true or false")
)

claim_tool <- function(name, description, run) {
  aisdk::tool(name = name, description = description,
              parameters = claim_parameters(), execute = function(...) run(list(...)))
}

make_a_tools <- function(m, task, checked) {
  sb <- sandbox_open(file.path(m$dir, "A"),
                     env = if (task$stratum %in% c("bioc", "heatmap", "tree")) "bioc" else "cran")
  state <- new.env(parent = emptyenv())
  state$calls <- list()
  state$submissions <- list()
  note <- function(tool, args, ok, result, ...) {
    state$calls[[length(state$calls) + 1L]] <- c(list(tool = tool, args = args, ok = ok, result = result), list(...))
    result
  }
  run_r <- aisdk::tool(
    name = "run_r",
    description = sprintf("Run one R script in the read-only figure sandbox. Output is clipped to %d characters.", output_limit),
    parameters = aisdk::z_object(code = z_string("R code")),
    execute = function(...) {
      a <- list(...)
      if (!is.character(a$code) || length(a$code) != 1L || !nzchar(a$code)) {
        return(note("run_r", a, FALSE, '{"error":"code must be one non-empty string"}'))
      }
      r <- sandbox_run(sb, a$code, timeout = sandbox_timeout, limit = output_limit)
      out <- if (nzchar(r$output)) r$output else "[the code printed nothing]"
      if (r$status != 0L && !r$timed_out && !r$killed) out <- paste0(out, sprintf("\n[R ended with status %d]", r$status))
      note("run_r", a, r$status == 0L, out, seconds = r$seconds, timed_out = r$timed_out, killed = r$killed)
    })
  submit <- claim_tool(
    "submit",
    "Submit a directional claim. Use the supplied table and column names. verdict is true only when the claim is supported.",
    function(a) {
      ok <- is.character(a$table) && is.character(a$predictor) && is.character(a$response) &&
        is.character(a$expect) && is.character(a$verdict)
      if (!ok) return(note("submit", a, FALSE, '{"error":"all fields must be strings"}'))
      if (checked) {
        d <- tryCatch(gloss::gl_table(m$fig, a$table), error = function(e) NULL)
        result <- if (is.null(d)) list(status = "refused", reason = "unknown table") else
          gloss::gl_check(d, "trend", list(response = a$response, predictor = a$predictor, expect = a$expect))
        state$submissions[[length(state$submissions) + 1L]] <- list(args = a, status = result$status,
                                                                      reason = result$reason %||% NULL)
        out <- json_line(list(recorded = TRUE, status = result$status, reason = result$reason %||% NULL))
      } else {
        state$submissions[[length(state$submissions) + 1L]] <- list(args = a, status = "unvalidated")
        out <- '{"recorded":true,"status":"unvalidated"}'
      }
      note("submit", a, TRUE, out)
    })
  structure(list(tools = list(run_r, submit), state = state, sandbox = sb), class = "m5_a_tools")
}

make_b_tools <- function(m, task, checked) {
  tools <- gloss::gl_tools(m$fig, stage = "claim", disclose = "rows")
  keep <- tools[!vapply(tools, function(x) x$name %in% c("check", "propose", "records", "get_context"), logical(1))]
  state <- new.env(parent = emptyenv())
  state$calls <- list(); state$submissions <- list()
  submit <- claim_tool(
    "submit",
    if (checked) "Submit a directional claim. The closed trend check runs at submission and returns verified or failed."
    else "Submit a directional claim without validation. Use the supplied table and column names. verdict is true or false.",
    function(a) {
      status <- "unvalidated"
      if (checked) {
        d <- tryCatch(gloss::gl_table(m$fig, a$table), error = function(e) NULL)
        result <- if (is.null(d)) list(status = "refused", reason = "unknown table") else
          gloss::gl_check(d, "trend", list(response = a$response, predictor = a$predictor, expect = a$expect))
        status <- result$status
      }
      state$submissions[[length(state$submissions) + 1L]] <- list(args = a, status = status)
      result <- json_line(list(recorded = TRUE, status = status))
      state$calls[[length(state$calls) + 1L]] <- list(tool = "submit", args = a, ok = TRUE, result = result)
      result
    })
  structure(list(tools = c(keep, list(submit)), read_tools = keep, gloss_tools = tools,
                state = state, sandbox = NULL), class = "m5_b_tools")
}

system_prompt <- function(condition, task) {
  checked <- condition %in% c("A_check", "B_check")
  base <- paste(
    "You are evaluating one directional claim about a captured R figure.",
    "Use only the supplied material and tools. The claim is supported when the",
    "response column has the supplied trend against the predictor column.",
    "Call the final submission tool exactly once. Use the exact table and column",
    "names in the task. Set verdict to true only when the claim is supported.",
    sprintf("Task table %s, predictor %s, response %s, claimed trend %s.",
            task$table, task$predictor, task$response, task$claim_expect),
    if (condition %in% c("A", "A_check")) paste(
      sprintf("The raw material file is tables/%s.csv. Read it with read.csv and use", task$table),
      "the columns named in the task. Do not refer to an R object before reading the file."
    ) else paste(
      "For this fixed-loop run, call `submit` as the first action using the exact",
      "fields already supplied. Do not spend requests exploring overview or elements.",
      "The checked submit returns the code-derived status. The unchecked submit records your verdict."
    ),
    if (condition == "B_check") paste(
      "For the checked gloss condition, call the `submit` tool with the exact",
      sprintf("table `%s`, response `%s`, predictor `%s`, and expect `%s`.", task$table,
              task$response, task$predictor, task$claim_expect),
      "The tool returns the closed check status."
    ) else if (checked) "The submission result will include the closed check status." else "The submission is recorded without validation.")
  base
}

user_prompt <- function(task) {
  sprintf(paste(
    "Decide whether this claim is supported by the figure data.",
    "Claim: the `%s` column in `%s` has a %s trend as `%s` increases.",
    "Use the available tools, then submit the claim with verdict true or false."),
    task$response, task$table, task$claim_expect, task$predictor)
}

gateway_key <- function() Sys.getenv("ANTHROPIC_AUTH_TOKEN", "local")

chat_request <- function(model_id, messages, tools = NULL, timeout = request_timeout) {
  body <- list(model = model_id, messages = messages, temperature = 0)
  if (length(tools)) body$tools <- lapply(tools, function(t) t$to_api_format())
  payload <- jsonlite::toJSON(body, auto_unbox = TRUE, null = "null", digits = NA)
  last <- "no request made"
  for (attempt in seq_len(3L)) {
    h <- curl::new_handle()
    curl::handle_setheaders(h, Authorization = paste("Bearer", gateway_key()), `Content-Type` = "application/json")
    curl::handle_setopt(h, copypostfields = payload, timeout = as.integer(timeout))
    res <- tryCatch(curl::curl_fetch_memory(paste0(gateway, "/chat/completions"), handle = h), error = function(e) e)
    if (inherits(res, "error")) last <- paste("request failed:", conditionMessage(res)) else {
      txt <- rawToChar(res$content); Encoding(txt) <- "UTF-8"
      parsed <- tryCatch(jsonlite::fromJSON(txt, simplifyVector = FALSE), error = function(e) NULL)
      msg <- parsed$choices[[1L]]$message %||% NULL
      if (res$status_code == 200L && is.list(msg)) return(list(message = msg, usage = parsed$usage, error = NULL))
      why <- parsed$error$message %||% substr(txt, 1L, 200L)
      last <- sprintf("HTTP %d: %s", res$status_code, substr(gsub("[0-9]{1,3}(\\.[0-9]{1,3}){3}", "<address>", why), 1L, 200L))
      if (res$status_code < 429L) break
    }
    if (attempt < 3L) Sys.sleep(2 * attempt)
  }
  list(message = NULL, usage = NULL, error = last)
}

tool_loop <- function(model_id, system, prompt, tools, max_steps = max_steps_default) {
  by_name <- stats::setNames(tools, vapply(tools, function(t) t$name, ""))
  messages <- list(list(role = "system", content = system), list(role = "user", content = prompt))
  usage <- c(prompt_tokens = 0, completion_tokens = 0, total_tokens = 0)
  requests <- 0L; text <- NA_character_; error <- NA_character_; finish <- NA_character_
  repeat {
    if (requests >= max_steps) { finish <- "step limit"; break }
    requests <- requests + 1L
    r <- chat_request(model_id, messages, tools)
    if (!is.null(r$error)) { error <- r$error; finish <- "request error"; break }
    for (k in names(usage)) usage[[k]] <- usage[[k]] + as.numeric(r$usage[[k]] %||% 0)
    msg <- r$message; calls <- msg$tool_calls; content <- if (is.character(msg$content)) msg$content else ""
    if (!length(calls)) { text <- content; finish <- "stop"; break }
    messages[[length(messages) + 1L]] <- list(role = "assistant", content = content,
      tool_calls = lapply(calls, function(tc) list(id = tc$id, type = "function",
        `function` = list(name = tc$`function`$name, arguments = tc$`function`$arguments %||% "{}"))))
    for (tc in calls) {
      raw <- tc$`function`$arguments %||% "{}"
      a <- tryCatch(jsonlite::fromJSON(if (nzchar(trimws(raw))) raw else "{}", simplifyVector = FALSE), error = function(e) NULL)
      tool <- by_name[[tc$`function`$name %||% ""]]
      out <- if (is.null(tool)) json_line(list(error = "no such tool")) else if (!is.list(a)) {
        json_line(list(error = "arguments are not a JSON object"))
      } else tryCatch(as.character(tool$run(a)), error = function(e) json_line(list(error = substr(conditionMessage(e), 1L, 300L))))
      messages[[length(messages) + 1L]] <- list(role = "tool", tool_call_id = tc$id, content = paste(out, collapse = "\n"))
    }
  }
  list(text = text, finish = finish, error = error, requests = requests, usage = as.list(usage))
}

submission_from_state <- function(condition, tools_obj, fig) {
  if (condition %in% c("A", "A_check", "B_no_check", "B_check")) {
    s <- tools_obj$state$submissions
    if (!length(s)) return(list(status = "none", verdict = NA, covered = FALSE, correct_payload = NULL))
    last <- s[[length(s)]]
    return(list(status = last$status %||% "unvalidated", verdict = last$args$verdict %||% NA,
                covered = !identical(last$status, "none"), correct_payload = last$args))
  }
  st <- gloss::gl_tool_state(tools_obj$tools)
  props <- st$proposals %||% list()
  if (!length(props)) return(list(status = "none", verdict = NA, covered = FALSE, correct_payload = NULL, state = st))
  candidate <- props[[length(props)]]
  rec <- candidate$record %||% NULL
  status <- rec$status %||% candidate$outcome %||% "rejected"
  list(status = status, verdict = if (identical(status, "verified")) "true" else if (identical(status, "failed")) "false" else NA,
       covered = status %in% c("verified", "failed", "partial"), correct_payload = rec, state = st)
}

score_submission <- function(task, condition, submission) {
  truth <- isTRUE(task$truth)
  status <- submission$status
  if (condition %in% c("A", "B_no_check")) {
    verdict <- tolower(as.character(submission$verdict %||% ""))
    correct <- nzchar(verdict) && identical(verdict, if (truth) "true" else "false")
    return(list(correct = correct, covered = nzchar(verdict), false_accept = !truth && identical(verdict, "true"),
                false_reject = truth && identical(verdict, "false")))
  }
  correct <- if (truth) identical(status, "verified") else identical(status, "failed")
  list(correct = correct, covered = isTRUE(submission$covered), false_accept = !truth && identical(status, "verified"),
       false_reject = truth && identical(status, "failed"))
}

run_one <- function(model_id, condition, m, task, repeat_n, max_steps, out_dir) {
  checked <- condition %in% c("A_check", "B_check")
  tools_obj <- if (condition %in% c("A", "A_check")) make_a_tools(m, task, checked) else make_b_tools(m, task, checked)
  on.exit(if (!is.null(tools_obj$sandbox)) sandbox_close(tools_obj$sandbox), add = TRUE)
  t0 <- Sys.time()
  res <- tryCatch(tool_loop(model_id, system_prompt(condition, task), user_prompt(task), tools_obj$tools, max_steps = max_steps),
                  error = function(e) list(text = NA_character_, finish = "error", error = conditionMessage(e), requests = NA_integer_, usage = NULL))
  seconds <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  sub <- submission_from_state(condition, tools_obj, m$fig)
  score <- score_submission(task, condition, sub)
  state <- if (condition %in% c("A", "A_check")) tools_obj$state else if (condition %in% c("B_no_check", "B_check")) {
    st <- gloss::gl_tool_state(tools_obj$gloss_tools)
    st$calls <- c(st$calls %||% list(), tools_obj$state$calls %||% list())
    st
  } else gloss::gl_tool_state(tools_obj$tools)
  row <- c(
    list(model = model_id, set = task$set, figure = task$figure, task = task$task,
         condition = condition, repeat_n = repeat_n, truth = task$truth, actual_expect = task$actual_expect,
         claim_expect = task$claim_expect, table = task$table, predictor = task$predictor, response = task$response,
         status = sub$status, verdict = sub$verdict, correct = score$correct, covered = score$covered,
         false_accept = score$false_accept, false_reject = score$false_reject,
         seconds = round(seconds, 2), finish = res$finish, steps = res$requests, error = res$error %||% NULL,
         usage = res$usage %||% NULL, source_scene_sha256 = task$source_scene_sha256,
         prepared_view_sha256 = task$prepared_view_sha256),
    list(tool_calls = length(state$calls %||% list()), failed_calls = sum(!vapply(state$calls %||% list(), function(x) isTRUE(x$ok), logical(1))),
         calls = lapply(state$calls %||% list(), function(x) {
           x$result <- if (is.character(x$result)) substr(x$result, 1L, 800L) else x$result
           x
         }), submissions = sub$correct_payload %||% NULL, text = if (is.null(res$text)) NULL else substr(res$text, 1L, 500L)))
  row
}

write_task_file <- function(set_name) {
  dir.create("bench/agent", showWarnings = FALSE)
  path <- file.path("bench", "agent", paste0(task_prefix, "-tasks-", set_name, ".csv"))
  if (!file.exists(path)) {
    tasks <- build_tasks(set_name, out_file = path)
  } else tasks <- utils::read.csv(path, stringsAsFactors = FALSE)
  if (!nrow(tasks)) stop("no scorable M5 tasks for ", set_name)
  tasks
}

args <- commandArgs(trailingOnly = TRUE)
mode <- if (length(args)) args[1L] else "tasks"
set_name <- if (length(args) > 1L) args[2L] else "dev"
if (!set_name %in% c("dev", "heldout")) stop("set must be dev or heldout")

if (mode == "tasks") {
  tasks <- build_tasks(set_name, out_file = file.path("bench", "agent", paste0(task_prefix, "-tasks-", set_name, ".csv")))
  print(tasks, row.names = FALSE)
  quit(status = if (nrow(tasks)) 0L else 1L)
}

if (mode == "scripted") {
  tasks <- write_task_file("dev")
  m <- load_material("dev", tasks$figure[1L])
  t <- as.list(tasks[1L, ])
  model <- R6::R6Class("m5_scripted", inherit = aisdk::LanguageModelV1,
    public = list(seen = 0L, initialize = function() super$initialize(provider = "scripted", model_id = "m5-scripted"),
      format_tool_result = function(tool_call_id, tool_name, result_content) list(role = "tool", tool_call_id = tool_call_id, name = tool_name, content = result_content),
      do_generate = function(params) {
        self$seen <- self$seen + 1L
        usage <- list(prompt_tokens = 3, completion_tokens = 2, total_tokens = 5)
        if (self$seen == 1L) {
          return(list(text = "", finish_reason = "tool_calls", usage = usage,
            tool_calls = list(list(id = "m5-scripted-1", name = "propose", arguments = list(layer = "claim", anchor = t$anchor,
              body = list(text = "scripted claim", check = list(kind = "trend", table = t$table,
                args = list(response = t$response, predictor = t$predictor, expect = t$actual_expect))))))))
        }
        list(text = "done", tool_calls = NULL, finish_reason = "stop", usage = usage)
      }))$new()
  out <- gloss:::run_stage(m$fig, "claim", model = model, context = list(task = "scripted M5"), max_steps = 3L)
  print(list(committed = length(out$report$committed %||% list()), status = gl_records(out$fig, "claim")$status,
             substrate_unchanged = identical(m$fig$substrate$scene, out$fig$substrate$scene)))
  quit(status = 0L)
}

if (mode != "run") stop("usage: m5-pilot.R tasks|scripted|run dev|heldout")

tasks <- write_task_file(set_name)
models <- strsplit(Sys.getenv("M5_MODELS", paste(models_default, collapse = ",")), ",", fixed = TRUE)[[1L]]
repeats <- as.integer(Sys.getenv("M5_REPEATS", if (set_name == "heldout") "2" else "2"))
max_steps <- as.integer(Sys.getenv("M5_MAX_STEPS", if (set_name == "heldout") "4" else "4"))
task_filter <- strsplit(Sys.getenv("M5_TASK_IDS", ""), ",", fixed = TRUE)[[1L]]
task_filter <- task_filter[nzchar(task_filter)]
if (length(task_filter)) tasks <- tasks[tasks$task %in% task_filter, , drop = FALSE]
condition_filter <- strsplit(Sys.getenv("M5_CONDITIONS", ""), ",", fixed = TRUE)[[1L]]
condition_filter <- condition_filter[nzchar(condition_filter)]
if (length(condition_filter)) conditions <- intersect(conditions, condition_filter)
if (!nrow(tasks) || !length(conditions)) stop("the requested M5 run has no tasks or conditions")
stamp <- utc_stamp()
out_file <- file.path("bench", "runs", paste0(stamp, "-", run_prefix, "-", set_name, ".jsonl"))
dir.create("bench/runs", recursive = TRUE, showWarnings = FALSE)
writeLines(json_line(list(meta = TRUE, script = "bench/agent/m5-pilot.R", set = set_name, models = models,
                          conditions = conditions, repeats = repeats, max_steps = max_steps,
                          request_timeout = request_timeout, sandbox_timeout = sandbox_timeout,
                          task_file = file.path("bench", "agent", paste0(task_prefix, "-tasks-", set_name, ".csv")),
                          gloss_commit = git_head(), prompt_version = paste0(run_prefix, "-v1"))), out_file)

for (model_id in models) for (i in seq_len(nrow(tasks))) for (condition in conditions) for (rep in seq_len(repeats)) {
  task <- as.list(tasks[i, ])
  m <- load_material(set_name, task$figure)
  row <- tryCatch(run_one(model_id, condition, m, task, rep, max_steps, dirname(out_file)), error = function(e) {
    list(model = model_id, set = set_name, figure = task$figure, task = task$task, condition = condition,
         repeat_n = rep, error = conditionMessage(e), correct = FALSE, covered = FALSE, false_accept = FALSE,
         false_reject = FALSE)
  })
  cat(json_line(row), "\n", file = out_file, append = TRUE)
  cat(sprintf("%s %s %s r%d correct=%s covered=%s status=%s %.1fs\n", model_id, task$figure, condition,
              rep, row$correct %||% FALSE, row$covered %||% FALSE, row$status %||% "error", row$seconds %||% NA))
}

cat("archived:", out_file, "\n")
