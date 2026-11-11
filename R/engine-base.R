# Engine plugin: base graphics, through gridGraphics. Accepts a recorded
# plot or a function that draws a base page. Panels are the plot windows,
# with the user coordinates gridGraphics gives their viewports. Base graphics
# carry no data tables; binding base plots to data is still open (design:
# 风险与未决问题).
#
# Until gloss captures base pages directly (page-capture plan Task 5,
# ADR-0006 point 6), the engine redraws the page with gridGraphics, a second
# implementation of base graphics whose page is not always the code's (dev
# log 2026-11-10-page-capture-spike: 9 of 10 development base figures). The
# contract check of the drawing step passes on example() only: a function is
# drawn by gridGraphics on its own device, where the background is
# transparent; the same plot recorded on svglite differs by one background
# rect, and rect(border = 0) by two primitives (dev log 2026-11-11).

register_engine_base <- function() {
  gl_register(
    "engine", name = "base", version = "0.1.0", package = "gloss",
    description = "base graphics via gridGraphics: plot windows with user coordinates",
    classes = c("recordedplot", "function"),
    page = "base",
    packages = "gridGraphics",
    prepare = function(x, width, height) list(x = x),
    draw = function(state) {
      dev <- grDevices::dev.cur()
      g <- gridGraphics::echoGrob(state$x, name = "graphics")
      grDevices::dev.set(dev)
      grid::grid.newpage()
      grid::grid.draw(g)
      state
    },
    panels = function(state, substrate) {
      leaves <- substrate$leaves
      seg <- vapply(strsplit(leaves$vp, "::", fixed = TRUE), function(parts) {
        hit <- grep("-window-[0-9]+-[0-9]+$", parts, value = TRUE)
        if (length(hit)) hit[length(hit)] else NA_character_
      }, "")
      native_panels(leaves, seg, key_fun = function(v) sub("^.*-window-", "window ", v))
    },
    example = function() {
      function() graphics::plot(datasets::mtcars$wt, datasets::mtcars$mpg, pch = 19)
    }
  )
}
