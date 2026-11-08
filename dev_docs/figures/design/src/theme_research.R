# theme_research.R -- house style for research / technical figures (ggplot2 + grid)
#
#   source("theme_research.R")
#   p <- ggplot(...) + ... + theme_research()
#   rw_save(rw_card(p, "Claim as the title", "optional context"), "fig.png")
#
# Pieces:
#   rw                 color tokens (see references/visual-style.md)
#   theme_research()   warm canvas, quiet axes, faint grid, bold centred claim title
#   rw_region_tint()   vertical background gradient for semantic regions (F12)
#   rw_card()          canvas + centred title/subtitle + rounded panel card, with
#                      optional coloured direction arrows on y and/or x (F10, F11)
#   rw_save()          png via ragg (or svg via svglite) at 2x-ish resolution
#   rw_demo()          renders three reference-style demos into a directory
#
# Dependencies: ggplot2, grid; ragg (png) or svglite (svg).

rw <- list(
  canvas = "#F0EEE6", panel = "#FAF9F5", card_head = "#F4F2EC", card_body = "#FDFCF9",
  stroke = "#C8C7BF", grid = "#E6E4DC", ink = "#1F1E1D", body = "#3D3D3A", muted = "#87867F",
  highlight = "#D65451", highlight_soft = "#EA9E9D",
  neutral_dark = "#5E5D59", neutral_soft = "#B0AEA5",
  pole_pos = "#5B8FD0", pole_neg = "#C9575E", tint_pos = "#DCE6F2", tint_neg = "#F2D9D9",
  internal = "#4C75AD", internal_fill = "#CFE0F4", output = "#C8553D", output_stroke = "#EECAB4",
  struck = "#8C8B85", ok = "#3B8C5A",
  stage = c("#2F6DB5", "#2E9A3E", "#D23B2E"),
  group_a = "#6258D1", group_a_fill = "#F1F0FF",
  group_b = "#E9A23B", group_b_fill = "#FAF3E8", shared_fill = "#DEDCD1"
)

theme_research <- function(base_size = 13, family = "", grid = c("y", "x", "xy", "none")) {
  grid <- match.arg(grid)
  el <- ggplot2::element_line(colour = rw$grid, linewidth = 0.35)
  th <- ggplot2::theme_minimal(base_size = base_size, base_family = family) +
    ggplot2::theme(
      plot.background = ggplot2::element_rect(fill = rw$canvas, colour = NA),
      panel.background = ggplot2::element_rect(fill = rw$panel, colour = NA),
      panel.grid.major = el,
      panel.grid.minor = ggplot2::element_blank(),
      axis.line = ggplot2::element_line(colour = rw$muted, linewidth = 0.4),
      axis.ticks = ggplot2::element_blank(),
      axis.text = ggplot2::element_text(colour = rw$muted, size = ggplot2::rel(0.85)),
      axis.title = ggplot2::element_text(colour = rw$muted, face = "bold", size = ggplot2::rel(0.95)),
      plot.title = ggplot2::element_text(colour = rw$ink, face = "bold", size = ggplot2::rel(1.9),
                                         hjust = 0.5, margin = ggplot2::margin(b = 4)),
      plot.subtitle = ggplot2::element_text(colour = rw$muted, size = ggplot2::rel(1.15),
                                            hjust = 0.5, margin = ggplot2::margin(b = 12)),
      plot.title.position = "plot",
      plot.caption = ggplot2::element_text(colour = rw$muted, size = ggplot2::rel(0.75), hjust = 0),
      strip.text = ggplot2::element_text(colour = rw$muted, hjust = 0, size = ggplot2::rel(0.95),
                                         margin = ggplot2::margin(b = 4)),
      legend.position = "top", legend.justification = "right",
      legend.title = ggplot2::element_blank(),
      legend.text = ggplot2::element_text(colour = rw$muted, size = ggplot2::rel(0.8)),
      legend.key = ggplot2::element_blank(), legend.background = ggplot2::element_blank(),
      plot.margin = ggplot2::margin(18, 24, 14, 18)
    )
  if (grid %in% c("y", "none")) th <- th + ggplot2::theme(panel.grid.major.x = ggplot2::element_blank())
  if (grid %in% c("x", "none")) th <- th + ggplot2::theme(panel.grid.major.y = ggplot2::element_blank())
  th
}

# Vertical gradient behind the data: top colour = "good"/positive region.
# Add it as the first layer so data draws on top.
rw_region_tint <- function(top = rw$tint_pos, bottom = rw$tint_neg, n = 128) {
  ramp <- grDevices::colorRampPalette(c(top, bottom))(n)
  ggplot2::annotation_raster(matrix(ramp, ncol = 1), xmin = -Inf, xmax = Inf,
                             ymin = -Inf, ymax = Inf, interpolate = TRUE)
}

# Two-tone double arrow with labels at both ends. `vertical = TRUE` draws it
# upward (first label/colour at the top).
rw_direction_grob <- function(labels, colours, vertical, x, y, length, family, fontsize = 11) {
  u <- grid::unit
  arr <- grid::arrow(length = u(0.09, "in"), type = "open")
  half <- length / 2
  if (vertical) {
    segs <- grid::gList(
      grid::segmentsGrob(x, y, x, y + half, arrow = arr, gp = grid::gpar(col = colours[1], lwd = 1.4)),
      grid::segmentsGrob(x, y, x, y - half, arrow = arr, gp = grid::gpar(col = colours[2], lwd = 1.4)),
      grid::textGrob(labels[1], x, y + half + u(0.08, "in"), rot = 90, just = "left",
                     gp = grid::gpar(col = colours[1], fontsize = fontsize, fontface = "bold", fontfamily = family)),
      grid::textGrob(labels[2], x, y - half - u(0.08, "in"), rot = 90, just = "right",
                     gp = grid::gpar(col = colours[2], fontsize = fontsize, fontface = "bold", fontfamily = family))
    )
  } else {
    segs <- grid::gList(
      grid::segmentsGrob(x, y, x - half, y, arrow = arr, gp = grid::gpar(col = colours[1], lwd = 1.4)),
      grid::segmentsGrob(x, y, x + half, y, arrow = arr, gp = grid::gpar(col = colours[2], lwd = 1.4)),
      grid::textGrob(labels[1], x - half - u(0.08, "in"), y, just = "right",
                     gp = grid::gpar(col = colours[1], fontsize = fontsize, fontface = "bold", fontfamily = family)),
      grid::textGrob(labels[2], x + half + u(0.08, "in"), y, just = "left",
                     gp = grid::gpar(col = colours[2], fontsize = fontsize, fontface = "bold", fontfamily = family))
    )
  }
  grid::grobTree(segs)
}

# Wrap a ggplot in the house layout: canvas, centred bold title (+ subtitle),
# rounded panel card holding the plot. Direction arrows:
#   y_direction = c(top = "Assistant-like", bottom = "Role-playing")
#   x_direction = c(left = "Role-playing", right = "Assistant-like")
# Colours follow the pole tokens (positive = top / right) unless overridden.
rw_card <- function(plot, title = NULL, subtitle = NULL,
                    y_direction = NULL, x_direction = NULL,
                    y_colours = c(rw$pole_pos, rw$pole_neg),
                    x_colours = c(rw$pole_neg, rw$pole_pos),
                    family = "", title_size = 26, subtitle_size = 16) {
  u <- grid::unit
  p <- plot + ggplot2::theme(
    plot.background = ggplot2::element_rect(fill = NA, colour = NA),
    plot.title = ggplot2::element_blank(), plot.subtitle = ggplot2::element_blank()
  )
  if (!is.null(y_direction) || !is.null(x_direction)) {
    p <- p + ggplot2::theme(panel.background = ggplot2::element_rect(fill = NA, colour = NA))
  }
  g <- ggplot2::ggplotGrob(p)

  head <- if (is.null(title)) 0.35 else 0.95
  if (!is.null(subtitle)) head <- head + 0.38
  lpad <- if (is.null(y_direction)) 0 else 0.5
  bpad <- if (is.null(x_direction)) 0 else 0.45

  card_vp <- grid::viewport(x = u(0.3, "in"), y = u(0.3, "in"), just = c("left", "bottom"),
                            width = u(1, "npc") - u(0.6, "in"),
                            height = u(1, "npc") - u(head + 0.3, "in"))
  inner_vp <- grid::viewport(x = u(0.2 + lpad, "in"), y = u(0.15 + bpad, "in"), just = c("left", "bottom"),
                             width = u(1, "npc") - u(0.4 + lpad, "in"),
                             height = u(1, "npc") - u(0.3 + bpad, "in"))

  card_children <- grid::gList(
    grid::roundrectGrob(r = u(0.22, "in"), gp = grid::gpar(fill = rw$panel, col = NA)),
    grid::grobTree(g, vp = inner_vp)
  )
  if (!is.null(y_direction)) {
    card_children <- grid::gList(card_children, rw_direction_grob(
      y_direction, y_colours, vertical = TRUE, x = u(0.42, "in"), y = u(0.5, "npc"),
      length = u(0.45, "npc"), family = family))
  }
  if (!is.null(x_direction)) {
    card_children <- grid::gList(card_children, rw_direction_grob(
      x_direction, x_colours, vertical = FALSE, x = u(0.5, "npc"), y = u(0.3, "in"),
      length = u(0.55, "npc"), family = family))
  }

  top <- grid::gList(grid::rectGrob(gp = grid::gpar(fill = rw$canvas, col = NA)))
  if (!is.null(title)) {
    top <- grid::gList(top, grid::textGrob(title, y = u(1, "npc") - u(0.5, "in"),
      gp = grid::gpar(fontsize = title_size, fontface = "bold", col = rw$ink, fontfamily = family)))
  }
  if (!is.null(subtitle)) {
    top <- grid::gList(top, grid::textGrob(subtitle, y = u(1, "npc") - u(0.9, "in"),
      gp = grid::gpar(fontsize = subtitle_size, col = rw$muted, fontfamily = family)))
  }
  grid::gTree(children = grid::gList(top, grid::grobTree(card_children, vp = card_vp)), cl = "rw_card")
}

rw_save <- function(x, file, width = 12, height = 6.75, res = 200) {
  ext <- tolower(tools::file_ext(file))
  if (ext == "svg") {
    svglite::svglite(file, width = width, height = height, bg = rw$canvas)
  } else {
    ragg::agg_png(file, width = width, height = height, units = "in", res = res, background = rw$canvas)
  }
  on.exit(grDevices::dev.off())
  if (inherits(x, "ggplot")) print(x) else { grid::grid.newpage(); grid::grid.draw(x) }
  invisible(file)
}

# ---------------------------------------------------------------------------
# Demos (synthetic numbers, for layout only). rw_demo("out/") writes 3 PNGs.
# ---------------------------------------------------------------------------
rw_demo <- function(dir = tempdir(), family = "") {
  library(ggplot2)
  dir.create(dir, showWarnings = FALSE, recursive = TRUE)

  # F9: highlight the metric that should move; controls stay neutral; values on bars; no y axis.
  bars <- expand.grid(metric = c("Harm rate", "Bench A", "Bench B", "Bench C"),
                      cond = c("Baseline", "Treated"), model = c("Model 1", "Model 2"))
  bars$value <- c(0.65, 0.93, 0.71, 0.89, 0.33, 0.93, 0.70, 0.89,
                  0.83, 0.76, 0.68, 0.81, 0.41, 0.76, 0.67, 0.83)
  bars$fill <- ifelse(bars$metric == "Harm rate",
                      ifelse(bars$cond == "Baseline", rw$highlight, rw$highlight_soft),
                      ifelse(bars$cond == "Baseline", rw$neutral_dark, rw$neutral_soft))
  p1 <- ggplot(bars, aes(metric, value, group = cond)) +
    geom_col(aes(fill = fill), position = position_dodge(0.78), width = 0.72) +
    geom_text(aes(label = sprintf("%.2f", value)), position = position_dodge(0.78),
              vjust = -0.5, size = 3.4, colour = rw$body, family = family) +
    scale_fill_identity() +
    scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
    facet_wrap(~model, ncol = 1, strip.position = "left") +
    labs(x = NULL, y = NULL) +
    theme_research(family = family, grid = "none") +
    theme(axis.text.y = element_blank(), axis.line.y = element_blank(),
          strip.placement = "outside", axis.text.x = element_text(face = "bold"))
  rw_save(rw_card(p1, "Treatment halves the harm rate; benchmarks unchanged",
                  family = family), file.path(dir, "demo-highlight-bars.png"))

  # F10 + F12: small multiples, shared axes, region tint, y-direction arrow.
  set.seed(1)
  traj <- do.call(rbind, lapply(c("Coding", "Writing", "Philosophy", "Therapy"), function(d) {
    drift <- c(Coding = 2, Writing = 6, Philosophy = 22, Therapy = 18)[[d]]
    data.frame(domain = d, turn = 0:14, y = -drift * (1 - exp(-(0:14) / 3)) + rnorm(15, 0, 0.6))
  }))
  traj$domain <- factor(traj$domain, c("Coding", "Philosophy", "Writing", "Therapy"))
  p2 <- ggplot(traj, aes(turn, y)) +
    rw_region_tint() +
    geom_line(aes(colour = y), linewidth = 0.9) +
    geom_point(aes(colour = y), size = 2.4) +
    scale_colour_gradient(low = rw$pole_neg, high = rw$pole_pos, guide = "none") +
    facet_wrap(~domain, ncol = 2) +
    labs(x = "Conversation turn", y = "Projection") +
    theme_research(family = family, grid = "none")
  rw_save(rw_card(p2, "Drift happens in some conversation domains, not others",
                  y_direction = c("Stays in role", "Drifts away"), family = family),
          file.path(dir, "demo-small-multiples-direction.png"))

  # F11: direct-labelled scatter with a bipolar gradient and an x-direction arrow.
  pts <- data.frame(x = runif(900, -60, 10))
  pts$y <- pmax(0, rexp(900, 1 / (0.02 + 0.10 * pmax(0, -pts$x) / 60)) * 0.6)
  lab <- data.frame(x = c(-55, -45, -32, -12, 6), y = c(0.36, 0.28, 0.2, 0.08, 0.04),
                    name = c("Demon", "Narcissist", "Saboteur", "Visionary", "Researcher"))
  p3 <- ggplot(pts, aes(x, y)) +
    geom_point(aes(colour = x), alpha = 0.35, size = 1.6, stroke = 0) +
    geom_text(data = lab, aes(label = name), fontface = "bold", size = 3.6,
              colour = rw$body, family = family, vjust = -0.6) +
    scale_colour_gradient(low = rw$pole_neg, high = rw$pole_pos, guide = "none") +
    labs(x = "Position on the axis (previous turn)", y = "Rate of harmful responses") +
    theme_research(family = family, grid = "none")
  rw_save(rw_card(p3, "Harm rate rises as responses move away from the default role",
                  x_direction = c("Role-playing", "Default role"), family = family),
          file.path(dir, "demo-direct-label-scatter.png"))

  invisible(list.files(dir, "^demo-.*png$", full.names = TRUE))
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  out <- rw_demo(if (length(args)) args[[1]] else "rw-demo", family = if (length(args) > 1) args[[2]] else "")
  cat(out, sep = "\n")
}
