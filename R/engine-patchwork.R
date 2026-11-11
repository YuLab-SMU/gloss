# Engine plugin: patchwork compositions. Each ggplot in the composition
# contributes its tables, prefixed with its position ("plot2_built_layer1").
# Panels of patchwork plots are not mapped yet (M1).
#
# patchwork's print() builds every plot itself, so the engine's builds are
# other builds. A plot built twice with different data draws random numbers
# in its build: its built data cannot be shown to be the data drawn, and are
# withheld with the reason (ADR-0006 point 4).

register_engine_patchwork <- function() {
  gl_register(
    "engine", name = "patchwork", version = "0.1.0", package = "gloss",
    description = "patchwork compositions: tables of every ggplot in the composition",
    classes = "patchwork",
    packages = c("patchwork", "ggplot2"),
    prepare = function(x, width, height) {
      plots <- patchwork_plots(x)
      built <- lapply(plots, build_ggplot)
      again <- lapply(plots, ggplot2::ggplot_build)
      random <- !mapply(function(a, b) identical(a$data, b$data), built, again)
      list(plot = x, plots = plots, built = built, random = unname(random))
    },
    tables = function(state) {
      out <- list()
      for (i in seq_along(state$plots)) {
        reason <- if (isTRUE(state$random[i])) {
          sprintf(paste("plot %d: two builds give different data (its build draws random numbers),",
                        "so its built data cannot be shown to be the data patchwork drew."), i)
        }
        tabs <- ggplot_tables(state$plots[[i]], state$built[[i]], withheld = reason)
        for (t in tabs) {
          t$name <- sprintf("plot%d_%s", i, t$name)
          if (!is.null(t$description)) t$description <- sprintf("plot %d: %s", i, t$description)
          out[[length(out) + 1L]] <- t
        }
      }
      out
    },
    describe = function(state) list(plots = lapply(state$plots, ggplot_describe)),
    example = function() {
      p <- ggplot2::ggplot(datasets::mtcars, ggplot2::aes(.data$wt, .data$mpg)) + ggplot2::geom_point()
      patchwork::wrap_plots(p, p)
    }
  )
}

# The ggplots of a composition, depth first, in patchwork's order.
patchwork_plots <- function(x) {
  if (!inherits(x, "patchwork")) {
    return(if (inherits(x, "ggplot")) list(x) else list())
  }
  get_patches <- utils::getFromNamespace("get_patches", "patchwork")
  parts <- get_patches(x)$plots
  unlist(lapply(parts, patchwork_plots), recursive = FALSE)
}
