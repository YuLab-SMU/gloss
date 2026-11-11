# Engine plugin: patchwork compositions. Each ggplot in the composition
# contributes its tables and panels, prefixed with its position
# ("plot2_built_layer1", "plot2_panel1"), and its layer leaves are bound with
# ggplot's binder.
#
# patchwork's print() builds every plot itself, so the engine's builds are
# other builds. A plot built twice with different data draws random numbers
# in its build: its built data cannot be shown to be the data drawn, and its
# built data, panels and bindings are withheld with the reason (ADR-0006
# point 4).
#
# The engine prints the composition as patchwork does and keeps the gtable
# print() drew (the last gtable on grid's display list). Each plot's panels
# are found in it by the cell names patchwork gives them (patchwork 1.3):
# a plot's cells carry its index among its composition's patches as a
# suffix ("panel-2", "axis-l-2"); a nested composition is one cell,
# "patchwork-table-<i>", holding its own table; a plot with one panel keeps
# its panel grob in cell "panel-<i>"; a plot with several has them in a
# table of their own, in cell "panel; <its cells' names>-<i>". The indices,
# read from the outside in, are the plot's path in get_patches(). A mapping
# that put a plot's panels with another plot's build would fail
# back-substitution, not pass it.

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
    draw = function(state) {
      print(state$plot)
      state$gtable <- last_drawn(function(g) inherits(g, "gtable"))
      state
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
    panels = function(state, substrate) patchwork_panels(state, substrate),
    bind = function(state, substrate) patchwork_bind(state, substrate),
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

# Each ggplot's path in the composition (patch indices from the outside in),
# in the order of patchwork_plots().
patchwork_patch_paths <- function(x, prefix = integer()) {
  if (!inherits(x, "patchwork")) {
    return(if (inherits(x, "ggplot")) list(prefix) else list())
  }
  get_patches <- utils::getFromNamespace("get_patches", "patchwork")
  parts <- get_patches(x)$plots
  unlist(lapply(seq_along(parts), function(j) patchwork_patch_paths(parts[[j]], c(prefix, j))),
         recursive = FALSE)
}

# The panel grobs of each plot, found in the drawn gtable by patchwork's cell
# names; a list with one entry per plot of patchwork_plots(), each a list of
# panel gTrees (empty for a plot whose panels were not found).
patchwork_plot_panels <- function(state) {
  paths <- vapply(patchwork_patch_paths(state$plot), paste, "", collapse = "/")
  found <- new_env()
  walk <- function(gt, prefix) {
    if (!inherits(gt, "gtable")) return(invisible())
    for (j in seq_len(nrow(gt$layout))) {
      nm <- gt$layout$name[j]
      g <- gt$grobs[[j]]
      if (grepl("^patchwork-table-[0-9]+$", nm)) {
        walk(g, c(prefix, as.integer(sub("^patchwork-table-", "", nm))))
      } else if (grepl("^panel-[0-9]+$", nm) && is_ggplot_panel(g)) {
        assign(paste(c(prefix, as.integer(sub("^panel-", "", nm))), collapse = "/"), list(g), envir = found)
      } else if (grepl("^panel; .*-[0-9]+$", nm) && inherits(g, "gtable")) {
        assign(paste(c(prefix, as.integer(sub("^.*-([0-9]+)$", "\\1", nm))), collapse = "/"),
               Filter(is_ggplot_panel, g$grobs), envir = found)
      }
    }
  }
  walk(state$gtable, integer())
  lapply(paths, function(p) if (exists(p, envir = found, inherits = FALSE)) get(p, envir = found) else list())
}

# The last grob on the current device's grid display list for which `keep`
# is TRUE: what a print() method drew.
last_drawn <- function(keep) {
  acc <- new_env()
  acc$g <- NULL
  grid::grid.DLapply(function(elt) {
    if (inherits(elt, "grob") && keep(elt)) acc$g <- elt
    elt
  })
  acc$g
}

is_ggplot_panel <- function(g) inherits(g, "gTree") && grepl("^panel-[0-9]+[.]", g$name %||% "")

# Every ggplot panel grob anywhere in a drawn tree.
all_ggplot_panels <- function(g) {
  if (is_ggplot_panel(g)) return(list(g))
  kids <- if (inherits(g, "gtable")) g$grobs else if (inherits(g, "gTree")) g$children else list()
  unlist(lapply(kids, all_ggplot_panels), recursive = FALSE)
}

random_reason <- function(i) {
  sprintf(paste("plot %d: two builds give different data (its build draws random numbers),",
                "so its built data cannot be shown to be the data patchwork drew."), i)
}

# Leaves whose path runs through one of `grobs`.
leaves_under <- function(leaves, grobs) {
  nm <- vapply(grobs, function(g) g$name, "")
  vapply(strsplit(leaves$path, "/", fixed = TRUE), function(s) any(s %in% nm), logical(1))
}

patchwork_panels <- function(state, substrate) {
  if (is.null(state$gtable)) return(list(withheld = "the gtable patchwork drew was not kept"))
  pp <- patchwork_plot_panels(state)
  panels <- list()
  leaf_panel <- character()
  notes <- character()
  for (i in seq_along(state$plots)) {
    if (!length(state$plots[[i]]$layers)) next
    if (!length(pp[[i]])) {
      notes <- c(notes, sprintf("plot %d: its panels were not found in the gtable patchwork drew.", i))
      next
    }
    if (isTRUE(state$random[i])) {
      notes <- c(notes, random_reason(i))
      next
    }
    r <- ggplot_panels(state$built[[i]], substrate, prefix = sprintf("plot%d_", i),
                       leaf_filter = leaves_under(substrate$leaves, pp[[i]]))
    if (!is.null(r$withheld)) {
      notes <- c(notes, sprintf("plot %d: %s", i, r$withheld))
      next
    }
    panels[[length(panels) + 1L]] <- r$panels
    leaf_panel <- c(leaf_panel, r$leaf_panel[!is.na(r$leaf_panel)])
  }
  list(panels = if (length(panels)) do.call(rbind, panels) else NULL, leaf_panel = leaf_panel,
       withheld = if (length(notes)) paste(notes, collapse = " ") else NULL)
}

# Bindings per plot with ggplot's binder, given that plot's panel grobs. A
# leaf no plot pairs is outside the layers, unless it lies in a ggplot panel
# that belongs to no plot found: then it is unbound, with the reason.
patchwork_bind <- function(state, substrate) {
  leaves <- substrate$leaves
  unbound <- function(ids, reason) data.frame(leaf = ids, reason = rep(reason, length(ids)), stringsAsFactors = FALSE)
  if (is.null(state$gtable)) return(list(claims = list(), unbound = unbound(leaves$id, "the gtable patchwork drew was not kept")))
  pp <- patchwork_plot_panels(state)
  claims <- list()
  ub <- unbound(character(), character())
  mine <- rep(FALSE, nrow(leaves))
  for (i in seq_along(state$plots)) {
    if (!length(pp[[i]])) next
    under <- leaves_under(leaves, pp[[i]])
    mine <- mine | under
    tab <- list(layout = data.frame(name = rep("panel", length(pp[[i]]))), grobs = pp[[i]])
    r <- ggplot_bind(state$built[[i]], tab, substrate, prefix = sprintf("plot%d_", i))
    if (isTRUE(state$random[i])) {
      # which leaves are the plot's layers is read from the drawn panels; the
      # rows they would be paired with are not the rows drawn
      layer_leaves <- c(vapply(r$claims, `[[`, "", "leaf"), r$unbound$leaf)
      ub <- rbind(ub, unbound(layer_leaves, random_reason(i)))
      next
    }
    claims <- c(claims, r$claims)
    ub <- rbind(ub, r$unbound)
  }
  # A ggplot panel no plot owns (an inset, a gtable added to the
  # composition): the leaves in its layer slots are unbound, its background,
  # grid and foreground are outside, as in a plot's own panels (the
  # children's order of ggplot_bind(), without panel.ontop).
  seen <- unlist(lapply(pp, function(g) vapply(g, function(x) x$name, "")))
  stray <- Filter(function(g) !g$name %in% seen, all_ggplot_panels(state$gtable))
  segs <- strsplit(leaves$path, "/", fixed = TRUE)
  for (g in stray) {
    kids <- names(g$children)
    layer_kids <- if (length(kids) >= 5L) kids[3:(length(kids) - 2L)] else character()
    hit <- !mine & vapply(segs, function(s) {
      at <- match(g$name, s)
      !is.na(at) && at < length(s) && s[at + 1L] %in% layer_kids
    }, logical(1))
    ub <- rbind(ub, unbound(leaves$id[hit], "the leaf lies in a ggplot panel that belongs to no plot gloss found in the composition"))
  }
  done <- c(vapply(claims, `[[`, "", "leaf"), ub$leaf)
  list(claims = claims, unbound = ub, outside = setdiff(leaves$id, done))
}
