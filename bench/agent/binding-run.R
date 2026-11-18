#!/usr/bin/env Rscript

# Run the four internal binding arms on the material already written by
# material-v1.R.  This script reads only binding-v1/dev.  It refuses a path
# containing "heldout" and requires the registered predictions section before
# it starts an archive.

suppressMessages(pkgload::load_all(".", quiet = TRUE, export_all = FALSE, helpers = FALSE))
source("bench/agent/binding-agent.R")

args <- commandArgs(trailingOnly = TRUE)
dry <- "--dry" %in% args || identical(tolower(Sys.getenv("GLOSS_BINDING_DRY", "false")), "true")
arms_arg <- grep("^--arms=", args, value = TRUE)
arms <- if (length(arms_arg)) strsplit(sub("^--arms=", "", arms_arg[1L]), ",", fixed = TRUE)[[1L]] else c("legacy", "contract", "enumeration", "agent")
if (!length(arms) || any(!arms %in% c("legacy", "contract", "enumeration", "agent"))) stop("--arms must be a comma-separated subset of legacy,contract,enumeration,agent")
cache_root <- path.expand(Sys.getenv("GLOSS_BENCH_CACHE", "~/.cache/gloss-bench"))
namespace <- Sys.getenv("GLOSS_BINDING_NAMESPACE", "binding-v1")
root <- file.path(cache_root, "agent", namespace, "dev")
if (!dir.exists(root)) stop("missing development material: run material-v1.R dev first")
if (grepl("heldout", root, ignore.case = TRUE)) stop("binding-run refuses held-out material paths")
predictions <- readLines("bench/predictions.md", warn = FALSE)
if (!any(grepl("Agent-first binding prototype predictions", predictions, fixed = TRUE))) {
  stop("bench/predictions.md does not contain registered agent-first predictions")
}

ids <- setdiff(args, "--dry")
ids <- ids[!startsWith(ids, "--")]
if (!length(ids)) ids <- sort(list.dirs(root, recursive = FALSE, full.names = FALSE))
ids <- ids[dir.exists(file.path(root, ids))]
if (!length(ids)) stop("no development material directories found")

stamp <- format(Sys.time(), "%Y-%m-%d-%H%M%S", tz = "UTC")
archive_dir <- file.path("bench", "runs", "binding-v1")
dir.create(archive_dir, recursive = TRUE, showWarnings = FALSE)
trace_file <- file.path(archive_dir, paste0(stamp, "-trace.jsonl"))
summary_file <- file.path(archive_dir, paste0(stamp, "-summary.csv"))

json_line <- function(x) jsonlite::toJSON(x, auto_unbox = TRUE, null = "null", na = "null",
                                           dataframe = "rows", digits = NA)
append_trace <- function(x) write(json_line(x), trace_file, append = TRUE)

summary_rows <- list()
for (id in ids) {
  dir <- file.path(root, id)
  material <- tryCatch(binding_load_material(dir), error = function(e) e)
  if (inherits(material, "error")) {
    for (arm in arms) {
      row <- data.frame(figure = id, arm = arm, outcome = "operational_failure", accepted = FALSE,
                        ambiguous = FALSE, candidates = NA_integer_, calls = NA_integer_, seconds = NA_real_,
                        failure = conditionMessage(material), stringsAsFactors = FALSE)
      summary_rows[[length(summary_rows) + 1L]] <- row
      append_trace(list(material = id, arm = arm, outcome = "operational_failure", failure = conditionMessage(material)))
    }
    next
  }
  for (arm in arms) {
    started <- Sys.time()
    result <- tryCatch({
      if (arm == "agent") binding_agent_run(material, dry = dry)
      else binding_arm(material, arm, max_candidates = as.integer(Sys.getenv("GLOSS_BINDING_MAX_CANDIDATES", "2000")))
    }, error = function(e) list(status = "operational_failure", outcome = "operational_failure", reason = conditionMessage(e), traces = list(), rows = data.frame()))
    seconds <- as.numeric(difftime(Sys.time(), started, units = "secs"))
    outcome <- result$outcome %||% result$status %||% if (!is.null(result$reason)) "refused" else "operational_failure"
    # Legacy's frozen rows are checked again from the hidden figure object.
    if (arm == "legacy" && identical(result$status, "measured")) {
      fresh <- tryCatch(gloss::gl_bindings(material$oracle$figure_object, by = "element"), error = function(e) e)
      same <- !inherits(fresh, "error") && identical(fresh, material$oracle$legacy$elements)
      result$legacy_linewise_identical <- same
      if (!same) { outcome <- "operational_failure"; result$reason <- "legacy rows changed during replay" }
    }
    if (arm == "enumeration") {
      traces <- result$traces %||% list()
      for (tr in traces) append_trace(binding_trace_record(material, arm, tr, seconds = seconds))
    } else if (arm == "agent") {
      analysis_calls <- Filter(function(call) identical(call$tool, "run_analysis"), result$calls %||% list())
      analysis_hashes <- vapply(analysis_calls, function(call) {
        code <- call$args$code %||% ""
        digest::digest(as.character(code), algo = "sha256", serialize = FALSE)
      }, "")
      for (tr in result$proposals %||% list()) append_trace(binding_trace_record(material, arm, tr,
                                                                                model = result$model %||% NA_character_,
                                                                                calls = length(result$calls %||% list()), seconds = seconds,
                                                                                failure = result$failure %||% NA_character_))
      append_trace(list(record_type = "run_summary", material_version = material$facts$version, material = id, arm = arm,
                        model = result$model %||% NA_character_, outcome = "summary", agent_outcome = outcome,
                        calls = result$calls %||% list(), usage = result$usage %||% list(),
                        analysis_code_sha256 = unname(analysis_hashes), text = result$text %||% "",
                        seconds = seconds, sandbox_calls = result$sandbox_calls %||% NA_integer_,
                        sandbox_resets = result$sandbox_resets %||% NA_integer_,
                        failure = result$failure %||% NA_character_))
    } else {
      append_trace(list(material_version = material$facts$version, material = id, arm = arm,
                        outcome = outcome, seconds = seconds, accepted = result$accepted %||% NA_integer_,
                        ambiguous = result$ambiguous %||% NA_integer_, rejected = result$rejected %||% NA_integer_,
                        legacy_linewise_identical = result$legacy_linewise_identical %||% NA))
    }
    summary_rows[[length(summary_rows) + 1L]] <- data.frame(
      figure = id, arm = arm, outcome = outcome, accepted = identical(outcome, "accepted"),
      ambiguous = identical(outcome, "ambiguous"), candidates = as.integer(result$candidates %||% NA),
      calls = as.integer(result$sandbox_calls %||% length(result$calls %||% list())),
      seconds = round(seconds, 2), failure = as.character(result$failure %||% result$reason %||% ""),
      stringsAsFactors = FALSE)
    cat(sprintf("%s %-11s %-18s %.1fs\n", id, arm, outcome, seconds))
  }
  write.csv(do.call(rbind, summary_rows), summary_file, row.names = FALSE)
}
summary <- do.call(rbind, summary_rows)
write.csv(summary, summary_file, row.names = FALSE)
jsonlite::write_json(list(format = "gloss-agent-binding-run", version = binding_material_version,
                          predictions = "bench/predictions.md", set = "dev", dry = dry,
                          figures = length(ids), arms = arms, summary = summary),
                     sub("\\.csv$", ".json", summary_file), auto_unbox = TRUE, pretty = TRUE,
                     null = "null", dataframe = "rows")
cat(sprintf("archived %d figures x %d arms: %s\n", length(ids), length(arms), summary_file))
