# gloss tour — the reproducible version of the Rho Notebook demo (2026-11-12).
# Run from the package root, with devtools, ggplot2 and svglite installed:
#   Rscript dev_docs/demo/gloss-tour.R
# or source() it in a live R session. dev_docs/ is not part of the build.
# Step 9 uses the M1 binding step, which is internal until ADR-0007.

gloss_tour <- function(write_bundles = TRUE) {
  suppressMessages(devtools::load_all(".", quiet = TRUE))
  library(ggplot2)

  p <- ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) +
    geom_point(size = 2.5) +
    facet_wrap(~am, labeller = label_both) +
    labs(title = "mtcars: weight vs mpg",
         subtitle = "a faceted ggplot, captured by gloss") +
    theme_bw()
  fig <- gloss(p, width = 8, height = 5)

  cat("== 1. what was captured ==\n")
  print(fig)

  el <- gl_elements(fig)
  circles <- el[el$tag == "circle", ]
  panel_of <- fig$substrate$leaves$path[match(circles$leaf, fig$substrate$leaves$id)]
  cat("== 2. the same SVG circle, two roles ==\n")
  cat("circles:", nrow(circles),
      "| data marks:", sum(grepl("panel-", panel_of)),
      "| legend keys:", sum(!grepl("panel-", panel_of)), "\n")

  hit <- gl_hit(fig, 2.62, 21, space = "data", panel = "panel2")
  dot <- hit[hit$tag == "circle", ][1, ]
  d <- gl_to_data(fig, "panel2", (dot$x0 + dot$x1) / 2, (dot$y0 + dot$y1) / 2)
  raw <- gl_table(fig, "raw")
  row <- raw[abs(raw$wt - d$x) < 0.01 & abs(raw$mpg - d$y) < 0.01 & raw$am == 1, ]
  cat("== 3. which car is that dot? ==\n")
  cat(dot$id, "->", rownames(row)[1],
      "| wt", row$wt, "mpg", row$mpg,
      "| leaf", dot$leaf, "| panel2\n")

  cat("== 4. geometry queries ==\n")
  cat("nearest:", paste(gl_near(fig, dot$id, k = 3, same_leaf = TRUE)$id, collapse = ", "),
      "| overlaps:", nrow(gl_overlap(fig, dot$id)), "\n")

  cat("== 5. tables, keys, context ==\n")
  print(gl_tables(fig)[, c("name", "nrow", "key", "key_rule")], row.names = FALSE)
  print(gl_context(fig)[, c("item", "found")], row.names = FALSE)

  base_draw <- function() {
    plot(mtcars$wt, mtcars$mpg, pch = 19, col = "#2b6cb0", main = "base graphics")
    abline(lm(mpg ~ wt, mtcars), col = "#c53030", lwd = 2)
  }
  cat("== 6. another engine: base graphics ==\n")
  base_fig <- gloss(base_draw, width = 7, height = 5)
  print(base_fig$substrate$leaves[, c("name", "n_expected", "n_drawn")], row.names = FALSE)

  if (write_bundles) {
    dir.create("dev_docs/demo", recursive = TRUE, showWarnings = FALSE)
    html <- "dev_docs/demo/mtcars-gloss.html"
    gl_write(fig, html, embed = "all")
    back <- gl_read(html)
    cat("== 7. bundle round trip ==\n")
    cat("elements / leaves / panels identical:",
        identical(gl_elements(back), gl_elements(fig)),
        identical(back$substrate$leaves, fig$substrate$leaves),
        identical(back$substrate$panels, fig$substrate$panels),
        "|", file.size(html), "bytes\n")
  }

  cat("== 8. plugins and contract ==\n")
  print(gl_test_plugin("engine", "ggplot"))

  cat("== 9. M1 binding (internal, not exported yet) ==\n")
  b <- gloss:::bind_capture(p, width = 8, height = 5)
  print(table(b$elements$status))
  print(b$elements[b$elements$element == dot$id, ], row.names = FALSE)

  invisible(list(fig = fig, binding = b))
}

gloss_tour()
