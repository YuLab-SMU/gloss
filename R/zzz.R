# Package load hooks.

register_builtin_engines <- function() {
  register_engine_grid()
  register_engine_ggplot()
  invisible(NULL)
}

.onLoad <- function(libname, pkgname) {
  register_builtin_engines()
  invisible(NULL)
}
