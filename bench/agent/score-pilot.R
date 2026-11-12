# Score the pilot (agent-path plan 2026-11-12, Task 5) from its archives:
#   Rscript bench/agent/score-pilot.R <stamp> [bench/runs/<stamp>-pilot-enumerate.csv]
# Reads bench/runs/<stamp>-pilot-*.jsonl (one file per model, or the
# rehearsal's) and, when given, the enumeration's table. Calls no model.
#
# A run is one model, arm, question and repeat. A run that ended in a request
# error was made again once (pilot.R); the attempt scored is the one without
# an error when there is one, else the last. Shares are given per figure and
# per model before any pooled number.

args <- commandArgs(trailingOnly = TRUE)
if (!length(args)) stop("usage: Rscript bench/agent/score-pilot.R <stamp> [enumerate.csv]")
stamp <- args[1]
files <- Sys.glob(file.path("bench", "runs", paste0(stamp, "-pilot-*.jsonl")))
if (!length(files)) stop("no archive bench/runs/", stamp, "-pilot-*.jsonl")
recs <- unlist(lapply(files, function(f) lapply(readLines(f, warn = FALSE), jsonlite::fromJSON, simplifyVector = FALSE)),
               recursive = FALSE)
metas <- Filter(function(r) isTRUE(r$meta), recs)
runs <- Filter(function(r) !isTRUE(r$meta), recs)
get <- function(r, name, type) {
  v <- r[[name]]
  if (is.null(v)) methods::as(NA, type) else methods::as(v, type)
}
col <- function(name, type) vapply(runs, get, methods::as(NA, type), name = name, type = type)
d <- data.frame(
  model = sub("^westlakehpc/", "", col("model", "character")), arm = col("arm", "character"),
  figure = col("figure", "character"), question = col("question", "integer"), rep = col("rep", "integer"),
  attempt = col("attempt", "integer"), error = !is.na(col("error", "character")),
  answered = col("answered", "logical"), correct = col("correct", "logical"),
  answer_table = col("answer_table", "character"), answer_row = col("answer_row", "integer"),
  truth_table = col("truth_table", "character"), truth_row = col("truth_row", "integer"),
  submissions = col("submissions", "integer"), wrong_accepted = col("wrong_accepted", "integer"),
  rejected = col("rejected", "integer"), refused = col("refused", "integer"),
  first_outcome = col("first_outcome", "character"), other_element = col("other_element", "integer"),
  tool_calls = col("tool_calls", "integer"), failed_calls = col("failed_calls", "integer"),
  steps = col("steps", "integer"), finish = col("finish", "character"), seconds = col("seconds", "numeric"),
  tokens = vapply(runs, function(r) { v <- r$usage$total_tokens; if (is.null(v)) NA_real_ else as.numeric(v) }, 1),
  stringsAsFactors = FALSE)
d$attempt[is.na(d$attempt)] <- 1L
all_attempts <- nrow(d)
request_errors <- sum(d$error)
# one attempt a run: the one without an error if there is one, else the last
key <- paste(d$model, d$arm, d$figure, d$question, d$rep)
keep <- unlist(lapply(split(seq_len(nrow(d)), key), function(i) {
  ok <- i[!d$error[i]]
  if (length(ok)) ok[length(ok)] else i[length(i)]
}))
d <- d[sort(keep), ]
max_steps <- metas[[1]]$max_steps

cat(sprintf("%s | %d runs (%d attempts archived, %d ended in a request error) | models: %s | gloss %s | aisdk %s\n\n", stamp, nrow(d),
            all_attempts, request_errors, paste(unique(d$model), collapse = ", "),
            paste(unique(vapply(metas, function(m) m$gloss_commit, "")), collapse = ", "),
            paste(unique(vapply(metas, function(m) m$aisdk, "")), collapse = ", ")))
frac <- function(k, n) sprintf("%d/%d", k, n)
tab <- function(by) {
  g <- split(d, by, drop = TRUE)
  do.call(rbind, lapply(names(g), function(n) {
    x <- g[[n]]
    data.frame(group = n, runs = nrow(x), correct = sum(x$correct), wrong = sum(x$answered & !x$correct),
               no_answer = sum(!x$answered), request_error = sum(x$error), stringsAsFactors = FALSE)
  }))
}

cat("runs by arm: correct, answered wrongly, no answer\n")
print(tab(d$arm), row.names = FALSE)
cat("\nby model and arm\n")
print(tab(paste(d$model, d$arm)), row.names = FALSE)

cat("\nby figure: correct runs of runs, each arm, all models; then each model\n")
figs <- sort(unique(d$figure))
per <- data.frame(figure = figs, questions = vapply(figs, function(f) length(unique(d$question[d$figure == f])), 1L))
cell <- function(f, a, m = NULL) {
  x <- d[d$figure == f & d$arm == a & (if (is.null(m)) TRUE else d$model == m), ]
  if (nrow(x)) frac(sum(x$correct), nrow(x)) else "-"
}
for (a in sort(unique(d$arm))) per[[a]] <- vapply(figs, cell, "", a = a)
for (m in unique(d$model)) for (a in sort(unique(d$arm))) per[[paste(substr(m, 1, 8), a)]] <- vapply(figs, cell, "", a = a, m = m)
print(per, row.names = FALSE)

# the same question in both arms: the share of its runs that are right
if (all(c("A", "B") %in% d$arm)) {
  qk <- paste(d$figure, d$question)
  share <- function(a) tapply(d$correct[d$arm == a], qk[d$arm == a], mean)
  sa <- share("A")
  sb <- share("B")[names(sa)]
  cat(sprintf("\nquestions (%d), by the share of their runs that are right: B above A in %d, A above B in %d, equal in %d (both all right: %d, both all wrong: %d)\n",
              length(sa), sum(sb > sa), sum(sa > sb), sum(sa == sb), sum(sa == 1 & sb == 1), sum(sa == 0 & sb == 0)))
  fa <- tapply(d$correct[d$arm == "A"], d$figure[d$arm == "A"], mean)
  fb <- tapply(d$correct[d$arm == "B"], d$figure[d$arm == "B"], mean)[names(fa)]
  cat(sprintf("figures (%d), by the same share: B above A in %d, A above B in %d, equal in %d; mean over figures A %.3f, B %.3f\n",
              length(fa), sum(fb > fa), sum(fa > fb), sum(fa == fb), mean(fa), mean(fb)))
}

b <- d[d$arm == "B", ]
if (nrow(b)) {
  cat(sprintf("\narm B, %d runs: first proposal %s; no proposal at all in %d\n", nrow(b),
              paste(names(table(b$first_outcome)), table(b$first_outcome), collapse = ", "), sum(is.na(b$first_outcome))))
  cat(sprintf("  runs with a rejected proposal: %d, of which %d ended right; proposals refused: %d in %d runs\n",
              sum(b$rejected > 0), sum(b$rejected > 0 & b$correct), sum(b$refused), sum(b$refused > 0)))
  cat(sprintf("  wrong acceptances (accepted for the element asked about, and not the answer): %d in %d runs; accepted for another element: %d in %d runs\n",
              sum(b$wrong_accepted), sum(b$wrong_accepted > 0), sum(b$other_element), sum(b$other_element > 0)))
}
a <- d[d$arm == "A", ]
if (nrow(a)) {
  wrong <- a[a$answered & !a$correct, ]
  cat(sprintf("\narm A, %d runs: submissions in a run %s; wrong answers %d (another table: %d; the table, another row: %d)\n", nrow(a),
              paste(names(table(a$submissions)), table(a$submissions), collapse = ", "), nrow(wrong),
              sum(wrong$answer_table != wrong$truth_table), sum(wrong$answer_table == wrong$truth_table)))
}

cat(sprintf("\nwhat the runs used (median; the limit on steps is %s)\n", format(max_steps)))
used <- do.call(rbind, lapply(split(d, paste(d$model, d$arm)), function(x) {
  data.frame(model = x$model[1], arm = x$arm[1], runs = nrow(x), calls = stats::median(x$tool_calls),
             failed_calls = sum(x$failed_calls), steps = stats::median(x$steps, na.rm = TRUE),
             at_step_limit = sum(x$steps >= max_steps, na.rm = TRUE), seconds = round(stats::median(x$seconds), 1),
             seconds_max = round(max(x$seconds), 1), tokens = round(stats::median(x$tokens, na.rm = TRUE)))
}))
print(used, row.names = FALSE)
cat(sprintf("total time of the runs: %.1f min (A %.1f, B %.1f)\n", sum(d$seconds) / 60, sum(d$seconds[d$arm == "A"]) / 60,
            sum(d$seconds[d$arm == "B"]) / 60))

bad <- d[!d$correct, c("model", "arm", "figure", "question", "rep", "answered", "answer_table", "answer_row", "truth_table",
                       "truth_row", "tool_calls", "steps", "error")]
if (nrow(bad)) {
  cat("\nruns not right\n")
  print(bad[order(bad$figure, bad$question, bad$arm, bad$model), ], row.names = FALSE)
}

if (length(args) > 1) {
  s <- utils::read.csv(args[2], stringsAsFactors = FALSE)
  cat(sprintf("\narm S (no model), %s: %d questions; right (the answer accepted and nothing else) %d; the answer accepted %d; questions with another row accepted %d; with a refusal %d; rows tried %d, median %.1f s a question\n",
              basename(args[2]), nrow(s), sum(s$correct), sum(s$truth_accepted), sum(s$wrong_accepted > 0), sum(s$refused > 0),
              sum(s$tried), stats::median(s$seconds)))
  print(do.call(rbind, lapply(split(s, s$figure), function(x) {
    data.frame(figure = x$figure[1], questions = nrow(x), right = sum(x$correct), answer_accepted = sum(x$truth_accepted),
               others_accepted = sum(x$wrong_accepted), refused = sum(x$refused), tried = sum(x$tried))
  })), row.names = FALSE)
}
