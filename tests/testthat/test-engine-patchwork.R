test_that("patchwork engine captures side-by-side and nested compositions with namespaced IR", {
  skip_if_not_installed("patchwork")
  skip_if_not_installed("ggplot2")

  p1 <- ggplot2::ggplot(datasets::mtcars, ggplot2::aes(.data$wt, .data$mpg, colour = factor(.data$cyl))) +
    ggplot2::geom_point() +
    ggplot2::labs(title = "Scatter")
  p2 <- ggplot2::ggplot(datasets::mtcars, ggplot2::aes(factor(.data$cyl))) +
    ggplot2::geom_bar() +
    ggplot2::labs(title = "Counts")
  p3 <- ggplot2::ggplot(datasets::mtcars, ggplot2::aes(.data$wt, .data$hp)) +
    ggplot2::geom_point() +
    ggplot2::facet_wrap(~ am) +
    ggplot2::labs(title = "Faceted HP")

  pw <- (p1 | p2) / p3 + patchwork::plot_annotation(title = "Combined Study")
  cap <- gloss(pw, width = 8, height = 6)

  expect_true(is_gloss_capture(cap))
  expect_identical(cap$page$engine, "patchwork")
  expect_identical(cap$page$draw_method, "patchworkGrob")
  expect_identical(cap$page$pages, 1L)

  # 4 panels total: p1_P1, p2_P1, p3_P1, p3_P2
  pids <- vapply(cap$ir$panels, `[[`, character(1L), "panel_id")
  expect_identical(pids, c("p1_P1", "p2_P1", "p3_P1", "p3_P2"))
  expect_true(all(vapply(cap$ir$panels, function(p) length(p$bbox_pt) == 4L, logical(1L))))

  # Tables are cleanly namespaced per subplot
  expect_true(all(c(
    "p1_raw", "p1_built_layer1",
    "p2_raw", "p2_built_layer1",
    "p3_raw", "p3_built_layer1"
  ) %in% names(cap$tables)))

  # Globally unique layer IDs across subplots
  lids <- vapply(cap$ir$layers, `[[`, integer(1L), "layer_id")
  expect_identical(lids, c(1L, 2L, 3L))

  # Lineage links every subplot's data leaf cleanly
  linked <- cap$lineage[!is.na(cap$lineage$layer_id), ]
  expect_equal(nrow(linked), 4L)
  expect_identical(linked$panel_id, c("p1_P1", "p2_P1", "p3_P1", "p3_P2"))
  expect_identical(linked$cardinality, c("1:1", "stat_aggregated", "1:1", "1:1"))

  # gl_query by subplot panel isolates p2 cleanly
  q_p2 <- gl_query(cap, panel = "p2_P1")
  expect_true(all(q_p2$lineage$panel_id == "p2_P1"))
  expect_identical(names(q_p2$tables), "p2_built_layer1")
})

test_that("patchwork engine works with wrap_plots and packages into a valid bundle", {
  skip_if_not_installed("patchwork")
  skip_if_not_installed("ggplot2")

  p1 <- ggplot2::ggplot(datasets::mtcars, ggplot2::aes(.data$wt, .data$mpg)) + ggplot2::geom_point()
  p2 <- ggplot2::ggplot(datasets::mtcars, ggplot2::aes(.data$disp, .data$hp)) + ggplot2::geom_point()
  pw <- patchwork::wrap_plots(p1, p2, ncol = 2)

  cap <- gloss(pw)
  expect_identical(cap$page$engine, "patchwork")
  expect_equal(length(cap$ir$panels), 2L)

  tmp <- withr::local_tempdir()
  bdir <- gl_asset_bundle(cap, path = file.path(tmp, "pw.gloss"))
  expect_true(file.exists(file.path(bdir, "asset-map.json")))
  expect_true(file.exists(file.path(bdir, "tables/p1_built_layer1.csv")))
  expect_true(file.exists(file.path(bdir, "tables/p2_built_layer1.csv")))
})

test_that("patchwork engine skips plot_spacer() and wrap_elements() without phantom panels", {
  skip_if_not_installed("patchwork")
  skip_if_not_installed("ggplot2")

  p1 <- ggplot2::ggplot(datasets::mtcars, ggplot2::aes(.data$wt, .data$mpg, colour = factor(.data$cyl))) +
    ggplot2::geom_point()
  p2 <- ggplot2::ggplot(datasets::mtcars, ggplot2::aes(factor(.data$cyl), fill = factor(.data$cyl))) +
    ggplot2::geom_bar()

  pw_sp <- p1 + patchwork::plot_spacer() + p2 + patchwork::plot_layout(guides = "collect")
  cap_sp <- gloss(pw_sp)
  expect_identical(vapply(cap_sp$ir$panels, `[[`, character(1L), "panel_id"), c("p1_P1", "p2_P1"))
  linked_sp <- cap_sp$lineage[!is.na(cap_sp$lineage$layer_id), ]
  expect_identical(linked_sp$panel_id, c("p1_P1", "p2_P1"))

  pw_we <- patchwork::wrap_elements(grid::rectGrob(gp = grid::gpar(fill = "grey90"))) + p1
  cap_we <- gloss(pw_we)
  expect_identical(vapply(cap_we$ir$panels, `[[`, character(1L), "panel_id"), "p1_P1")
  expect_equal(nrow(cap_we$lineage[!is.na(cap_we$lineage$layer_id), ]), 1L)
})
