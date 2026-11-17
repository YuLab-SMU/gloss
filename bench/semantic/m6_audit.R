#!/usr/bin/env Rscript

# M6 audit contract and deterministic proxy. The proxy deliberately labels its
# raters by method; it does not claim to replace the two-person open-world
# audit. The latter is archived as a human queue with blank labels.

source("bench/R/runner.R")
.libPaths(unique(c(bench_libpaths(), .libPaths())))
suppressMessages(pkgload::load_all(".", quiet = TRUE, export_all = FALSE, helpers = FALSE))
if (!requireNamespace("ggplot2", quietly = TRUE)) stop("ggplot2 is required")
`%||%` <- function(a, b) if (is.null(a) || !length(a)) b else a

namespace <- Sys.getenv("GLOSS_MATERIAL_NAMESPACE", "m6-container")
task_file <- Sys.getenv("GLOSS_AUDIT_TASK_FILE", "bench/agent/m6-tasks-dev.csv")
cache_root <- path.expand(Sys.getenv("GLOSS_BENCH_CACHE", "~/.cache/gloss-bench"))
material_root <- file.path(cache_root, "agent", namespace, "dev")
out_dir <- file.path("bench", "runs", "m6-audit")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
tasks <- utils::read.csv(task_file, stringsAsFactors = FALSE)
if (!nrow(tasks)) stop("no tasks in ", task_file)

load_material <- function(id) {
  dir <- file.path(material_root, id)
  if (!file.exists(file.path(dir, "figure.html"))) stop("missing material for ", id)
  list(
    dir = dir,
    fig = gloss::gl_read(file.path(dir, "figure.html")),
    answers = readRDS(file.path(dir, "answers.rds")),
    metadata = jsonlite::read_json(file.path(dir, "m5-metadata.json"), simplifyVector = FALSE)
  )
}

rows <- list()
for (i in seq_len(nrow(tasks))) {
  task <- tasks[i, , drop = FALSE]
  m <- load_material(task$figure)
  d <- gloss::gl_table(m$fig, task$table)
  fit <- stats::lm(d[[task$response]] ~ d[[task$predictor]])
  slope <- unname(stats::coef(fit)[2L])
  for (truth in c(TRUE, FALSE)) {
    expect <- if (truth) task$actual_expect else if (task$actual_expect == "positive") "negative" else "positive"
    check <- tryCatch(gloss::gl_check(d, "trend", list(response = task$response, predictor = task$predictor, expect = expect)),
                      error = function(e) list(status = "refused", reason = conditionMessage(e)))
    code_label <- if (identical(check$status, "verified")) "supported" else if (identical(check$status, "failed")) "unsupported" else "unresolved"
    recompute <- (expect == "positive" && is.finite(slope) && slope > 0) ||
      (expect == "negative" && is.finite(slope) && slope < 0)
    rows[[length(rows) + 1L]] <- data.frame(
      item = sprintf("claim-%02d-%s", i, if (truth) "true" else "false"), type = "claim",
      figure = task$figure, task = task$task, audit_kind = "deterministic_proxy",
      expected = if (truth) "supported" else "unsupported", rater_a = code_label,
      rater_b = if (recompute) "supported" else "unsupported", adjudicated = NA_character_,
      reason = check$reason %||% "independent slope recomputation", human_required = FALSE,
      stringsAsFactors = FALSE
    )
  }
  bound <- m$answers$elements
  bound <- bound[bound$table == task$table & bound$status == "verified" & !is.na(bound$row), , drop = FALSE]
  if (nrow(bound)) {
    z <- bound[1L, , drop = FALSE]
    wrong <- if (as.integer(z$row) == 1L) 2L else 1L
    for (right in c(TRUE, FALSE)) {
      proposal <- gloss::gl_propose(m$fig, list(kind = "binding", element = z$element,
                                                table = z$table, row = if (right) z$row else wrong))
      code_label <- if (identical(proposal$outcome, "accepted")) "verified" else "rejected"
      rows[[length(rows) + 1L]] <- data.frame(
        item = sprintf("binding-%02d-%s", i, if (right) "true" else "false"), type = "binding",
        figure = task$figure, task = task$task, audit_kind = "deterministic_proxy",
        expected = if (right) "verified" else "rejected", rater_a = code_label,
        rater_b = if (right) "verified" else "rejected", adjudicated = NA_character_,
        reason = if (right) "captured binding" else "independent wrong-row perturbation",
        human_required = FALSE, stringsAsFactors = FALSE
      )
    }
  }
}
proxy <- do.call(rbind, rows)
proxy$agreement <- proxy$rater_a == proxy$rater_b

queue_path <- "bench/runs/2026-11-15-semantic-pilot-audit.csv"
human_queue <- if (file.exists(queue_path)) {
  q <- utils::read.csv(queue_path, stringsAsFactors = FALSE)
  data.frame(
    item = paste0("open-world-", q$id), type = as.character(q$layer),
    figure = "mtcars-facet-points", task = as.character(q$audit_question),
    audit_kind = "open_world_human_queue", expected = NA_character_,
    rater_a = NA_character_, rater_b = NA_character_, adjudicated = NA_character_,
    reason = as.character(q$reason), human_required = TRUE, agreement = NA,
    stringsAsFactors = FALSE
  )
} else data.frame()

all_rows <- rbind(proxy, human_queue)
stamp <- format(Sys.time(), "%Y-%m-%d-%H%M", tz = "UTC")
csv <- file.path(out_dir, paste0(stamp, "-items.csv"))
utils::write.csv(all_rows, csv, row.names = FALSE, na = "")
summary <- list(
  namespace = namespace, task_file = task_file,
  proxy_items = nrow(proxy), proxy_agreement = sum(proxy$agreement),
  proxy_agreement_rate = mean(proxy$agreement),
  open_world_human_queue = nrow(human_queue), human_labels_present = sum(!is.na(human_queue$rater_a)),
  statuses = as.list(table(all_rows$audit_kind)), csv = csv
)
jsonlite::write_json(summary, sub("[.]csv$", "-summary.json", csv), auto_unbox = TRUE, pretty = TRUE, null = "null")
print(summary)
