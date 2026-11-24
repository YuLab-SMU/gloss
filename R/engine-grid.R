# Built-in grid plotting engine.

register_engine_grid <- function() {
  gl_register_engine(
    name = "grid",
    classes = c("grob", "gList", "gTree", "gtable", "function", "recordedplot"),
    capture_fn = engine_grid_capture,
    packages = "grid",
    description = "Low-level grid grobs, gtables, grid drawing functions, and recorded grid plots",
    priority = -10L,
    page_kind = "grid",
    overwrite = TRUE
  )
}

engine_grid_capture <- function(x, ctx) {
  draw_method <- ctx$draw_method
  if (!isTRUE(ctx$already_drawn)) {
    draw_method <- ctx$draw_input(x)
    ctx$ensure_device()
  }

  sc <- ctx$capture_grid(draw_method = draw_method)

  leaves <- sc$leaves
  lineage <- make_lineage_df(leaves)

  list(
    scene = sc,
    ir = list(
      panels = list(),
      layers = list(),
      scales = list(),
      orders = stats::setNames(list(), character())
    ),
    tables = list(),
    lineage = lineage
  )
}
