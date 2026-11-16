# Deterministic M2 rebase measurement on a hand-built ggplot fixture.
# Run from the repository root with:
#   Rscript bench/m2/rebase.R

if (!requireNamespace("ggplot2", quietly = TRUE)) stop("ggplot2 is required")
if (!requireNamespace("devtools", quietly = TRUE)) stop("devtools is required")
devtools::load_all(quiet = TRUE)

point_plot <- function() {
  ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, colour = factor(cyl))) +
    ggplot2::geom_point()
}

point_smooth_plot <- function() {
  point_plot() + ggplot2::geom_smooth(method = "lm", se = FALSE)
}

make_fixture <- function(p) {
  fig <- gloss(p, context = FALSE)
  b <- gl_bindings(fig)
  b <- b[b$status == "verified" & b$table == "built_layer1", , drop = FALSE]
  first <- b$element[1L]
  row2 <- b$row[2L]
  tab <- b$table[1L]
  vals <- as.list(fig$tables[[tab]]$data[row2, fig$tables[[tab]]$key, drop = FALSE])
  names(vals) <- fig$tables[[tab]]$key
  el <- fig$substrate$elements
  leaf <- el$leaf[match(first, el$id)]
  ordinal <- el$ordinal[match(first, el$id)]
  e <- el[match(first, el$id), , drop = FALSE]
  anchors <- list(
    element_id = gl_anchor(element = first),
    data_key = gl_anchor(data_key = list(table = tab, key = vals)),
    structure_path = gl_anchor(structure_path = list(leaf = leaf, ordinal = ordinal)),
    region = gl_anchor(region = list(panel = fig$substrate$leaves$panel[match(leaf, fig$substrate$leaves$id)],
                                     x = c(e$x0 - 0.01, e$x1 + 0.01),
                                     y = c(e$y0 - 0.01, e$y1 + 0.01)))
  )
  for (a in anchors) fig <- gl_record(fig, "meaning", a, list(text = "fixture"), by = "m2-fixture")
  fig
}

measure <- function(name, original, edited) {
  fig <- make_fixture(original)
  out <- gl_rebase(fig, edited)
  st <- gl_status(out)
  data.frame(
    variant = name, records = nrow(st), auto_hit = sum(st$status != "invalid"),
    invalid = sum(st$status == "invalid"), ambiguous = sum(st$anchor_status == "ambiguous"),
    hit_rate = sum(st$status != "invalid") / nrow(st), stringsAsFactors = FALSE
  )
}

rows <- rbind(
  measure("title", point_plot(), point_plot() + ggplot2::labs(title = "edited")),
  measure("colour", point_plot(), ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, colour = factor(cyl))) +
    ggplot2::geom_point(size = 3)),
  measure("data_subset", point_plot(), ggplot2::ggplot(mtcars[-1, ], ggplot2::aes(wt, mpg, colour = factor(cyl))) +
    ggplot2::geom_point()),
  measure("add_layer", point_plot(), point_plot() + ggplot2::geom_smooth(method = "lm", se = FALSE)),
  measure("delete_layer", point_smooth_plot(), point_plot())
)

stamp <- "2026-11-15-m2-rebase"
dir.create(file.path("bench", "runs", stamp), recursive = TRUE, showWarnings = FALSE)
write.csv(rows, file.path("bench", "runs", stamp, "summary.csv"), row.names = FALSE)
writeLines(c(
  "M2 rebase fixture: five controlled edits, four anchor forms plus add/delete layer.",
  paste(capture.output(print(rows)), collapse = "\n")
), file.path("bench", "runs", stamp, "README.txt"))
print(rows)
