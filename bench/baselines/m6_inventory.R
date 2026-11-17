#!/usr/bin/env Rscript

# M6 engineering-baseline inventory. Comparison packages stay outside the
# package dependency graph. A baseline is counted only when its own package
# and source-level integration are available; every other row carries a reason.

out_dir <- file.path("bench", "runs", "m6-baselines")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
ids <- c("gallery-005", "gallery-029", "exts-030", "bioc-016", "patchwork-006", "tree-062",
         "gallery-016", "gallery-033", "gallery-060", "patchwork-014", "tree-001", "gallery-064")
sets <- c(rep("dev", 6L), rep("heldout", 6L))
tools <- c("ggiraph", "gridSVG", "maidR", "plotly")
patterns <- list(
  ggiraph = "girafe\\s*\\(|geom_[A-Za-z0-9_]*_interactive",
  gridSVG = "gridSVG|grid\\.export|grid\\.to\\.SVG",
  maidR = "maidR|maidr",
  plotly = "plotly|ggplotly|plot_ly|plotly_build"
)

rows <- list()
for (i in seq_along(ids)) {
  id <- ids[i]
  code <- paste(readLines(file.path("bench", "figures", id, "code.R"), warn = FALSE), collapse = "\n")
  for (tool in tools) {
    pkg <- if (identical(tool, "maidR")) "maidr" else tool
    installed <- requireNamespace(pkg, quietly = TRUE)
    integration <- grepl(patterns[[tool]], code, ignore.case = TRUE, perl = TRUE)
    status <- if (!installed) "unavailable" else if (!integration) "not_applicable" else "candidate"
    reason <- if (!installed) paste0("package ", pkg, " is not installed in this environment") else
      if (!integration) "frozen figure code has no baseline-specific integration" else
        "source contains a baseline-specific call; adapter run is queued"
    rows[[length(rows) + 1L]] <- data.frame(
      set = sets[i], figure = id, tool = tool, package = pkg,
      package_version = if (installed) as.character(utils::packageVersion(pkg)) else NA_character_,
      integration = integration, status = status, reason = reason,
      stringsAsFactors = FALSE
    )
  }
}
result <- do.call(rbind, rows)
stamp <- format(Sys.time(), "%Y-%m-%d-%H%M", tz = "UTC")
csv <- file.path(out_dir, paste0(stamp, "-inventory.csv"))
utils::write.csv(result, csv, row.names = FALSE, na = "")
summary <- list(
  figures = length(ids), tools = tools, rows = nrow(result),
  statuses = as.list(table(result$tool, result$status)),
  runnable_candidates = sum(result$status == "candidate"),
  unavailable = sum(result$status == "unavailable"),
  csv = csv
)
jsonlite::write_json(summary, sub("[.]csv$", "-summary.json", csv), auto_unbox = TRUE, pretty = TRUE)
print(summary)
