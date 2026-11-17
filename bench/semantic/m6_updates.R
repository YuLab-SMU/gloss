#!/usr/bin/env Rscript

# M6 controlled update and selector ablation. This is a deterministic
# development fixture; it never calls a model and treats missing/ambiguous
# targets as outcomes rather than silently repairing them.

source("bench/R/runner.R")
.libPaths(unique(c(bench_libpaths(), .libPaths())))
suppressMessages(pkgload::load_all(".", quiet = TRUE, export_all = FALSE, helpers = FALSE))
if (!requireNamespace("ggplot2", quietly = TRUE)) stop("ggplot2 is required")
`%||%` <- function(a, b) if (is.null(a) || !length(a)) b else a

out_dir <- file.path("bench", "runs", "m6-updates")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

base_plot <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
  ggplot2::geom_point() + ggplot2::geom_smooth(method = "lm", se = FALSE)
base <- gloss::gloss(base_plot, context = FALSE)
bindings <- gloss::gl_bindings(base)
verified <- bindings[bindings$status == "verified" & !is.na(bindings$row), , drop = FALSE]
if (!nrow(verified)) stop("the update fixture has no verified binding")
binding <- verified[1L, , drop = FALSE]
element_id <- as.character(binding$element[1L])
table_name <- as.character(binding$table[1L])
row_number <- as.integer(binding$row[1L])
table_data <- gloss::gl_table(base, table_name)
key_names <- gloss::gl_tables(base)$key[match(table_name, gloss::gl_tables(base)$name)]
key_names <- strsplit(key_names, " + ", fixed = TRUE)[[1L]]
key_values <- as.list(table_data[row_number, key_names, drop = FALSE])
names(key_values) <- key_names

anchors <- list(
  element_id = gloss::gl_anchor(element_id),
  data_key = gloss::gl_anchor(data_key = list(table = table_name, key = key_values)),
  multi_selector = list(selectors = list(
    list(type = "element_id", id = element_id),
    list(type = "data_key", table = table_name, key = key_values)
  ))
)

updates <- list()
for (i in 1:5) {
  updates[[paste0("title-", i)]] <- base_plot + ggplot2::labs(title = paste("title", i))
  updates[[paste0("colour-", i)]] <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
    ggplot2::geom_point(colour = c("red", "blue", "darkgreen", "purple", "orange")[i]) +
    ggplot2::geom_smooth(method = "lm", se = FALSE)
  keep <- switch(as.character(i),
    `1` = mtcars$cyl != 6,
    `2` = mtcars$am == 1,
    `3` = mtcars$hp > 100,
    `4` = mtcars$wt < 4,
    `5` = mtcars$mpg > 20
  )
  updates[[paste0("data-subset-", i)]] <- ggplot2::ggplot(mtcars[keep, , drop = FALSE], ggplot2::aes(wt, mpg)) +
    ggplot2::geom_point() + ggplot2::geom_smooth(method = "lm", se = FALSE)
  updates[[paste0("add-layer-", i)]] <- base_plot + ggplot2::geom_text(
    data = mtcars[i, , drop = FALSE], ggplot2::aes(label = row.names(mtcars)[i]), vjust = -1
  )
  updates[[paste0("delete-layer-", i)]] <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
    if (i %% 2L == 1L) ggplot2::geom_point() else ggplot2::geom_smooth(method = "lm", se = FALSE)
}

rows <- list()
for (update_name in names(updates)) {
  edited <- suppressWarnings(gloss::gloss(updates[[update_name]], context = FALSE))
  update_type <- sub("-[0-9]+$", "", update_name)
  for (selector_name in names(anchors)) {
    anchor <- anchors[[selector_name]]
    resolution <- tryCatch(gloss::gl_resolve_anchor(edited, anchor), error = function(e) list(status = "error", reason = conditionMessage(e)))
    target <- as.character(resolution$target %||% character())
    silent <- identical(resolution$status, "unique") && length(target) == 1L && !identical(target, element_id)
    rebased <- tryCatch(gloss::gl_rebase(gloss::gl_record(base, "meaning", anchor,
                                                          list(text = paste(update_name, selector_name)), by = "m6"),
                                         updates[[update_name]]), error = function(e) e)
    rebase_status <- if (inherits(rebased, "error")) "error" else {
      rr <- gloss::gl_records(rebased, "meaning")
      if (!nrow(rr)) "missing_record" else paste(unique(rr$status), collapse = "|")
    }
    rows[[length(rows) + 1L]] <- data.frame(
      update = update_name, update_type = update_type, selector = selector_name,
      resolution = resolution$status %||% "error", target = paste(target, collapse = "|"),
      same_target = identical(resolution$status, "unique") && identical(target, element_id),
      silent_misattachment = silent, rebase_status = rebase_status,
      stringsAsFactors = FALSE
    )
  }
}
result <- do.call(rbind, rows)
stamp <- format(Sys.time(), "%Y-%m-%d-%H%M", tz = "UTC")
csv <- file.path(out_dir, paste0(stamp, "-selector-ablation.csv"))
utils::write.csv(result, csv, row.names = FALSE, na = "")
summary <- list(
  updates = length(updates), selectors = length(anchors), attempts = nrow(result),
  unique = sum(result$resolution == "unique"),
  ambiguous = sum(result$resolution == "ambiguous"),
  missing = sum(result$resolution == "missing"),
  silent_misattachments = sum(result$silent_misattachment),
  silent_misattachments_by_selector = as.list(table(result$selector[result$silent_misattachment])),
  multi_selector_silent_misattachments = sum(result$silent_misattachment & result$selector == "multi_selector"),
  same_target = sum(result$same_target),
  rebase_errors = sum(result$rebase_status == "error"),
  by_update = as.list(table(result$update_type, result$selector)),
  csv = csv
)
jsonlite::write_json(summary, sub("[.]csv$", "-summary.json", csv), auto_unbox = TRUE, pretty = TRUE)
print(summary)
if (summary$multi_selector_silent_misattachments > 0L || summary$rebase_errors > 0L) quit(status = 2L)
