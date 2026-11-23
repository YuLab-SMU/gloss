# Package load hooks.

register_builtin_engines <- function() {
  register_engine_grid()
  register_engine_base()
  register_engine_ggplot()
  register_engine_patchwork()
  register_engine_heatmap()
  invisible(NULL)
}

.onLoad <- function(libname, pkgname) {
  register_builtin_engines()
  invisible(NULL)
}
