# Engine plugin: any grid grob (including gtables and gLists), and any
# function or recorded plot that draws a grid page. No tables or panels;
# leaves, viewports and native scales still come from the probes.

register_engine_grid <- function() {
  gl_register(
    "engine", name = "grid", version = "0.1.0", package = "gloss",
    description = "any grid grob, or a function or recorded plot that draws with grid: leaves and viewports only",
    classes = c("grob", "gList", "function", "recordedplot"),
    page = "grid",
    packages = "grid",
    prepare = function(x, width, height) list(x = x),
    example = function() {
      grid::gTree(children = grid::gList(
        grid::rectGrob(gp = grid::gpar(fill = "grey95")),
        grid::pointsGrob(c(0.2, 0.5, 0.8), c(0.3, 0.7, 0.4), pch = 19)
      ), vp = grid::viewport(xscale = c(0, 1), yscale = c(0, 1)))
    }
  )
}
