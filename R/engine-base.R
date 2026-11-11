# Engine plugin: base graphics. Accepts a recorded plot or a function that
# draws a base page. gloss replays the page one display-list entry at a time
# (ADR-0006); each entry that draws is a leaf, named by its call. Panels are
# the plot regions of the page's figures, with the user coordinates of
# par("usr"); a leaf lies in a panel when its primitives are clipped to that
# plot region. Base graphics carry no data tables; binding base plots to data
# is still open (design: 风险与未决问题).

register_engine_base <- function() {
  gl_register(
    "engine", name = "base", version = "0.2.0", package = "gloss",
    description = "base graphics, replayed one display-list entry at a time: plot regions with user coordinates",
    classes = c("recordedplot", "function"),
    page = "base",
    packages = "graphics",
    prepare = function(x, width, height) list(x = x),
    panels = function(state, substrate) {
      leaves <- substrate$leaves
      seg <- ifelse(endsWith(leaves$vp, "::plot"), leaves$vp, NA_character_)
      native_panels(leaves, seg, key_fun = function(v) sub("::plot$", "", v))
    },
    example = function() {
      function() graphics::plot(datasets::mtcars$wt, datasets::mtcars$mpg, pch = 19)
    }
  )
}
