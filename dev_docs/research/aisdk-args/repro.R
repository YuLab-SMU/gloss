# What aisdk does to a tool call's arguments before the tool sees them.
#   Rscript dev_docs/research/aisdk-args/repro.R > dev_docs/research/aisdk-args/repro.out
# Needs aisdk and jsonlite; calls no model and nothing of gloss.
#
# Found 2026-11-12 in the rehearsal of the agent-path pilot: R code a model
# wrote as `d[i, ]` reached a sandbox tool as `d[i]` (dev log
# 2026-11-12-agent-path-task3). parse_tool_arguments() runs
# repair_json_string() on the arguments first and parses the result; the
# arguments as given are tried only when the repaired text does not parse.
# The repair is a set of regular expressions over the whole JSON text, so
# it also rewrites the inside of string values.

cat("aisdk", as.character(utils::packageVersion("aisdk")), "\n\n")
parse_args <- utils::getFromNamespace("parse_tool_arguments", "aisdk")
try_it <- function(label, value) {
  json <- as.character(jsonlite::toJSON(list(code = value), auto_unbox = TRUE))
  strict <- jsonlite::fromJSON(json, simplifyVector = FALSE)$code
  got <- parse_args(json)$code
  cat(sprintf("%s\n  sent     : %s\n  received : %s\n  %s\n\n", label, value, if (is.null(got)) "<no such argument>" else got,
              if (identical(got, value)) "unchanged" else "CHANGED (jsonlite alone gives the text back unchanged: " |>
                paste0(identical(strict, value), ")")))
  identical(got, value)
}
same <- c(
  try_it("a data frame's rows", "print(d[2:3, ])"),
  try_it("an empty column index", "m <- x[order(x$a), ]"),
  try_it("a trailing comma before a brace, as in text or JSON inside a string", "the set {a, b, } is written so"),
  try_it("a single-quoted name before a colon", "x <- c('a': 1)"),
  try_it("a name after a comma, before a colon", "f(x, y: z)"),
  try_it("plain text", "which row does the circle draw?"),
  try_it("an element id", "e28")
)
cat(sprintf("%d of %d valid arguments reach the tool unchanged\n", sum(same), length(same)))
cat("\nthe step that changes them (aisdk:::repair_json_string), on the first:\n")
cat(" ", utils::getFromNamespace("repair_json_string", "aisdk")('{"code":"print(d[2:3, ])"}'), "\n")
