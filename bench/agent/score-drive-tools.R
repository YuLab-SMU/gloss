# Score a run of bench/agent/drive-tools.R against predictions 102-107:
#   Rscript bench/agent/score-drive-tools.R bench/runs/<stamp>-drive-tools.json
# Reads the archive only; calls no model.

args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 1L, file.exists(args[1]))
a <- jsonlite::fromJSON(args[1], simplifyVector = FALSE)
runs <- a$runs
field <- function(name, type) vapply(runs, function(r) {
  v <- r[[name]]
  if (is.null(v)) methods::as(NA, type) else methods::as(v, type)
}, methods::as(NA, type))
d <- data.frame(
  model = sub("^westlakehpc/", "", field("model", "character")),
  variant = field("variant", "character"),
  question = field("question", "integer"),
  correct = field("correct", "logical"),
  tool_calls = field("tool_calls", "integer"),
  failed_calls = field("failed_calls", "integer"),
  rejected = field("rejected", "integer"),
  seconds = field("seconds", "numeric"),
  error = !is.na(field("error", "character")),
  finish = field("finish", "character"),
  seen = field("calls_seen_by_aisdk", "integer"),
  stringsAsFactors = FALSE
)
# a rejected submission followed by an accepted one, for the element asked about
d$recovered <- vapply(runs, function(r) {
  acc <- vapply(r$submissions, function(s) isTRUE(s$accepted), logical(1))
  length(acc) > 1L && any(!acc) && any(acc) && which(acc)[1] > which(!acc)[1]
}, logical(1))
tokens <- vapply(runs, function(r) {
  u <- r$usage
  v <- u$total_tokens
  if (is.null(v)) NA_real_ else as.numeric(v)
}, 1)

cat(sprintf("%s | %d runs | models %s | gloss %s | aisdk %s\n\n", a$meta$stamp, nrow(d),
            paste(sub("^westlakehpc/", "", unlist(a$meta$models)), collapse = ", "),
            a$meta$gloss_commit, a$meta$aisdk))
cat("correct runs of 10, by model and variant\n")
print(stats::xtabs(correct ~ model + variant, d))
cat("\nruns that raised an error:", sum(d$error), "| runs that ended without an accepted submission:", sum(!d$correct), "\n")
cat("finish reasons:", paste(names(table(d$finish, useNA = "ifany")), table(d$finish, useNA = "ifany"), collapse = ", "), "\n")

med <- function(v) stats::median(v, na.rm = TRUE)
cat("\nmedian tool calls in correct runs: L", med(d$tool_calls[d$correct & d$variant == "L"]),
    "| M", med(d$tool_calls[d$correct & d$variant == "M"]), "\n")
by <- stats::aggregate(cbind(tool_calls, failed_calls, rejected, seconds) ~ model + variant, d,
                       function(v) round(stats::median(v), 1))
names(by)[3:6] <- c("median_calls", "median_failed", "median_rejected", "median_seconds")
print(by, row.names = FALSE)
cat(sprintf("\nfailed calls: %d of %d (%.1f%%); calls aisdk recorded that no tool saw: %d\n",
            sum(d$failed_calls), sum(d$tool_calls), 100 * sum(d$failed_calls) / max(1, sum(d$tool_calls)),
            sum(pmax(d$seen - d$tool_calls, 0), na.rm = TRUE)))
cat(sprintf("seconds per run: median %.1f, 90th percentile %.1f, max %.1f; total %.1f min\n",
            med(d$seconds), stats::quantile(d$seconds, 0.9), max(d$seconds), sum(d$seconds) / 60))
cat(sprintf("variant M runs with a rejected submission followed by an accepted one: %d of %d; runs with any rejection: L %d, M %d\n",
            sum(d$recovered & d$variant == "M"), sum(d$variant == "M"),
            sum(d$rejected > 0 & d$variant == "L"), sum(d$rejected > 0 & d$variant == "M")))
if (any(!is.na(tokens))) {
  cat(sprintf("total tokens per run, where the gateway gave them (%d runs): median %.0f, max %.0f\n",
              sum(!is.na(tokens)), med(tokens), max(tokens, na.rm = TRUE)))
} else cat("the gateway gave no token counts\n")
wrong <- d[!d$correct, c("model", "variant", "question", "tool_calls", "rejected", "failed_calls", "seconds", "finish", "error")]
if (nrow(wrong)) {
  cat("\nruns not correct\n")
  print(wrong, row.names = FALSE)
}

# ---- which tools, in what order ------------------------------------------------
path <- vapply(runs, function(r) paste(vapply(r$calls, function(c) c$tool, ""), collapse = " > "), "")
used <- function(tool) vapply(runs, function(r) any(vapply(r$calls, function(c) identical(c$tool, tool), logical(1))), logical(1))
cat("\ncalls by tool and variant\n")
print(table(tool = unlist(lapply(runs, function(r) vapply(r$calls, function(c) c$tool, ""))),
            variant = rep(d$variant, d$tool_calls)))
cat(sprintf("\nvariant L runs that never called get_binding: %d of %d (correct: %d)\n",
            sum(d$variant == "L" & !used("get_binding")), sum(d$variant == "L"),
            sum(d$variant == "L" & !used("get_binding") & d$correct)))
cat(sprintf("variant M runs that never called to_data: %d of %d (correct: %d)\n",
            sum(d$variant == "M" & !used("to_data")), sum(d$variant == "M"),
            sum(d$variant == "M" & !used("to_data") & d$correct)))
cat(sprintf("range of calls in a run: L %d to %d, M %d to %d\n",
            min(d$tool_calls[d$variant == "L"]), max(d$tool_calls[d$variant == "L"]),
            min(d$tool_calls[d$variant == "M"]), max(d$tool_calls[d$variant == "M"])))
key <- paste(d$model, d$variant, d$question)
same <- vapply(split(path, key), function(p) length(unique(p)) == 1L, logical(1))
cat(sprintf("the two runs of one model, variant and question took the same path of tools in %d of %d pairs (temperature %s)\n",
            sum(same), length(same), format(a$meta$temperature)))
cat("\ndistinct paths, with the number of runs\n")
t <- sort(table(paste(d$variant, "|", path)), decreasing = TRUE)
for (i in seq_along(t)) cat(sprintf("%3d  %s\n", t[i], names(t)[i]))
