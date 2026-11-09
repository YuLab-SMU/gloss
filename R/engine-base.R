# Engine plugin: base graphics, through gridGraphics. Accepts a recorded
# plot or a function that draws the plot. Panels are the plot windows, with
# the user coordinates gridGraphics gives their viewports. Base graphics
# carry no data tables; binding base plots to data is still open (design:
# 风险与未决问题).

register_engine_base <- function() {
  gl_register(
    "engine", name = "base", version = "0.1.0", package = "gloss",
    description = "base graphics via gridGraphics: plot windows with user coordinates",
    classes = c("recordedplot", "function"),
    packages = "gridGraphics",
    prepare = function(x, width, height) list(x = x),
    grob = function(state) gridGraphics::echoGrob(state$x, name = "graphics"),
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
