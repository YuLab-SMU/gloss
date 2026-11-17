#!/usr/bin/env Rscript

# Score an archived M5 JSONL trace. This script makes no model calls.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L || !file.exists(args[1L])) stop("usage: Rscript bench/agent/score-m5.R <m5-jsonl>")
file <- args[1L]
lines <- readLines(file, warn = FALSE)
if (!length(lines)) stop("empty M5 archive")
meta <- jsonlite::fromJSON(lines[1L], simplifyVector = FALSE)
rows <- lapply(lines[-1L], function(x) jsonlite::fromJSON(x, simplifyVector = FALSE))
rows <- Filter(function(x) !is.null(x$model) && !is.null(x$condition), rows)
if (!length(rows)) stop("the archive contains no run rows")

scalar <- function(x, default = NA) {
  if (is.null(x) || !length(x)) return(default)
  if (is.list(x)) return(default)
  x[[1L]]
}
usage_total <- function(x) {
  u <- x$usage
  if (is.null(u) || !length(u)) return(NA_real_)
  as.numeric(u$total_tokens %||% NA_real_)
}
`%||%` <- function(a, b) if (is.null(a) || !length(a)) b else a

d <- do.call(rbind, lapply(rows, function(r) data.frame(
  model = scalar(r$model, NA_character_), set = scalar(r$set, NA_character_),
  figure = scalar(r$figure, NA_character_), task = scalar(r$task, NA_character_),
  condition = scalar(r$condition, NA_character_), repeat_n = as.integer(scalar(r$repeat_n, NA_integer_)),
  truth = as.logical(scalar(r$truth, NA)), status = scalar(r$status, NA_character_),
  verdict = scalar(r$verdict, NA_character_), correct = as.logical(scalar(r$correct, FALSE)),
  covered = as.logical(scalar(r$covered, FALSE)), false_accept = as.logical(scalar(r$false_accept, FALSE)),
  false_reject = as.logical(scalar(r$false_reject, FALSE)), seconds = as.numeric(scalar(r$seconds, NA_real_)),
  steps = as.integer(scalar(r$steps, NA_integer_)), tokens = usage_total(r),
  error = scalar(r$error, NA_character_), stringsAsFactors = FALSE
)))

rate <- function(x) if (!length(x)) NA_real_ else mean(x, na.rm = TRUE)
med <- function(x) if (!length(x) || all(is.na(x))) NA_real_ else stats::median(x, na.rm = TRUE)
summary_rows <- lapply(split(d, list(d$model, d$condition), drop = TRUE), function(x) data.frame(
  model = x$model[1L], condition = x$condition[1L], runs = nrow(x),
  correct = rate(x$correct), coverage = rate(x$covered), false_accept = rate(x$false_accept),
  false_reject = rate(x$false_reject), median_tokens = med(x$tokens), median_seconds = med(x$seconds),
  request_errors = sum(!is.na(x$error) & nzchar(x$error)), stringsAsFactors = FALSE
))
summary_table <- do.call(rbind, summary_rows)
rownames(summary_table) <- NULL

paired <- function(left, right, measure) {
  a <- aggregate(d[[measure]][d$condition == left], list(task = d$task[d$condition == left], model = d$model[d$condition == left]), mean, na.rm = TRUE)
  b <- aggregate(d[[measure]][d$condition == right], list(task = d$task[d$condition == right], model = d$model[d$condition == right]), mean, na.rm = TRUE)
  names(a)[3L] <- "left"; names(b)[3L] <- "right"
  m <- merge(a, b, by = c("task", "model"))
  if (nrow(m)) m$delta <- m$right - m$left
  m
}

out_txt <- sub("[.]jsonl$", "-score.txt", file)
out_csv <- sub("[.]jsonl$", "-score.csv", file)
write.csv(d, out_csv, row.names = FALSE, na = "")
sink(out_txt)
cat("M5 archive:", file, "\n")
cat("set:", meta$set %||% NA_character_, "models:", paste(unlist(meta$models %||% list()), collapse = ", "),
    "conditions:", paste(unlist(meta$conditions %||% list()), collapse = ", "), "\n\n")
cat("condition summary\n")
print(summary_table, row.names = FALSE)
cat("\nerrors by condition\n")
print(with(d, table(condition, error = !is.na(error) & nzchar(error))))
cat("\nB check minus B no check, correctness and coverage\n")
print(paired("B_no_check", "B_check", "correct"), row.names = FALSE)
print(paired("B_no_check", "B_check", "covered"), row.names = FALSE)
cat("\nA check minus A, correctness and coverage\n")
print(paired("A", "A_check", "correct"), row.names = FALSE)
print(paired("A", "A_check", "covered"), row.names = FALSE)
sink()

jsonlite::write_json(list(
  archive = normalizePath(file), meta = meta, runs = nrow(d),
  conditions = summary_table, request_errors = sum(!is.na(d$error) & nzchar(d$error)),
  materialized = TRUE
), sub("[.]jsonl$", "-summary.json", file), auto_unbox = TRUE, pretty = TRUE, null = "null")

cat(readLines(out_txt, warn = FALSE), sep = "\n")
