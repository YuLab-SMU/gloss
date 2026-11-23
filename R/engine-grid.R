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
  lineage <- if (nrow(leaves) == 0L) {
    empty_lineage_df()
  } else {
    data.frame(
      leaf_id = leaves$leaf_id,
      grob_name = leaves$grob_name,
      layout_slot = leaves$layout_slot,
      panel_id = rep(NA_character_, nrow(leaves)),
      layer_id = rep(NA_integer_, nrow(leaves)),
      table_id = rep(NA_character_, nrow(leaves)),
      cardinality = rep("unlinked", nrow(leaves)),
      n_rows = rep(NA_integer_, nrow(leaves)),
      n_elements = leaves$n_elements,
      stringsAsFactors = FALSE
    )
  }

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
