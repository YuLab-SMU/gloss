# P7 (2026-11-11): page-capture plan, Task 7. The six capture inputs of the
# tests on the page route, for the table of design §元素归属 (it showed the
# M0 engine route, with base through gridGraphics). Per input: engine, kind of
# page, leaves, elements with a leaf, elements without one, gloss's verdict
# (the captured page against the page drawn, primitives and clip regions),
# and whether the captured scene equals plain svglite's drawing of the input.
# 7 x 5 inches, dense = Inf, context = FALSE. One run each, after one warm-up.
#
# Host. Run from the repository root:
#   Rscript dev_docs/research/capture-fidelity/p7-six-inputs.R
suppressMessages(pkgload::load_all(".", quiet = TRUE, export_all = TRUE, helpers = FALSE))
source("tests/testthat/helper-figures.R")
ins <- six_inputs()
invisible(suppressWarnings(gloss(ins[[1]]$x, width = 7, height = 5, context = FALSE)))
cat(sprintf("%-12s | %-9s | %-4s | %6s | %9s | %7s | %-7s | %-11s | %s\n",
            "input", "engine", "page", "leaves", "with leaf", "unowned", "verdict", "= svglite", "seconds"))
for (nm in names(ins)) {
  t0 <- proc.time()[[3]]
  fig <- suppressWarnings(gloss(ins[[nm]]$x, width = 7, height = 5, context = FALSE, dense = Inf))
  secs <- proc.time()[[3]] - t0
  el <- fig$substrate$elements
  plain <- plain_svg(ins[[nm]]$draw, 7, 5)
  same <- identical(scene_signatures(fig$substrate$scene), scene_signatures(plain)) &&
    identical(clip_regions(fig$substrate$scene), clip_regions(plain))
  cat(sprintf("%-12s | %-9s | %-4s | %6d | %9d | %7d | %-7s | %-11s | %.2f\n", nm, fig$meta$engine, fig$meta$page$kind,
              nrow(fig$substrate$leaves), sum(!is.na(el$leaf)), sum(is.na(el$leaf)), fig$meta$page$verdict, same, secs))
}
