#!/usr/bin/env Rscript

# Offline semantic pilot. It compares a deterministic code proposal with a
# frozen set of model-shaped proposals. Every claim with a closed check goes
# through gloss::gl_check(); claims without a check, or checks that cannot run,
# become targeted audit candidates. This script makes no model or network call.

suppressPackageStartupMessages({
  pkgload::load_all(".", quiet = TRUE, export_all = FALSE, helpers = FALSE)
  if (!requireNamespace("ggplot2", quietly = TRUE)) stop("ggplot2 is required")
})

args <- commandArgs(trailingOnly = TRUE)
dry <- "--dry" %in% args
out_arg <- args[startsWith(args, "--out=")]
out_base <- if (length(out_arg)) sub("^--out=", "", out_arg[1]) else NULL
`%||%` <- function(a, b) if (is.null(a) || !length(a)) b else a

proposal_path <- file.path("bench", "semantic", "proposals.csv")
proposals <- utils::read.csv(proposal_path, stringsAsFactors = FALSE, na.strings = "")
required <- c("id", "source", "layer", "text", "table", "check_kind", "response",
              "predictor", "by", "expect", "audit_question")
stopifnot(identical(names(proposals), required))
stopifnot(!anyDuplicated(proposals$id), all(proposals$source %in% c("code", "model")))

p <- ggplot2::ggplot(
  mtcars,
  ggplot2::aes(wt, mpg, colour = factor(cyl))
) + ggplot2::geom_point() + ggplot2::facet_wrap(~am)
points <- ggplot2::ggplot_build(p)$data[[1]]
tables <- list(
  points = points,
  points_g3 = points[points$group == 3, , drop = FALSE]
)

split_by <- function(x) {
  if (is.na(x) || !nzchar(x)) character() else strsplit(x, "|", fixed = TRUE)[[1]]
}

proposal_check <- function(row) {
  if (row$layer != "claim" || is.na(row$check_kind) || !nzchar(row$check_kind)) {
    return(list(status = "uncheckable", passed = NA, reason = "no closed check was supplied",
                groups = NULL, needs_audit = TRUE))
  }
  if (!row$table %in% names(tables)) {
    return(list(status = "refused", passed = NA,
                reason = sprintf("no built table '%s' in the fixture", row$table),
                groups = NULL, needs_audit = TRUE))
  }
  check_args <- list(
    response = row$response,
    predictor = row$predictor,
    by = split_by(row$by),
    expect = row$expect
  )
  check_args <- check_args[!vapply(check_args, function(x) length(x) == 0L, logical(1))]
  result <- tryCatch(
    gloss::gl_check(tables[[row$table]], row$check_kind, check_args),
    error = function(e) list(status = "refused", passed = NA,
                              reason = conditionMessage(e), groups = NULL)
  )
  status <- result$status
  list(
    status = status,
    passed = result$passed,
    reason = result$reason %||% NA_character_,
    groups = result$groups,
    needs_audit = status %in% c("partial", "refused")
  )
}

runs <- lapply(seq_len(nrow(proposals)), function(i) {
  row <- proposals[i, , drop = FALSE]
  checked <- proposal_check(row)
  list(
    id = row$id,
    source = row$source,
    layer = row$layer,
    text = row$text,
    table = row$table,
    check_kind = if (nzchar(row$check_kind)) row$check_kind else NA_character_,
    status = checked$status,
    passed = checked$passed,
    needs_audit = checked$needs_audit,
    reason = checked$reason,
    audit_question = if (nzchar(row$audit_question)) row$audit_question else NA_character_,
    groups = checked$groups
  )
})

flat <- do.call(rbind, lapply(runs, function(x) {
  data.frame(
    id = x$id, source = x$source, layer = x$layer, table = x$table,
    status = x$status, passed = x$passed, needs_audit = x$needs_audit,
    reason = x$reason, audit_question = x$audit_question,
    evidence = if (is.data.frame(x$groups)) {
      jsonlite::toJSON(x$groups, auto_unbox = TRUE, na = "null")
    } else {
      NA_character_
    },
    stringsAsFactors = FALSE
  )
}))
audit <- flat[flat$needs_audit, c("id", "source", "layer", "status", "reason", "audit_question", "evidence"),
              drop = FALSE]

cat(sprintf("semantic pilot: %d proposals (%d code, %d model-shaped)\n",
            nrow(flat), sum(flat$source == "code"), sum(flat$source == "model")))
for (source in unique(flat$source)) {
  sub <- flat[flat$source == source, , drop = FALSE]
  counts <- table(factor(sub$status, levels = c("verified", "failed", "partial", "refused", "uncheckable")))
  cat(sprintf("  %s: verified %d, failed %d, partial %d, refused %d, uncheckable %d\n",
              source, counts[["verified"]], counts[["failed"]], counts[["partial"]],
              counts[["refused"]], counts[["uncheckable"]]))
}
cat(sprintf("  targeted audit queue: %d case%s\n", nrow(audit), if (nrow(audit) == 1L) "" else "s"))
print(flat[, c("id", "source", "status", "needs_audit")], row.names = FALSE)
if (nrow(audit)) print(audit, row.names = FALSE)

if (!is.null(out_base) && !dry) {
  dir.create(dirname(out_base), recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(flat, paste0(out_base, ".csv"), row.names = FALSE, na = "")
  utils::write.csv(audit, paste0(out_base, "-audit.csv"), row.names = FALSE, na = "")
  json <- list(
    fixture = list(name = "mtcars-facet-points", tables = names(tables),
                   rows = vapply(tables, nrow, integer(1))),
    proposals = runs,
    audit_queue = split(audit, seq_len(nrow(audit)))
  )
  jsonlite::write_json(json, paste0(out_base, ".json"), auto_unbox = TRUE,
                       pretty = TRUE, na = "null")
  cat("archived:", paste0(out_base, c(".csv", "-audit.csv", ".json")), "\n")
}
