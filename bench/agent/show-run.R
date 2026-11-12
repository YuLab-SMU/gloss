# Print the transcript of archived pilot runs (agent-path plan 2026-11-12, Task 5):
#   Rscript bench/agent/show-run.R <stamp> [model=<part of id>] [arm=A|B] [figure=<id>] [question=<n>] [rep=<n>]
#                                  [only=wrong|noanswer|notright|right] [width=<characters of each result>] [max=<runs>]
# Reads bench/runs/<stamp>-pilot-*.jsonl. Calls no model and scores nothing:
# it shows what a run sent to its tools and what they answered, which is read
# before a share from score-pilot.R is believed.

args <- commandArgs(trailingOnly = TRUE)
if (!length(args)) stop("usage: Rscript bench/agent/show-run.R <stamp> [model=] [arm=] [figure=] [question=] [rep=] [only=] [width=] [max=]")
stamp <- args[1]
opt <- function(name, default = NULL) {
  hit <- grep(paste0("^", name, "="), args[-1], value = TRUE)
  if (length(hit)) sub(paste0("^", name, "="), "", hit[1]) else default
}
`%||%` <- function(a, b) if (is.null(a) || !length(a)) b else a
files <- Sys.glob(file.path("bench", "runs", paste0(stamp, "-pilot-*.jsonl")))
if (!length(files)) stop("no archive bench/runs/", stamp, "-pilot-*.jsonl")
recs <- unlist(lapply(files, function(f) lapply(readLines(f, warn = FALSE), jsonlite::fromJSON, simplifyVector = FALSE)),
               recursive = FALSE)
runs <- Filter(function(r) !isTRUE(r$meta), recs)

state <- function(r) if (isTRUE(r$correct)) "right" else if (isTRUE(r$answered)) "wrong" else "noanswer"
want <- function(r) {
  only <- opt("only")
  (is.null(opt("model")) || grepl(opt("model"), r$model, fixed = TRUE)) &&
    (is.null(opt("arm")) || identical(r$arm, opt("arm"))) &&
    (is.null(opt("figure")) || identical(r$figure, opt("figure"))) &&
    (is.null(opt("question")) || identical(as.integer(r$question), as.integer(opt("question")))) &&
    (is.null(opt("rep")) || identical(as.integer(r$rep), as.integer(opt("rep")))) &&
    (is.null(only) || identical(state(r), only) || (only == "notright" && state(r) != "right"))
}
shown <- Filter(want, runs)
width <- as.integer(opt("width", "600"))
most <- as.integer(opt("max", "20"))
cat(sprintf("%d of %d runs match%s\n", length(shown), length(runs),
            if (length(shown) > most) sprintf("; the first %d are shown", most) else ""))

clip <- function(text, n) {
  text <- paste(as.character(unlist(text)), collapse = " ")
  if (nchar(text) <= n) return(text)
  paste0(substr(text, 1L, floor(n * 2 / 3)), sprintf(" [... %d characters ...] ", nchar(text) - n),
         substr(text, nchar(text) - (n - floor(n * 2 / 3)) + 1L, nchar(text)))
}
for (r in utils::head(shown, most)) {
  cat(sprintf("\n==== %s  arm %s  %s q%s r%s  %s | answer %s:%s, the answer is %s:%s | %s calls, %s requests, %.0f s, ended: %s%s\n",
              sub("^westlakehpc/", "", r$model), r$arm, r$figure, r$question, r$rep, toupper(state(r)),
              r$answer_table %||% "-", r$answer_row %||% "-", r$truth_table, r$truth_row,
              r$tool_calls, r$steps %||% "?", r$seconds, r$finish %||% "?",
              if (is.null(r$error)) "" else paste0(" | request error: ", clip(r$error, 120))))
  for (i in seq_along(r$calls)) {
    cl <- r$calls[[i]]
    a <- cl$args
    sent <- if (!is.null(a$code)) paste0("\n", paste0("      | ", strsplit(as.character(a$code), "\n", fixed = TRUE)[[1]], collapse = "\n"))
            else paste0(" ", as.character(jsonlite::toJSON(a, auto_unbox = TRUE, null = "null")))
    cat(sprintf("  %2d %s %s%s%s\n", i, if (isTRUE(cl$ok)) "ok  " else "FAIL", cl$tool, sent,
                if (isTRUE(cl$timed_out)) "  [timed out]" else if (isTRUE(cl$killed)) "  [killed]" else ""))
    cat("      -> ", gsub("\n", "\n         ", clip(cl$result, width), fixed = TRUE), "\n", sep = "")
  }
  if (nzchar(r$text %||% "")) cat("  last words: ", clip(r$text, width), "\n", sep = "")
}
