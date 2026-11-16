#!/usr/bin/env Rscript

# M3 mechanism fixture. It runs only deterministic table checks and a local
# ggplot projection. It does not use a model or a held-out figure set.

suppressPackageStartupMessages({
  pkgload::load_all(".", quiet = TRUE, export_all = FALSE, helpers = FALSE)
  if (!requireNamespace("ggplot2", quietly = TRUE)) stop("ggplot2 is required")
})

`%||%` <- function(a, b) if (is.null(a) || !length(a)) b else a
stamp <- "2026-11-16-m3"
out_dir <- file.path("bench", "runs", stamp)
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

d <- data.frame(
  group = rep(c("a", "b"), each = 3),
  x = c(1, 2, 3, 1, 2, 3),
  y = c(2, 4, 6, 9, 8, 7),
  label = c("ok", "ok", "ok", "other", "other", "other"),
  stringsAsFactors = FALSE
)

cases <- list(
  count_true = list(kind = "count", args = list(by = "group", equals = 3L), expected = "verified"),
  count_false = list(kind = "count", args = list(by = "group", equals = 2L), expected = "failed"),
  value_true = list(kind = "value", args = list(column = "label", value = "ok", row = 1L), expected = "verified"),
  value_false = list(kind = "value", args = list(column = "label", value = "wrong"), expected = "failed"),
  compare_true = list(kind = "compare", args = list(left = "y", right = "x", expect = "greater"), expected = "verified"),
  compare_false = list(kind = "compare", args = list(left = "x", right = "y", expect = "greater"), expected = "failed"),
  range_mixed = list(kind = "range", args = list(column = "x", min = 2), expected = "partial"),
  range_refused = list(kind = "range", args = list(column = "missing", min = 1), expected = "refused"),
  exists_true = list(kind = "exists", args = list(column = "label", value = "other"), expected = "verified"),
  exists_false = list(kind = "exists", args = list(column = "label", value = "absent"), expected = "failed")
)

check_rows <- lapply(names(cases), function(id) {
  x <- cases[[id]]
  out <- gl_check(d, x$kind, x$args)
  data.frame(
    id = id, kind = x$kind, expected = x$expected, status = out$status,
    passed = out$passed, correct = identical(out$status, x$expected),
    reason = out$reason %||% NA_character_, stringsAsFactors = FALSE
  )
})
checks <- do.call(rbind, check_rows)
write.csv(checks, file.path(out_dir, "checks.csv"), row.names = FALSE, na = "")

fig <- gloss(
  ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point(),
  context = FALSE
)
element <- fig$substrate$elements$id[1L]
claim <- list(
  text = "weight and fuel economy trend down together",
  check = list(kind = "trend", table = "built_layer1",
               args = list(response = "y", predictor = "x", expect = "negative"))
)
fig <- gl_record(fig, "claim", element, claim, by = "m3-fixture")
claim_id <- gl_records(fig, "claim")$id[1L]
projected <- gl_apply(fig, list(
  list(op = "select", target = element),
  list(op = "style", target = element, style = "highlight"),
  list(op = "overlay", target = element, kind = "leader",
       text = "verified claim", basis = claim_id),
  list(op = "tooltip", target = element, text = "verified claim")
))

scene <- gloss:::scene_with_operations(projected)
html_path <- file.path(out_dir, "fixture.html")
gl_write(projected, html_path)
aria <- gl_export(projected, "aria")
text_description <- gl_export(projected, "text")
annotation <- gl_export(projected, "annotation")
writeLines(aria, file.path(out_dir, "aria.json"), useBytes = TRUE)
writeLines(text_description, file.path(out_dir, "description.txt"), useBytes = TRUE)
writeLines(annotation, file.path(out_dir, "annotation.json"), useBytes = TRUE)

summary <- list(
  fixture = "mtcars-point",
  checks = list(total = nrow(checks), correct = sum(checks$correct),
                statuses = as.list(table(checks$status))),
  claim = list(status = gl_records(fig, "claim")$status[1L], id = claim_id),
  operation = list(count = length(projected$operations$specs),
                   data_attributes = grepl("data-gloss-element", scene, fixed = TRUE),
                   overlay = grepl("gloss-overlay", scene, fixed = TRUE),
                   tooltip = grepl("data-gloss-tooltip", scene, fixed = TRUE),
                   substrate_unchanged = identical(fig$substrate$scene, projected$substrate$scene)),
  outputs = list(html_bytes = file.size(html_path), aria_bytes = file.size(file.path(out_dir, "aria.json")),
                 text_bytes = file.size(file.path(out_dir, "description.txt")),
                 annotation_bytes = file.size(file.path(out_dir, "annotation.json")))
)
jsonlite::write_json(summary, file.path(out_dir, "summary.json"), auto_unbox = TRUE, pretty = TRUE)
writeLines(c(
  sprintf("M3 mechanism fixture: %d/%d check cases matched expected status.", sum(checks$correct), nrow(checks)),
  sprintf("claim status: %s", summary$claim$status),
  sprintf("operations: %d, overlay: %s, tooltip: %s, substrate unchanged: %s",
          summary$operation$count, summary$operation$overlay, summary$operation$tooltip,
          summary$operation$substrate_unchanged),
  sprintf("HTML bytes: %d, ARIA bytes: %d, text bytes: %d, annotation bytes: %d",
          summary$outputs$html_bytes, summary$outputs$aria_bytes,
          summary$outputs$text_bytes, summary$outputs$annotation_bytes)
), file.path(out_dir, "README.txt"))

print(checks, row.names = FALSE)
print(summary)
