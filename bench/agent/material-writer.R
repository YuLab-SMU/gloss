# What each arm of the pilot works on, written for one figure (agent-path
# plan 2026-11-12, Task 4). One function, self-contained, so that the bench
# worker can be handed it (bench/agent/material.R, in the container) and a
# hand-built figure can be written with it on the host (bench/agent/pilot.R,
# the rehearsal). The layout is described at the top of bench/agent/material.R.
#
#   fig   the figure object (a ggplot or a patchwork)
#   svg   the figure drawn alone on svglite, 7 x 5 in, as one string
#   dir   where to write
# Returns counts for the run's record.
write_material <- function(fig, svg, dir) {
  gx <- suppressWarnings(gloss::gloss(fig))   # with the bindings made at capture
  dir.create(file.path(dir, "A", "tables"), recursive = TRUE, showWarnings = FALSE)
  gloss::gl_write(gx, file.path(dir, "figure.html"))
  bound <- gloss::gl_bindings(gx)
  saveRDS(list(elements = bound, leaves = gloss::gl_bindings(gx, by = "leaf"), geometry = gloss::gl_elements(gx)),
          file.path(dir, "answers.rds"), version = 2)
  writeLines(svg, file.path(dir, "A", "figure.svg"), useBytes = TRUE)
  tabs <- list()
  for (nm in gloss::gl_tables(gx)$name) {
    d <- tryCatch(gloss::gl_table(gx, nm), error = function(e) NULL)
    if (!is.data.frame(d)) next
    tabs[[nm]] <- d
    flat <- d[vapply(d, function(col) is.atomic(col) && is.null(dim(col)), logical(1))]
    utils::write.csv(cbind(row = seq_len(nrow(d)), flat), file.path(dir, "A", "tables", paste0(nm, ".csv")), row.names = FALSE)
  }
  saveRDS(tabs, file.path(dir, "A", "tables.rds"), version = 2)
  # the grob tree as grid lists it; a gtable is measured on a device, so one
  # that draws nowhere is opened for it
  grDevices::pdf(NULL, width = 7, height = 5)
  dev <- grDevices::dev.cur()
  tree <- tryCatch({
    gt <- if (inherits(fig, "patchwork")) patchwork::patchworkGrob(fig) else ggplot2::ggplotGrob(fig)
    utils::capture.output(grid::grid.ls(grid::grid.force(gt)))
  }, error = function(e) paste("the grob tree could not be listed:", conditionMessage(e)),
  finally = if (dev %in% grDevices::dev.list()) grDevices::dev.off(dev))
  writeLines(tree, file.path(dir, "A", "grob_tree.txt"))
  list(answers = sum(bound$status %in% "verified"), tables = length(tabs), tree_lines = length(tree))
}
