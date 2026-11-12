# Binding by back-substitution (plan 2026-11-11-m1-roles-and-binding, Task 2).

bind_fixture <- function() {
  skip_if_not_installed("ggplot2")
  p <- ggplot2::ggplot(datasets::mtcars, ggplot2::aes(.data$wt, .data$mpg, colour = factor(.data$cyl))) +
    ggplot2::geom_point() +
    ggplot2::geom_smooth(method = "lm", formula = y ~ x) +
    ggplot2::facet_wrap(~am) +
    ggplot2::annotate("text", x = 4, y = 32, label = "heavier")
  suppressWarnings(bind_capture(p))
}

test_that("layer leaves of a facetted ggplot bind and verify", {
  b <- bind_fixture()
  lv <- b$leaves
  pts <- lv[lv$table %in% "built_layer1", ]
  expect_equal(nrow(pts), 2L)
  expect_equal(pts$status, c("verified", "verified"))
  expect_equal(sum(pts$verified), 32L)
  expect_true(all(pts$max_dev < 0.05))
  # one regression line per group and panel, each against its own group
  lines <- lv[lv$table %in% "built_layer2" & lv$mode %in% "group", ]
  expect_gte(nrow(lines), 6L)
  expect_true(all(lines$status == "verified"))
  # the annotate() layer, drawn as a generic text grob, is paired by its place in the panel
  ann <- lv[lv$table %in% "built_layer3", ]
  expect_equal(ann$status, c("verified", "verified"))
  # nothing outside the layers is paired
  out <- lv[lv$status == "outside", ]
  expect_true(all(is.na(out$table)))
  expect_true(any(grepl("axis|strip|grid|background", b$fig$substrate$leaves$path[match(out$leaf, b$fig$substrate$leaves$id)])))
  # every element of a verified leaf has its row
  el <- b$elements[b$elements$leaf %in% pts$leaf, ]
  expect_equal(nrow(el), 32L)
  expect_false(anyNA(el$row))
  expect_true(all(el$status == "verified"))
})

test_that("rows put out of order fail every element they move", {
  b <- bind_fixture()
  fig <- b$fig
  eng <- gl_plugin("engine", "ggplot")
  p <- ggplot2::ggplot(datasets::mtcars, ggplot2::aes(.data$wt, .data$mpg)) + ggplot2::geom_point()
  res <- capture_figure(p, eng, context = FALSE)
  stated <- eng$bind(res$state, res$fig$substrate)
  cl <- stated$claims[[1]]
  geo <- scene_geometry(res$fig$substrate)
  leaf <- res$fig$substrate$leaves[res$fig$substrate$leaves$id == cl$leaf, ]
  ok <- check_claim(cl, leaf, geo)
  expect_equal(ok$leaf$status, "verified")
  # permute the rows: an element now paired with another row fails unless
  # that row sits where its own row does (mtcars has no two cars at one point)
  set.seed(1)
  perm <- sample.int(nrow(cl$pred))
  moved <- perm != seq_along(perm)
  bad <- cl
  bad$pred <- cl$pred[perm, ]
  r <- check_claim(bad, leaf, geo)
  expect_equal(r$elements$status[moved], rep("failed", sum(moved)))
  expect_equal(r$elements$status[!moved], rep("verified", sum(!moved)))
  expect_equal(r$leaf$status, "partly_failed")
  # move one drawn point by 1 pt: that element fails, the others stay verified
  geo2 <- geo
  k <- which(geo2$leaf == cl$leaf)[5]
  geo2$cx[k] <- geo2$cx[k] + 1
  r2 <- check_claim(cl, leaf, geo2)
  expect_equal(sum(r2$elements$status == "failed"), 1L)
  expect_equal(r2$elements$status[5], "failed")
})

test_that("elements whose rows tie are ambiguous, not verified", {
  skip_if_not_installed("ggplot2")
  d <- data.frame(x = c(1, 2, 2, 3), y = c(1, 2, 2, 3))
  b <- bind_capture(ggplot2::ggplot(d, ggplot2::aes(.data$x, .data$y)) + ggplot2::geom_point())
  lv <- b$leaves[b$leaves$table %in% "built_layer1", ]
  expect_equal(lv$status, "ambiguous")
  expect_equal(lv$verified, 2L)
  expect_equal(lv$ambiguous, 2L)
  el <- b$elements[b$elements$leaf == lv$leaf, ]
  expect_equal(el$status, c("verified", "ambiguous", "ambiguous", "verified"))
})

test_that("bars under coord_flip() and lines on a log scale verify", {
  skip_if_not_installed("ggplot2")
  bars <- bind_capture(ggplot2::ggplot(ggplot2::mpg, ggplot2::aes(.data$class)) + ggplot2::geom_bar() +
                         ggplot2::coord_flip())
  lv <- bars$leaves[bars$leaves$table %in% "built_layer1", ]
  expect_equal(lv$status, "verified")
  expect_equal(lv$verified, 7L)
  line <- bind_capture(ggplot2::ggplot(ggplot2::economics, ggplot2::aes(.data$date, .data$unemploy)) +
                         ggplot2::geom_line() + ggplot2::scale_y_log10())
  lv <- line$leaves[line$leaves$table %in% "built_layer1", ]
  expect_equal(lv$status, "verified")
  expect_equal(lv$mode, "group")
})

test_that("leaves that cannot be paired say why", {
  b <- bind_fixture()
  lv <- b$leaves
  # a ribbon's outline draws two lines for one group
  two <- lv[lv$table %in% "built_layer2" & lv$status == "unbound", ]
  expect_gte(nrow(two), 1L)
  expect_match(two$reason[1], "neither one per row nor one per group")
  # the ribbon outline of a two-car group draws nothing: its counts do not match
  cm <- lv[lv$status == "count_mismatch", ]
  expect_gte(nrow(cm), 1L)
  expect_match(cm$reason[1], "drew 0 elements")
  # rows without positions (geom_hline keeps only yintercept)
  h <- bind_capture(ggplot2::ggplot(datasets::mtcars, ggplot2::aes(.data$wt, .data$mpg)) +
                      ggplot2::geom_hline(yintercept = 20))
  hl <- h$leaves[h$leaves$status == "unbound", ]
  expect_equal(nrow(hl), 1L)
  expect_match(hl$reason, "neither x and y")
  # an engine that states no bindings
  g <- bind_capture(grid::rectGrob())
  expect_true(all(g$leaves$status == "unbound"))
  expect_match(g$leaves$reason[1], "states no bindings")
})

test_that("heatmap cells verify by place and colour, and a wrong order fails on colour", {
  skip_if_not_installed("ComplexHeatmap")
  set.seed(1)
  m <- matrix(stats::rnorm(40), 5, dimnames = list(paste0("g", 1:5), paste0("s", 1:8)))
  ht <- ComplexHeatmap::Heatmap(m, name = "z", row_split = c(1, 1, 2, 2, 2), column_km = 2)
  eng <- gl_plugin("engine", "heatmap")
  res <- suppressMessages(capture_figure(ht, eng, context = FALSE))
  b <- bind_figure(res$fig, res$engine, res$state)
  body <- b$leaves[b$leaves$table %in% "matrix_z", ]
  expect_equal(nrow(body), 4L)
  expect_equal(sum(body$verified), 40L)
  expect_true(all(body$status == "verified"))
  # the same cells with the slice's rows in another order: every place still
  # passes, the colours of the moved rows do not
  stated <- eng$bind(res$state, res$fig$substrate)
  cl <- stated$claims[[3]]
  geo <- scene_geometry(res$fig$substrate)
  leaf <- res$fig$substrate$leaves[res$fig$substrate$leaves$id == cl$leaf, ]
  nr <- 3L
  swap <- unlist(lapply(seq(0, nrow(cl$pred) - nr, by = nr), function(o) o + c(2L, 1L, 3L)))
  bad <- cl
  bad$pred$fill <- cl$pred$fill[swap]
  r <- check_claim(bad, leaf, geo)
  moved <- swap != seq_along(swap)
  expect_true(all(r$elements$status[moved] == "failed"))
  expect_true(all(r$elements$status[!moved] == "verified"))
})

# Patchwork (plan Task 2b): each plot's panels are found in the gtable
# patchwork drew, by the patch index patchwork appends to the cell names, and
# bound with that plot's build.
patchwork_fixture <- function() {
  skip_if_not_installed("patchwork")
  p1 <- ggplot2::ggplot(datasets::mtcars, ggplot2::aes(.data$wt, .data$mpg)) + ggplot2::geom_point()
  p2 <- ggplot2::ggplot(datasets::mtcars, ggplot2::aes(factor(.data$cyl))) + ggplot2::geom_bar() +
    ggplot2::facet_wrap(~am)
  p3 <- ggplot2::ggplot(datasets::mtcars, ggplot2::aes(.data$hp, .data$qsec)) + ggplot2::geom_point(colour = "red")
  patchwork::wrap_plots(p1, p2) / p3
}

test_that("patchwork: each plot's panels are mapped and its layer leaves bind", {
  b <- bind_capture(patchwork_fixture())
  pan <- b$fig$substrate$panels
  expect_setequal(pan$id, c("plot1_panel1", "plot2_panel1", "plot2_panel2", "plot3_panel1"))
  lv <- b$leaves[!is.na(b$leaves$table), ]
  expect_setequal(unique(lv$table), c("plot1_built_layer1", "plot2_built_layer1", "plot3_built_layer1"))
  expect_equal(sum(lv$failed), 0L)
  expect_equal(sum(lv$verified[lv$table == "plot1_built_layer1"]), 32L)
  expect_equal(sum(lv$verified[lv$table == "plot2_built_layer1"]), 6L)   # 3 bars in each of two panels
  # plot 3: Hornet Sportabout and Pontiac Firebird share hp (175) and differ
  # by 0.03 s in qsec: their points lie within 0.5 pt of each other, ambiguous
  p3 <- lv[lv$table == "plot3_built_layer1", ]
  expect_equal(c(p3$verified, p3$ambiguous), c(30L, 2L))
  # axes, strips and backgrounds of the plots are outside the layers
  expect_true(all(b$leaves$status[is.na(b$leaves$table)] == "outside"))
})

test_that("patchwork: a plot paired with another plot's rows fails, so the mapping is checked", {
  x <- patchwork_fixture()
  eng <- gl_plugin("engine", "patchwork")
  res <- capture_figure(x, eng, context = FALSE)
  # plots 1 and 3 both draw 32 points: with their builds swapped every
  # count still matches, and every point must fail on its position
  st <- res$state
  st$built[c(1, 3)] <- st$built[c(3, 1)]
  b <- bind_figure(res$fig, eng, st)
  lv <- b$leaves[b$leaves$table %in% c("plot1_built_layer1", "plot3_built_layer1"), ]
  expect_equal(nrow(lv), 2L)
  expect_equal(lv$status, c("failed", "failed"))
  expect_equal(sum(lv$failed), 64L)
})

test_that("patchwork: plots inside a nested composition, after a spacer, are found", {
  skip_if_not_installed("patchwork")
  p1 <- ggplot2::ggplot(datasets::mtcars, ggplot2::aes(.data$wt, .data$mpg)) + ggplot2::geom_point()
  p2 <- ggplot2::ggplot(ggplot2::economics, ggplot2::aes(.data$date, .data$unemploy)) + ggplot2::geom_line()
  b <- bind_capture(p1 | (patchwork::plot_spacer() / p2))
  lv <- b$leaves[!is.na(b$leaves$table), ]
  expect_setequal(unique(lv$table), c("plot1_built_layer1", "plot3_built_layer1"))
  expect_true(all(lv$status == "verified"))
  expect_equal(lv$mode[lv$table == "plot3_built_layer1"], "group")
})

test_that("patchwork: a plot whose build draws random numbers is withheld alone, with the reason", {
  skip_if_not_installed("patchwork")
  steady <- ggplot2::ggplot(datasets::mtcars, ggplot2::aes(.data$wt, .data$mpg)) + ggplot2::geom_point()
  shaken <- ggplot2::ggplot(datasets::mtcars, ggplot2::aes(.data$cyl, .data$mpg)) +
    ggplot2::geom_point(position = ggplot2::position_jitter(width = 0.3, height = 0))
  b <- bind_capture(patchwork::wrap_plots(steady, shaken), width = 6, height = 3)
  expect_equal(b$fig$substrate$panels$id, "plot1_panel1")
  w <- b$fig$status$withheld
  expect_match(w$reason[w$what == "panels"], "plot 2: two builds")
  lv <- b$leaves
  expect_equal(lv$status[lv$table %in% "plot1_built_layer1"], "verified")
  shaken_leaf <- lv[lv$status == "unbound", ]
  expect_equal(nrow(shaken_leaf), 1L)
  expect_match(shaken_leaf$reason, "plot 2: two builds")
  expect_equal(shaken_leaf$n_elements, 32L)
})

test_that("a geom with one child per row pairs each child with its row (geom_label)", {
  # Development run 2026-11-11-1205, gallery-029: geom_label() draws one
  # child per row; pairing each child with its group failed all 2000 boxes.
  skip_if_not_installed("ggplot2")
  d <- data.frame(x = c(1, 2, 3, 4), y = c(2, 4, 1, 3), lab = c("a", "bb", "c", "dd"))
  b <- bind_capture(ggplot2::ggplot(d, ggplot2::aes(.data$x, .data$y, label = .data$lab)) + ggplot2::geom_label())
  lv <- b$leaves[b$leaves$table %in% "built_layer1", ]
  expect_equal(nrow(lv), 8L)                      # a box and a text per label
  expect_true(all(lv$status == "verified"))
  el <- b$elements[b$elements$leaf %in% lv$leaf, ]
  expect_setequal(el$row, 1:4)
  expect_true(all(table(el$row) == 2L))
})

test_that("an area's outline is checked through ymax, the line it draws", {
  # Development run 2026-11-11-1205, gallery-024: 30 outlines of stacked
  # areas compared with y failed; the outline runs along ymax.
  skip_if_not_installed("ggplot2")
  d <- data.frame(x = rep(1:5, 2), y = c(1, 2, 3, 2, 1, 2, 2, 2, 2, 2), g = rep(c("a", "b"), each = 5))
  b <- bind_capture(ggplot2::ggplot(d, ggplot2::aes(.data$x, .data$y, fill = .data$g)) + ggplot2::geom_area())
  lv <- b$leaves[b$leaves$table %in% "built_layer1", ]
  expect_equal(sum(lv$mode == "group"), 4L)       # a polygon and an outline per group
  expect_equal(sum(lv$failed), 0L)
  geo <- scene_geometry(b$fig$substrate)
  tag <- geo$tag[match(lv$leaf, geo$leaf)]
  expect_true(all(lv$status[tag == "polygon"] == "verified"))
  # Stacked areas share a boundary: the lower area's outline (its ymax) is
  # the upper area's ymin, so another group's line passes as well. That
  # outline is ambiguous, not verified; the top area's outline is verified.
  expect_equal(sort(lv$status[tag == "polyline"]), c("ambiguous", "verified"))
})

test_that("a layer that draws nothing in a panel does not stop the layers after it from pairing", {
  # Development run 2026-11-11-1205, exts-022: a ggrepel layer with nothing
  # to label drew NULL, the panel held one child fewer than background +
  # layers + foreground, and none of its 12275 elements was paired.
  skip_if_not_installed("ggplot2")
  GeomNothing <- ggplot2::ggproto("GeomNothing", ggplot2::GeomPoint, draw_panel = function(...) NULL)
  nothing <- ggplot2::layer(geom = GeomNothing, stat = "identity", position = "identity")
  p <- ggplot2::ggplot(datasets::mtcars, ggplot2::aes(.data$wt, .data$mpg)) +
    ggplot2::geom_point() + nothing + ggplot2::geom_point(ggplot2::aes(y = .data$mpg + 5), colour = "red")
  b <- bind_capture(p)
  lv <- b$leaves[!is.na(b$leaves$table), ]
  expect_equal(lv$table, c("built_layer1", "built_layer3"))
  expect_equal(lv$status, c("verified", "verified"))
  expect_equal(sum(lv$verified), 64L)
})

test_that("a layer whose rows lack a position a comparison needs is unbound with the reason, not an error", {
  # Development run 2026-11-11-1319, patchwork-012: a boxplot's built rows
  # carry x, ymin, lower, middle, upper and ymax but no y; comparing its
  # polygons by vertex mean stopped the whole figure's binding with an error.
  skip_if_not_installed("ggplot2")
  p <- ggplot2::ggplot(datasets::mtcars, ggplot2::aes(.data$gear, .data$disp, group = .data$gear)) +
    ggplot2::geom_boxplot()
  b <- bind_capture(p)
  lv <- b$leaves[b$leaves$table %in% "built_layer1", ]
  expect_gt(nrow(lv), 0L)
  expect_false(any(lv$status %in% c("verified", "ambiguous")))
  ub <- lv[lv$status == "unbound", ]
  expect_gt(nrow(ub), 0L)
  expect_true(any(grepl("have no y", ub$reason)))
})

test_that("patchwork: a panel no plot owns has its layer leaves unbound and its grid outside", {
  # Development run 2026-11-11-1319, patchwork-006: a gtable added to the
  # composition had its panel's background and grid lines counted as
  # unbound layer leaves.
  skip_if_not_installed("patchwork")
  p1 <- ggplot2::ggplot(datasets::mtcars, ggplot2::aes(.data$wt, .data$mpg)) + ggplot2::geom_point()
  p2 <- ggplot2::ggplot(datasets::mtcars, ggplot2::aes(.data$hp, .data$qsec)) + ggplot2::geom_point()
  # ggplotGrob() measures text on the open device: build it on a null one,
  # so that no Rplots.pdf is written (the bench container's tree is read-only)
  g2 <- local({
    grDevices::pdf(NULL)
    on.exit(grDevices::dev.off())
    ggplot2::ggplotGrob(p2)
  })
  b <- bind_capture(p1 + g2)
  sl <- b$fig$substrate$leaves
  lv <- b$leaves
  stray <- lv[lv$status == "unbound", ]
  expect_equal(nrow(stray), 1L)
  expect_match(stray$reason, "belongs to no plot")
  expect_match(sl$path[sl$id == stray$leaf], "geom_point")
  expect_equal(lv$status[lv$table %in% "plot1_built_layer1"], "verified")
  grid_leaves <- sl$id[grepl("grill", sl$path)]
  expect_true(all(lv$status[lv$leaf %in% grid_leaves] == "outside"))
})

test_that("binding measures on a null device of its own: no default device, no silent fallback", {
  # Counting each layer's children draws the layers again after capture has
  # closed its device; text geoms then opened R's default device (writing
  # Rplots.pdf in the working directory) or, where none could be opened (the
  # bench container's read-only tree), the count failed and the binder fell
  # back to one child per layer without saying so.
  skip_if_not_installed("ggplot2")
  GeomNothing <- ggplot2::ggproto("GeomNothing", ggplot2::GeomPoint, draw_panel = function(...) NULL)
  nothing <- ggplot2::layer(geom = GeomNothing, stat = "identity", position = "identity")
  d <- data.frame(x = c(1, 2, 3, 4), y = c(2, 4, 1, 3), lab = c("a", "bb", "c", "dd"))
  p <- ggplot2::ggplot(d, ggplot2::aes(.data$x, .data$y, label = .data$lab)) +
    nothing + ggplot2::geom_label()
  # devices earlier tests left open would hide the defect
  grDevices::graphics.off()
  old <- options(device = function(...) stop("a default device was opened"))
  on.exit(options(old), add = TRUE)
  b <- bind_capture(p)
  lv <- b$leaves[!is.na(b$leaves$table), ]
  expect_equal(nrow(lv), 8L)
  expect_true(all(lv$status == "verified"))
})

# Base figures (plan Task 5): each data-mark entry's elements are paired with
# its arguments, put on the page through the entry's usr and log axes.

test_that("base: points, lines, bars, segments, text and symbols bind to their calls' arguments", {
  d <- datasets::mtcars
  page <- function() {
    graphics::par(mfrow = c(1, 2))
    graphics::plot(d$wt, d$mpg, pch = 19)
    graphics::lines(sort(d$wt), sort(d$mpg, decreasing = TRUE))
    graphics::segments(2, 15, 5, 30)
    graphics::text(c(3, 4), c(20, 25), c("a", "b"))
    graphics::rect(4.5, 10, 5.2, 14)
    graphics::symbols(3, 30, circles = 0.2, inches = FALSE, add = TRUE)
    graphics::barplot(table(d$gear))
  }
  b <- bind_capture(page)
  lv <- b$leaves[!is.na(b$leaves$table), ]
  sl <- b$fig$substrate$leaves
  cls <- sl$class[match(lv$leaf, sl$id)]
  expect_setequal(unique(lv$table), c("base_plotXY", "base_segments", "base_text", "base_rect", "base_symbols"))
  expect_true(all(lv$status %in% c("verified", "ambiguous")))
  expect_equal(sum(lv$verified + lv$ambiguous), 32 + 1 + 1 + 2 + 1 + 1 + 3)
  # points state their symbol and are paired part by part (plan
  # 2026-11-11-tree-binding, Task 6); the line through them by its group
  expect_equal(lv$mode[cls == "plotXY"], c("symbol", "group"))
  # axes, box and titles are not data-mark calls: outside
  expect_true(all(b$leaves$status[sl$class %in% c("axis", "box", "title")] == "outside"))
  # the tables hold the arguments, with the entry each row came from
  pts <- b$fig$tables[["base_plotXY"]]
  expect_false(is.null(pts))
})

test_that("base: points on log axes bind through log10, and a wrong row order fails", {
  x <- c(1, 10, 100, 1000)
  y <- c(5, 50, 2, 300)
  b <- bind_capture(function() graphics::plot(x, y, log = "xy", pch = 19))
  lv <- b$leaves[b$leaves$table %in% "base_plotXY", ]
  expect_equal(lv$status, "verified")
  expect_equal(lv$verified, 4L)
  # the same check with the rows reversed fails every point
  eng <- gl_plugin("engine", "base")
  res <- capture_figure(function() graphics::plot(x, y, log = "xy", pch = 19), eng, context = FALSE)
  stated <- eng$bind(res$state, res$fig$substrate)
  cl <- stated$claims[[1]]
  cl$pred[, c("x", "y")] <- cl$pred[rev(seq_len(nrow(cl$pred))), c("x", "y")]
  geo <- scene_geometry(res$fig$substrate)
  r <- check_claim(cl, res$fig$substrate$leaves[res$fig$substrate$leaves$id == cl$leaf, ], geo)
  expect_equal(r$leaf$status, "failed")
})

test_that("base: calls whose elements are not one per argument row are unbound with the reason", {
  b <- suppressWarnings(bind_capture(function() {
    graphics::plot(1:5, type = "b")
    graphics::arrows(1, 1, 3, 4)
  }))
  ub <- b$leaves[b$leaves$status == "unbound", ]
  expect_equal(nrow(ub), 2L)
  expect_match(ub$reason[1], "plotXY")
  expect_match(ub$reason[2], "heads")
})

# Labels in their own frame (plan 2026-11-11-tree-binding, Task 2). R's
# engine places a text from its row along the baseline by (hjust - the
# anchor svglite writes) times its width, and across it by vjust times the
# ascent of "M"; ggtree's tip labels use hjust = -.1 (bench tree-011, -060,
# -083: 128 rightly paired labels failed), and rotated labels were not
# compared at all (tree-072).

justified_claim <- function(p) {
  eng <- gl_plugin("engine", "ggplot")
  res <- suppressWarnings(capture_figure(p, eng, context = FALSE))
  stated <- eng$bind(res$state, res$fig$substrate)
  geo <- scene_geometry(res$fig$substrate)
  lv <- res$fig$substrate$leaves
  list(claims = stated$claims, geo = geo, leaves = lv)
}

test_that("text justified outside 0..1 or rotated verifies, and permuted labels fail", {
  skip_if_not_installed("ggplot2")
  d <- data.frame(x = c(1, 2, 3, 4, 5), y = c(1, 3, 2, 5, 4),
                  lab = c("bufonidae", "dendrobatidae", "hylidae", "centrolenidae", "Ab"))
  cases <- list(
    hjust_out = ggplot2::geom_text(hjust = -0.1),
    vjust_out = ggplot2::geom_text(vjust = -0.5),
    both_out = ggplot2::geom_text(hjust = 1.2, vjust = 1.5),
    inside = ggplot2::geom_text(hjust = 0.3, vjust = 0.8),
    rotated = ggplot2::geom_text(angle = 30, hjust = 0.3),
    rotated_out = ggplot2::geom_text(angle = -90, hjust = -0.2, vjust = -0.4)
  )
  for (nm in names(cases)) {
    p <- ggplot2::ggplot(d, ggplot2::aes(.data$x, .data$y, label = .data$lab)) + cases[[nm]] +
      ggplot2::xlim(0, 7) + ggplot2::ylim(0, 6)
    b <- suppressWarnings(bind_capture(p))
    lv <- b$leaves[b$leaves$table %in% "built_layer1", ]
    expect_equal(nrow(lv), 1L, label = nm)
    expect_equal(lv$status, "verified", label = nm)
    expect_lt(lv$max_dev, 0.05, label = paste(nm, "max_dev"))
    # the same leaf with its rows permuted fails on every label it moves
    j <- justified_claim(p)
    cl <- j$claims[[1]]
    perm <- c(2, 3, 4, 5, 1)
    bad <- cl
    bad$pred <- cl$pred[perm, ]
    r <- check_claim(bad, j$leaves[j$leaves$id == cl$leaf, ], j$geo)
    expect_equal(r$elements$status, rep("failed", 5L), label = paste(nm, "permuted"))
  }
})

test_that("label boxes are placed from their row by their justification, not by their vertex mean", {
  # Bench tree-041 and tree-045, run 2026-11-11-2224: label boxes failed by
  # 0.67-0.74 pt for these strings with plain geom_label(hjust = .5), with or
  # without showtext. ggplot2's labelGrob puts the box's centre at the row
  # moved by (0.5 - hjust) of its width and (0.5 - vjust) of its height; the
  # vertex mean of a rounded rectangle's polygon is not its centre.
  skip_if_not_installed("ggplot2")
  d <- data.frame(x = 1:6, y = 1:6, lab = c("bufonidae", "dendrobatidae", "ceratophryidae",
                                             "centrolenidae", "leptodactylidae", "hylidae"))
  for (hj in c(0.5, 0, 1)) {
    p <- ggplot2::ggplot(d, ggplot2::aes(.data$x, .data$y, label = .data$lab)) +
      ggplot2::geom_label(hjust = hj, vjust = 0.2) + ggplot2::xlim(-2, 9)
    b <- suppressWarnings(bind_capture(p))
    lv <- b$leaves[b$leaves$table %in% "built_layer1", ]
    sl <- b$fig$substrate$leaves
    boxes <- lv[sl$class[match(lv$leaf, sl$id)] != "text", ]
    expect_equal(nrow(boxes), 6L, label = paste("hjust", hj))
    expect_true(all(boxes$status == "verified"), label = paste("hjust", hj, "boxes"))
  }
})

# Polar coordinates (plan 2026-11-11-tree-binding, Task 3). Circular and fan
# tree layouts bound nothing (bench tree-025, -038, -057: 241 elements
# unbound, "the panel's scales cannot be mapped (CoordPolar)"). Rows go to
# the device through the coord's own transform; a segment under a
# non-linear coord is a path munched along it, its ends at the row's ends.

polar_plot <- function(layer, ...) {
  d <- data.frame(x = c(1, 2, 3, 4, 5), y = c(1, 3, 2, 5, 4), xend = c(2, 3, 4, 5, 1),
                  yend = c(2, 2, 4, 3, 5), lab = c("aa", "bbb", "c", "dddd", "ee"), ang = c(0, 30, 60, 90, 120))
  ggplot2::ggplot(d, ggplot2::aes(.data$x, .data$y)) + layer + ggplot2::coord_polar(...)
}

test_that("points, segments and rotated text under coord_polar() verify, and permuted rows fail", {
  skip_if_not_installed("ggplot2")
  layers <- list(
    points = ggplot2::geom_point(),
    segments = ggplot2::geom_segment(ggplot2::aes(xend = .data$xend, yend = .data$yend)),
    text = ggplot2::geom_text(ggplot2::aes(label = .data$lab, angle = .data$ang), hjust = -0.1),
    theta_y = ggplot2::geom_point()
  )
  for (nm in names(layers)) {
    p <- if (nm == "theta_y") polar_plot(layers[[nm]], theta = "y", start = 1, direction = -1) else polar_plot(layers[[nm]])
    b <- suppressWarnings(bind_capture(p))
    lv <- b$leaves[b$leaves$table %in% "built_layer1", ]
    expect_equal(nrow(lv), 1L, label = nm)
    expect_true(lv$status %in% c("verified", "ambiguous"), label = paste(nm, lv$status, lv$reason))
    expect_equal(lv$verified + lv$ambiguous, 5L, label = nm)
    j <- justified_claim(p)
    cl <- j$claims[[1]]
    bad <- cl
    bad$pred <- cl$pred[c(2, 3, 4, 5, 1), ]
    r <- check_claim(bad, j$leaves[j$leaves$id == cl$leaf, ], j$geo)
    expect_equal(r$elements$status, rep("failed", 5L), label = paste(nm, "permuted"))
  }
})

test_that("under coord_polar(), what the coord munches into paths without row ends is unbound with the reason", {
  skip_if_not_installed("ggplot2")
  # a line through its group's rows and a bar are drawn along the coord's
  # arcs: their vertices are not the rows' points, so they are not compared
  b <- suppressWarnings(bind_capture(polar_plot(ggplot2::geom_line())))
  lv <- b$leaves[b$leaves$table %in% "built_layer1", ]
  expect_equal(lv$status, "unbound")
  expect_match(lv$reason, "munched along the coord \\(CoordPolar\\)")
  bars <- ggplot2::ggplot(data.frame(g = c("a", "b", "c"), n = c(3, 5, 2)), ggplot2::aes(x = "", y = .data$n, fill = .data$g)) +
    ggplot2::geom_col() + ggplot2::coord_polar(theta = "y")
  b <- suppressWarnings(bind_capture(bars))
  lv <- b$leaves[b$leaves$table %in% "built_layer1", ]
  expect_true(all(lv$status == "unbound"))
  expect_match(lv$reason[1], "rectangles .*\\(CoordPolar\\)")
  expect_equal(sum(lv$failed), 0L)
  # labels stacked on the slices keep the stack's xmin..ymax in their rows;
  # they are text at (x, y), not rectangles (bench gallery-020, run
  # 2026-11-11-2303: its 5 labels were given the rectangles' reason)
  b <- suppressWarnings(bind_capture(bars + ggplot2::geom_text(ggplot2::aes(label = .data$g),
                                                               position = ggplot2::position_stack(vjust = 0.5))))
  lab <- b$leaves[b$leaves$table %in% "built_layer2", ]
  expect_equal(lab$status, "verified")
  expect_equal(lab$verified, 3L)
  expect_true(all(b$leaves$status[b$leaves$table %in% "built_layer1"] == "unbound"))
})

test_that("a path paired one per row whose row has ends verifies by its ends (geom_curve)", {
  skip_if_not_installed("ggplot2")
  d <- data.frame(x = c(1, 2, 3), y = c(1, 3, 2), xend = c(2, 3, 1), yend = c(3, 1, 3))
  p <- ggplot2::ggplot(d, ggplot2::aes(.data$x, .data$y, xend = .data$xend, yend = .data$yend)) + ggplot2::geom_curve()
  b <- suppressWarnings(bind_capture(p))
  lv <- b$leaves[b$leaves$table %in% "built_layer1", ]
  expect_equal(lv$status, "verified")
  expect_equal(lv$verified, 3L)
})

test_that("text drawn as glyph outlines is named as such, and never failed", {
  # The ggtree book's setup attaches emojifont, which turns showtext on: each
  # glyph is drawn as a path (bench tree-014, -041, -046, -054, -062). A
  # text leaf then drew one element per glyph, a count mismatch that did not
  # say why, or, with one glyph per label, passed the count and failed on
  # position as a shape (37 elements). Plan 2026-11-11-tree-binding, Task 4.
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("showtext")
  showtext::showtext_auto(TRUE)
  on.exit(showtext::showtext_auto(FALSE), add = TRUE)
  d <- data.frame(x = 1:3, y = 1:3, one = c("A", "B", "C"), many = c("Alpha", "Be ta", "C"))
  leaf_of <- function(col) {
    p <- ggplot2::ggplot(d, ggplot2::aes(.data$x, .data$y, label = .data[[col]])) + ggplot2::geom_text()
    b <- suppressWarnings(bind_capture(p))
    b$leaves[b$leaves$table %in% "built_layer1", ]
  }
  one <- leaf_of("one")
  expect_equal(one$status, "unbound")
  expect_equal(one$failed, 0L)
  expect_match(one$reason, "glyph outlines")
  expect_match(one$reason, "3 paths for 3 labels")
  many <- leaf_of("many")
  expect_equal(many$status, "count_mismatch")
  expect_match(many$reason, "glyph outlines")
  expect_match(many$reason, "10 paths for 3 labels with 10 characters other than spaces")
})

# Points drawn as several elements (plan 2026-11-11-tree-binding, Task 5).
# Bench tree-014's leaf of 8100 points in shapes 1-8 drew 12690 elements and
# was a count mismatch. Each row draws the parts its shape draws, in order,
# and each part's box holds the row's point at the fraction its symbol puts
# it (dev_docs/research/point-symbols); a dense leaf keeps those boxes.

shapes_plot <- function(n = 40, values = 1:8) {
  set.seed(4)
  d <- data.frame(x = stats::runif(n), y = stats::runif(n), k = factor(rep_len(seq_along(values), n)))
  ggplot2::ggplot(d, ggplot2::aes(.data$x, .data$y, shape = .data$k)) + ggplot2::geom_point(alpha = 0.6) +
    ggplot2::scale_shape_manual(values = values, guide = "none")
}

test_that("points in several shapes bind part by part, and permuted rows fail every part they move", {
  skip_if_not_installed("ggplot2")
  for (dense in c(Inf, 30)) {
    p <- shapes_plot()
    b <- suppressWarnings(bind_capture(p, dense = dense))
    lv <- b$leaves[b$leaves$table %in% "built_layer1", ]
    sl <- b$fig$substrate$leaves
    expect_equal(nrow(lv), 1L, label = paste("dense", dense))
    expect_equal(sl$dense[sl$id == lv$leaf], is.finite(dense), label = paste("dense", dense))
    # 40 rows in shapes 1-8, five of each: 5 x (1 + 1 + 2 + 2 + 1 + 1 + 3 + 4)
    expect_equal(lv$n_elements, 75L, label = paste("dense", dense))
    expect_equal(lv$n_rows, 40L)
    expect_equal(lv$mode, "symbol")
    expect_equal(lv$status, "verified", label = paste("dense", dense, lv$reason))
    expect_lt(lv$max_dev, 0.05)
    el <- b$elements[b$elements$leaf == lv$leaf, ]
    expect_equal(as.vector(table(factor(el$row, levels = 1:40))), rep(c(1, 1, 2, 2, 1, 1, 3, 4), 5))
  }
  # the rows permuted: every part of a moved row fails, by place or by tag
  eng <- gl_plugin("engine", "ggplot")
  res <- capture_figure(shapes_plot(), eng, context = FALSE)
  stated <- eng$bind(res$state, res$fig$substrate)
  cl <- stated$claims[[1]]
  geo <- scene_geometry(res$fig$substrate)
  leaf <- res$fig$substrate$leaves[res$fig$substrate$leaves$id == cl$leaf, ]
  expect_equal(check_claim(cl, leaf, geo)$leaf$status, "verified")
  # rotate the rows within each shape: parts keep their tags, every one moves
  bad <- cl
  for (s in unique(cl$pred$shape)) {
    k <- which(cl$pred$shape == s)
    bad$pred[k, c("x", "y")] <- cl$pred[k[c(2:length(k), 1)], c("x", "y")]
  }
  r <- check_claim(bad, leaf, geo)
  expect_equal(r$leaf$status, "failed")
  expect_equal(r$leaf$failed, 75L)
  # rows in another order of shapes: every part now paired with another row
  # than its own fails. A part the shift pairs with its own row again (the
  # next part of the same symbol) passes when it has the tag the stated
  # shape draws there, and fails on its tag when it does not.
  own <- check_claim(cl, leaf, geo)$elements$row
  bad <- cl
  bad$pred <- cl$pred[c(2:40, 1), ]
  r <- check_claim(bad, leaf, geo)
  moved <- r$elements$row != own
  want <- unlist(symbol_parts[symbol_kind(bad$pred$shape)], use.names = FALSE)
  tag <- geo$tag[match(r$elements$element, geo$id)]
  expect_gte(sum(moved), 40L)
  expect_true(all(r$elements$status[moved] == "failed"))
  expect_equal(r$elements$status[!moved], ifelse(tag[!moved] == want[!moved], "verified", "failed"))
  expect_true(any(tag[!moved] != want[!moved]))
})

test_that("all 26 shapes bind, and a shape the rows do not draw is not passed", {
  skip_if_not_installed("ggplot2")
  d <- data.frame(x = 1:26, y = c(1:13, 13:1), s = 0:25)
  p <- ggplot2::ggplot(d, ggplot2::aes(.data$x, .data$y, shape = .data$s)) + ggplot2::geom_point(fill = "grey", size = 4) +
    ggplot2::scale_shape_identity()
  b <- suppressWarnings(bind_capture(p))
  lv <- b$leaves[b$leaves$table %in% "built_layer1", ]
  expect_equal(lv$n_elements, 43L)
  expect_equal(lv$status, "verified", label = lv$reason)
  # rows that state other shapes than were drawn
  eng <- gl_plugin("engine", "ggplot")
  res <- capture_figure(p, eng, context = FALSE)
  cl <- eng$bind(res$state, res$fig$substrate)$claims[[1]]
  geo <- scene_geometry(res$fig$substrate)
  leaf <- res$fig$substrate$leaves[res$fig$substrate$leaves$id == cl$leaf, ]
  bad <- cl
  bad$pred$shape[bad$pred$shape == 2] <- 6   # upward triangle stated as downward: same parts, other place
  r <- check_claim(bad, leaf, geo)
  expect_equal(r$leaf$failed, 1L)
  # (a plus stated as a cross passes: both are two lines centred on the
  # point, and the rule checks where parts are, not what they look like)
  bad <- cl
  bad$pred$shape[bad$pred$shape == 3] <- 11  # two lines stated as two triangles: the tags differ
  r <- check_claim(bad, leaf, geo)
  expect_equal(r$leaf$failed, 2L)
  bad <- cl
  bad$pred$shape[bad$pred$shape == 8] <- 1   # four parts stated as one
  r <- check_claim(bad, leaf, geo)
  expect_equal(r$leaf$status, "unbound")
  expect_match(r$leaf$reason, "shapes .* 40 parts, the leaf drew 43")
})

test_that("a character symbol drawn as a glyph outline is checked by its box, and permuted rows fail", {
  # Bench tree-061 (emojifont turns showtext on): geom_point(shape = "|")
  # drew each symbol as a path, which the vertex-mean rule passed within
  # 0.49 pt of a 0.5 pt tolerance (run 2026-11-11-2344): luck, since the
  # vertex mean of an outline is 1.15 pt off at a larger size. R's engine
  # centres the character by its glyph's box, so the outline's box is
  # centred on the point across, and holds it along (side bearings):
  # dev_docs/research/point-symbols, glyph.R.
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("showtext")
  showtext::showtext_auto(TRUE)
  on.exit(showtext::showtext_auto(FALSE), add = TRUE)
  d <- data.frame(x = 1:4, y = c(2, 4, 1, 3))
  for (ch in c("|", "j")) for (sz in c(1.5, 10)) {
    p <- ggplot2::ggplot(d, ggplot2::aes(.data$x, .data$y)) + ggplot2::geom_point(shape = ch, size = sz)
    nm <- paste(ch, sz)
    b <- suppressWarnings(bind_capture(p))
    lv <- b$leaves[b$leaves$table %in% "built_layer1", ]
    expect_equal(lv$mode, "symbol", label = nm)
    expect_equal(lv$status, "verified", label = paste(nm, lv$reason))
    expect_lt(lv$max_dev, 0.05, label = nm)
    j <- justified_claim(p)
    cl <- j$claims[[1]]
    bad <- cl
    bad$pred <- cl$pred[c(2, 3, 4, 1), ]
    r <- check_claim(bad, j$leaves[j$leaves$id == cl$leaf, ], j$geo)
    expect_equal(r$elements$status, rep("failed", 4L), label = paste(nm, "permuted"))
  }
})

test_that("base points in several symbols bind part by part, and reversed rows fail", {
  x <- c(1, 3, 2, 5, 4, 6, 8, 7)
  y <- c(2, 1, 4, 3, 6, 5, 7, 8)
  page <- function() graphics::plot(x, y, pch = c(3, 8, 7, 1, 17, 11, 97, 4), cex = c(1, 2, 1, 0, 1, 1, 1, 1))
  b <- bind_capture(page)
  lv <- b$leaves[b$leaves$table %in% "base_plotXY", ]
  # the point at cex 0 is not drawn and has no row
  expect_equal(lv$n_rows, 7L)
  expect_equal(lv$n_elements, 2L + 4L + 3L + 1L + 2L + 1L + 2L)
  expect_equal(lv$mode, "symbol")
  expect_equal(lv$status, "verified", label = lv$reason)
  eng <- gl_plugin("engine", "base")
  res <- capture_figure(page, eng, context = FALSE)
  cl <- eng$bind(res$state, res$fig$substrate)$claims[[1]]
  # every row moved to the next one's place (no row left where it was)
  cl$pred[, c("x", "y")] <- cl$pred[c(2:nrow(cl$pred), 1L), c("x", "y")]
  r <- check_claim(cl, res$fig$substrate$leaves[res$fig$substrate$leaves$id == cl$leaf, ], scene_geometry(res$fig$substrate))
  expect_equal(r$leaf$status, "failed")
  expect_equal(r$leaf$failed, 15L)
})

# What remains on the tree stratum (plan 2026-11-11-tree-binding, Task 6).

test_that("rows ggplot2 drops before drawing are not paired (NA labels)", {
  # Bench tree-003: geom_text2() labels the inner nodes; the tips' labels are
  # NA, which Geom$handle_na() drops before drawing, while the built rows
  # keep them (11 rows, 5 drawn: unbound, "neither one per row nor one per
  # group").
  skip_if_not_installed("ggplot2")
  d <- data.frame(x = 1:5, y = c(2, 4, 1, 3, 5), lab = c("a", NA, "ccc", NA, "e"))
  p <- ggplot2::ggplot(d, ggplot2::aes(.data$x, .data$y, label = .data$lab)) + ggplot2::geom_text(na.rm = TRUE)
  b <- suppressWarnings(bind_capture(p))
  lv <- b$leaves[b$leaves$table %in% "built_layer1", ]
  expect_equal(lv$status, "verified", label = lv$reason)
  expect_equal(c(lv$n_elements, lv$n_rows), c(3L, 3L))
  expect_equal(b$elements$row[b$elements$leaf == lv$leaf], c(1L, 3L, 5L))
})

test_that("a geom that moves x by its nudge_x when drawing is checked at the moved place", {
  # Bench tree-041: ggtree's GeomSegmentGGtree$draw_panel() adds its
  # parameter nudge_x to x (not xend) before the coord's transform; the built
  # rows do not hold it (6 dotted lines failed by up to 128 pt). ggimage's
  # GeomImage does the same with nudge_x and nudge_y.
  skip_if_not_installed("ggplot2")
  GeomNudged <- ggplot2::ggproto("GeomNudged", ggplot2::GeomSegment,
    draw_panel = function(self, data, panel_params, coord, nudge_x = 0, lineend = "butt") {
      data$x <- data$x + nudge_x
      ggplot2::GeomSegment$draw_panel(data, panel_params, coord, lineend = lineend)
    })
  d <- data.frame(x = c(1, 2, 3), y = c(1, 3, 2), xend = c(5, 5, 5), yend = c(1, 3, 2))
  p <- ggplot2::ggplot(d, ggplot2::aes(.data$x, .data$y, xend = .data$xend, yend = .data$yend)) +
    ggplot2::layer(geom = GeomNudged, stat = "identity", position = "identity", params = list(nudge_x = 0.5)) +
    ggplot2::xlim(0, 6)
  b <- suppressWarnings(bind_capture(p))
  lv <- b$leaves[b$leaves$table %in% "built_layer1", ]
  expect_equal(lv$status, "verified", label = paste(lv$status, lv$max_dev))
  expect_lt(lv$max_dev, 0.05)
})

test_that("images bind: one per row by their box, one raster per group by its cells' bounds", {
  # Bench tree-041 (ggimage: a rasterGrob centred on each row) and v0's
  # gallery-015 (geom_raster(): one image over all its cells) were unbound,
  # "no comparison for <image> elements".
  skip_if_not_installed("ggplot2")
  img <- matrix(c("red", "blue", "green", "white"), 2)
  GeomPic <- ggplot2::ggproto("GeomPic", ggplot2::Geom, required_aes = c("x", "y"),
    draw_panel = function(data, panel_params, coord) {
      co <- coord$transform(data, panel_params)
      kids <- lapply(seq_len(nrow(co)), function(i) grid::rasterGrob(img, x = co$x[i], y = co$y[i], height = grid::unit(0.1, "npc")))
      grid::gTree(children = do.call(grid::gList, kids))
    })
  d <- data.frame(x = c(1, 3, 2, 5), y = c(2, 1, 4, 3))
  p <- ggplot2::ggplot(d, ggplot2::aes(.data$x, .data$y)) +
    ggplot2::layer(geom = GeomPic, stat = "identity", position = "identity") + ggplot2::xlim(0, 6) + ggplot2::ylim(0, 5)
  b <- suppressWarnings(bind_capture(p))
  lv <- b$leaves[b$leaves$table %in% "built_layer1", ]
  expect_equal(nrow(lv), 4L)
  expect_true(all(lv$status == "verified"), label = paste(lv$status, lv$reason, collapse = "; "))
  # each image against another row fails
  j <- justified_claim(p)
  for (cl in j$claims) {
    bad <- cl
    bad$pred[, c("x", "y")] <- cl$pred[c(2:4, 1), c("x", "y")]
    r <- check_claim(bad, j$leaves[j$leaves$id == cl$leaf, ], j$geo)
    expect_equal(r$leaf$status, "failed")
  }
  # a raster over a grid of cells
  g <- expand.grid(x = 1:4, y = 1:3)
  g$z <- seq_len(nrow(g))
  p <- ggplot2::ggplot(g, ggplot2::aes(.data$x, .data$y, fill = .data$z)) + ggplot2::geom_raster()
  b <- suppressWarnings(bind_capture(p))
  lv <- b$leaves[b$leaves$table %in% "built_layer1", ]
  expect_equal(c(lv$mode, lv$status), c("group", "verified"), label = lv$reason)
  # the rows' cells one column narrower than what was drawn: failed
  j <- justified_claim(p)
  cl <- j$claims[[1]]
  bad <- cl
  w <- (max(cl$pred$xmax) - min(cl$pred$xmin)) / 4
  bad$pred$xmax <- cl$pred$xmax - w * (cl$pred$xmax == max(cl$pred$xmax))
  r <- check_claim(bad, j$leaves[j$leaves$id == cl$leaf, ], j$geo)
  expect_equal(r$leaf$status, "failed")
})

test_that("leaves a layer's grob makes only when drawn are unbound with that reason, never failed", {
  # Bench tree-054 (geom_label_repel()): the layer's grob has no children in
  # the built gtable; ggrepel makes the boxes, connectors and texts when it
  # is drawn (makeContent), placed away from their rows. Each leaf was
  # paired with all the layer's rows: 41 boxes failed, 28 connectors and 41
  # texts unbound or count mismatches.
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("ggrepel")
  set.seed(5)
  d <- data.frame(x = c(1, 1.02, 1.04, 1.06, 2), y = c(1, 1.01, 1.02, 1.03, 2), lab = c("alpha", "beta", "gamma", "delta", "eps"))
  for (geom in c("label", "text")) {
    layer <- if (geom == "label") ggrepel::geom_label_repel(seed = 1, min.segment.length = 0) else ggrepel::geom_text_repel(seed = 1, min.segment.length = 0)
    p <- ggplot2::ggplot(d, ggplot2::aes(.data$x, .data$y, label = .data$lab)) + ggplot2::geom_point() + layer
    b <- suppressWarnings(bind_capture(p))
    lv <- b$leaves[b$leaves$leaf %in% b$fig$substrate$leaves$id[grepl("repeltree", b$fig$substrate$leaves$path)], ]
    expect_gt(nrow(lv), 5L)
    expect_true(all(lv$status == "unbound"), label = paste(geom, paste(unique(lv$status), collapse = ",")))
    expect_true(all(grepl("makes what it draws when it is drawn", lv$reason)), label = geom)
    expect_true(all(b$elements$status[b$elements$leaf %in% lv$leaf] == "unbound"))
    expect_equal(sum(b$leaves$failed), 0L, label = geom)
    # the points of the same plot still bind
    expect_equal(b$leaves$status[b$leaves$table %in% "built_layer1"], "verified", label = geom)
  }
})

test_that("a failed leaf that is a passing sibling moved by one offset is unbound as a copy", {
  # Bench tree-072 (shadowtext): each label is drawn 17 times, 16 copies
  # moved 0.1 x the height of "X" in 16 directions, then the label; 10 copy
  # leaves failed by 0.57-0.81 pt, rightly paired.
  skip_if_not_installed("ggplot2")
  GeomHalo <- ggplot2::ggproto("GeomHalo", ggplot2::Geom, required_aes = c("x", "y", "label"),
    draw_panel = function(data, panel_params, coord) {
      co <- coord$transform(data, panel_params)
      at <- function(dx, dy, lab = co$label) grid::textGrob(lab, x = grid::unit(co$x, "npc") + grid::unit(dx, "bigpts"),
                                                            y = grid::unit(co$y, "npc") + grid::unit(dy, "bigpts"))
      grid::gTree(children = grid::gList(at(1.5, 0), at(-1.5, 0), at(0, 0.3), at(1.5, 0, rev(co$label)), at(0, 0)))
    })
  d <- data.frame(x = c(1, 2, 3), y = c(1, 3, 2), lab = c("ab", "cde", "f"))
  p <- ggplot2::ggplot(d, ggplot2::aes(.data$x, .data$y, label = .data$lab)) +
    ggplot2::layer(geom = GeomHalo, stat = "identity", position = "identity") + ggplot2::xlim(0, 4) + ggplot2::ylim(0, 4)
  b <- suppressWarnings(bind_capture(p))
  lv <- b$leaves[b$leaves$table %in% "built_layer1", ]
  expect_equal(nrow(lv), 5L)
  # the label and the copy moved within its row's box pass
  expect_equal(lv$status[c(3, 5)], c("verified", "verified"))
  # the copies moved 1.5 pt along the baseline: copies of the label, not failed
  expect_equal(lv$status[1:2], c("unbound", "unbound"))
  expect_match(lv$reason[1], "copy of L[0-9]+ moved by \\(1\\.50, 0\\.00\\) pt")
  expect_match(lv$reason[2], "copy of L[0-9]+ moved by \\(-1\\.50, 0\\.00\\) pt")
  # the copy with its labels in another order is not a copy: still failed
  expect_equal(lv$status[4], "failed")
})
