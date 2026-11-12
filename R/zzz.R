.onLoad <- function(libname, pkgname) {
  register_builtin_plugins()
  invisible()
}

# Built-in plugins register through gl_register(), exactly as a third-party
# package would from its own .onLoad().
register_builtin_plugins <- function() {
  register_engine_ggplot()
  register_engine_patchwork()
  register_engine_heatmap()
  register_engine_base()
  register_engine_grid()
  register_context_code()
  register_context_data()
  register_context_engine()
  register_context_env()
  register_context_doc()
  register_context_git()
  register_projection_html()
  register_projection_svg()
}
