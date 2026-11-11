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

test_that("patchwork leaves are unbound: the engine states no bindings yet", {
  skip_if_not_installed("patchwork")
  p <- ggplot2::ggplot(datasets::mtcars, ggplot2::aes(.data$wt, .data$mpg)) + ggplot2::geom_point()
  b <- bind_capture(patchwork::wrap_plots(p, p))
  expect_true(all(b$leaves$status == "unbound"))
  expect_match(b$leaves$reason[1], "engine 'patchwork' states no bindings")
})
