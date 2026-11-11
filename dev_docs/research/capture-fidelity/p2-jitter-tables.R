# P2 (2026-11-11): page-capture plan, Task 2, first measurement (assumption 1).
# With print(x) drawing the page, the ggplot engine's tables come from another
# build than the drawn one. Does the built table still describe the page when
# the build draws random numbers (position_jitter() without a seed)?
#
# For each rule the figure is captured by the package and every row of
# built_layer1, mapped through the panel's scales, is compared with the centre
# of the circle drawn for it (rows and circles in the same order; tolerance
# 0.011 pt, the SVG's printed precision of 0.01 pt plus rounding).
#
#   separate build  the engine builds in prepare(), print() builds again
#                   (the package after Task 1)
#   same RNG state  the engine builds from the random state print() starts
#                   with (built, then .Random.seed restored before print())
#   engine draws    the engine draws the gtable of its own build: the steps of
#                   ggplot2's print method without set_last_plot()
#
# Ran at 19f39d7 (after Task 1, before the table rule of Task 2); the
# "separate build" variant reuses that commit's prepare(), which built.
# Host. Run from the repository root:
#   Rscript dev_docs/research/capture-fidelity/p2-jitter-tables.R
suppressMessages(pkgload::load_all(".", quiet = TRUE, export_all = TRUE, helpers = FALSE))
library(ggplot2)

base_engine <- gl_plugin("engine", "ggplot")
variant <- function(name, prepare = base_engine$prepare, draw = NULL) {
  args <- list("engine", name, "0.1.0", classes = "gloss_p2", prepare = prepare,
               tables = base_engine$tables, panels = base_engine$panels)
  if (!is.null(draw)) args$draw <- draw
  do.call(gl_register, args)
}
variant("separate_build")
variant("same_rng_state", prepare = function(x, width, height) {
  seed <- get0(".Random.seed", envir = globalenv(), inherits = FALSE)
  built <- ggplot2::ggplot_build(x)
  assign(".Random.seed", seed, envir = globalenv())
  list(plot = x, built = built)
})
variant("engine_draws", draw = function(state) {
  grid::grid.newpage()
  grid::grid.draw(ggplot2::ggplot_gtable(state$built))
  state
})

rows_on_page <- function(fig) {
  built <- gl_table(fig, "built_layer1")
  lv <- gl_leaf(fig)
  leaf <- lv$id[grepl("geom_point", lv$path)]
  el <- gl_elements(fig, list(leaf = leaf))
  px <- gl_to_pixel(fig, gl_panels(fig)$id[1], built$x, built$y)
  cx <- (el$x0 + el$x1) / 2
  cy <- (el$y0 + el$y1) / 2
  c(agree = sum(abs(px$x - cx) < 0.011 & abs(px$y - cy) < 0.011), rows = nrow(built))
}

p <- ggplot(mtcars, aes(cyl, mpg)) + geom_point(position = position_jitter(width = 0.4, height = 0))
class(p) <- c("gloss_p2", class(p))
cat("== jitter without a seed, 32 rows, 5 runs per rule (set.seed(k) before gloss()) ==\n")
for (rule in c("separate_build", "same_rng_state", "engine_draws")) {
  res <- vapply(1:5, function(k) {
    set.seed(k)
    fig <- suppressWarnings(gloss(p, width = 5, height = 4, context = FALSE, engine = rule))
    rows_on_page(fig)
  }, c(agree = 0, rows = 0))
  cat(sprintf("  %-15s rows on the page: %s of %d\n", rule, paste(res["agree", ], collapse = ", "), res["rows", 1]))
}

# The engine's own drawing step draws the page print() draws from the same
# random state (the contract of ADR-0006 point 4).
own <- page_signature(xml2::read_xml(plain_svg(function() { set.seed(7); print(p) }, 5, 4)))
eng <- gl_plugin("engine", "engine_draws")
by_engine <- page_signature(xml2::read_xml(plain_svg(function() {
  set.seed(7)
  eng$draw(eng$prepare(p, 5, 4))
}, 5, 4)))
cat(sprintf("\nengine draws vs print(), same seed: identical=%s, %d primitives differ\n",
            identical(own, by_engine), signature_diff(own, by_engine)))
