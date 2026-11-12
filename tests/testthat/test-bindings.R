# Bindings as a derived table of the figure: computed at capture, read
# through gl_bindings(), kept by the bundle (ADR-0007; plan
# 2026-11-11-m1-roles-and-binding, Task 6a). How a pairing is checked is
# tested in test-bind.R; here, where the result lives and how it is read.

p_cars <- function() ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()

p_lines <- function() {
  d <- data.frame(x = rep(1:5, 2), y = c(1, 3, 2, 5, 4, 2, 2, 4, 3, 6), g = rep(c("a", "b"), each = 5))
  ggplot2::ggplot(d, ggplot2::aes(x, y, group = g)) + ggplot2::geom_line()
}

test_that("a captured figure carries its bindings and gl_bindings() reads them", {
  skip_if_no("ggplot2")
  fig <- gloss(p_cars(), width = 7, height = 5, context = FALSE)
  b <- gl_bindings(fig)
  expect_named(b, c("element", "leaf", "table", "row", "n_rows", "status", "dev"))
  expect_equal(nrow(b), 32L)
  expect_setequal(b$row, 1:32)
  expect_equal(unique(b$table), "built_layer1")
  expect_true(all(b$status == "verified"))
  expect_true(all(b$element %in% gl_elements(fig)$id))
  # the element is where its row says: the dot's centre, taken back to data
  # space, is the row's wt and mpg
  el <- gl_elements(fig, where = list(id = b$element[7]))
  at <- gl_to_data(fig, el$panel, (el$x0 + el$x1) / 2, (el$y0 + el$y1) / 2)
  built <- gl_table(fig, "built_layer1")
  expect_equal(c(at$x, at$y), c(built$x[b$row[7]], built$y[b$row[7]]), tolerance = 1e-2)
  # who made them, and with what tolerance
  d <- fig$derived$bindings
  expect_equal(d$by$name, "ggplot")
  expect_equal(d$by$version, gl_plugin("engine", "ggplot")$version)
  expect_equal(d$params$tolerance, 0.5)
})

test_that("the stored bindings are those of the internal bind step", {
  skip_if_no("ggplot2")
  fig <- suppressWarnings(gloss(p_facet(), width = 7, height = 4, context = FALSE))
  ref <- suppressWarnings(bind_capture(p_facet(), width = 7, height = 4))
  # two captures of one plot: the same elements (grid numbers its grobs anew)
  expect_identical(fig$substrate$elements, ref$fig$substrate$elements)
  got <- gl_bindings(fig)
  expect_identical(got[c("element", "leaf", "table", "row", "n_rows", "status")],
                   ref$elements[c("element", "leaf", "table", "row", "n_rows", "status")])
  # deviations are kept to 1/1000 pt: within half of that of the unrounded
  expect_identical(is.na(got$dev), is.na(ref$elements$dev))
  expect_true(all(abs(got$dev - ref$elements$dev) <= 5e-4 + 1e-9, na.rm = TRUE))
  expect_identical(got$dev, round(got$dev * 1000) / 1000)
  lv <- gl_bindings(fig, by = "leaf")
  expect_identical(lv[setdiff(names(lv), "max_dev")], ref$leaves[setdiff(names(ref$leaves), "max_dev")])
  expect_identical(lv$leaf, fig$substrate$leaves$id)
})

test_that("by = 'row' gives every row an element draws, a group's rows included", {
  skip_if_no("ggplot2")
  fig <- gloss(p_lines(), width = 5, height = 4, context = FALSE)
  el <- gl_bindings(fig)
  expect_equal(nrow(el), 2L)
  expect_equal(el$n_rows, c(5L, 5L))
  expect_equal(el$status, c("verified", "verified"))
  r <- gl_bindings(fig, by = "row")
  expect_named(r, c("element", "leaf", "table", "row", "status"))
  expect_equal(nrow(r), 10L)
  expect_equal(r$row[r$element == el$element[1]], 1:5)
  expect_equal(r$row[r$element == el$element[2]], 6:10)
  # one element per row: the same pairs as by = "element"
  fig2 <- gloss(p_cars(), width = 7, height = 5, context = FALSE)
  e2 <- gl_bindings(fig2)
  r2 <- gl_bindings(fig2, by = "row")
  expect_identical(r2, e2[c("element", "leaf", "table", "row", "status")])
})

test_that("where filters any view, and an unknown field is refused", {
  skip_if_no("ggplot2")
  fig <- suppressWarnings(gloss(p_facet(), width = 7, height = 4, context = FALSE))
  all_el <- gl_bindings(fig)
  one_leaf <- all_el$leaf[1]
  expect_identical(gl_bindings(fig, where = list(leaf = one_leaf)),
                   `rownames<-`(all_el[all_el$leaf == one_leaf, ], NULL))
  hit <- gl_bindings(fig, by = "row", where = list(table = "built_layer1", row = 3L))
  expect_equal(nrow(hit), 1L)
  expect_equal(hit$element, all_el$element[all_el$table %in% "built_layer1" & all_el$row %in% 3L])
  lv <- gl_bindings(fig, by = "leaf", where = list(status = "outside"))
  expect_true(nrow(lv) > 0L && all(lv$status == "outside"))
  expect_error(gl_bindings(fig, where = list(colour = "red")), "Unknown binding field")
})

test_that("an engine that states no bindings gives every leaf the reason", {
  g <- grid::gTree(children = grid::gList(grid::circleGrob(r = 0.1), grid::rectGrob(width = 0.5, height = 0.5)))
  fig <- gloss(g, width = 3, height = 3, context = FALSE)
  expect_equal(nrow(gl_bindings(fig)), 0L)
  lv <- gl_bindings(fig, by = "leaf")
  expect_equal(lv$leaf, fig$substrate$leaves$id)
  expect_true(all(lv$status == "unbound"))
  expect_match(lv$reason, "states no bindings")
})

test_that("bind = FALSE skips the step and the query says so", {
  skip_if_no("ggplot2")
  fig <- gloss(p_cars(), width = 4, height = 3, context = FALSE, bind = FALSE)
  expect_null(fig$derived$bindings)
  w <- fig$status$withheld
  expect_equal(w$what, "bindings")
  expect_match(w$reason, "bind = FALSE")
  expect_error(gl_bindings(fig), "bind = FALSE")
  expect_output(print(fig), "withheld bindings")
  # the substrate is the same either way
  expect_identical(fig$substrate$elements,
                   gloss(p_cars(), width = 4, height = 3, context = FALSE)$substrate$elements)
})

test_that("a bind step that fails does not fail the capture; the reason is kept", {
  skip_if_no("ggplot2")
  eng <- gl_plugin("engine", "ggplot")
  broken <- eng
  broken$name <- "ggplot_broken_bind"
  broken$bind <- function(state, substrate) {
    list(claims = list(list(leaf = substrate$leaves$id[1], table = "built_layer1", pred = "not a table")))
  }
  fig <- gl_capture(p_cars(), broken, width = 4, height = 3, context = FALSE)
  expect_s3_class(fig, "gloss_figure")
  expect_null(fig$derived$bindings)
  w <- fig$status$withheld
  expect_equal(w$what, "bindings")
  expect_match(w$reason, "the bind step failed")
  expect_error(gl_bindings(fig), "the bind step failed")
})

test_that("bindings survive the bundle in every form", {
  skip_if_no("ggplot2")
  figs <- list(facet = suppressWarnings(gloss(p_facet(), width = 7, height = 4, context = FALSE)),
               lines = gloss(p_lines(), width = 5, height = 4, context = FALSE))
  for (nm in names(figs)) {
    fig <- figs[[nm]]
    for (path in c(withr::local_tempfile(fileext = ".html"), withr::local_tempfile(fileext = ".svg"),
                   file.path(withr::local_tempdir(), "x.gloss"))) {
      gl_write(fig, path)
      back <- gl_read(path)
      expect_identical(back$derived, fig$derived, label = paste(nm, path))
      for (by in c("element", "leaf", "row")) {
        expect_identical(gl_bindings(back, by = by), gl_bindings(fig, by = by), label = paste(nm, by))
      }
    }
  }
  d <- file.path(withr::local_tempdir(), "y.gloss")
  gl_write(figs$facet, d)
  expect_true(all(c("substrate/derived/bindings/elements.json", "substrate/derived/bindings/leaves.json",
                    "substrate/derived/bindings/rows.json") %in% list.files(d, recursive = TRUE)))
  man <- jsonlite::read_json(file.path(d, "manifest.json"))
  expect_equal(man$derived$bindings$by$name, "ggplot")
})

test_that("a figure written without bindings reads back without them, and says so", {
  skip_if_no("ggplot2")
  fig <- gloss(p_cars(), width = 4, height = 3, context = FALSE, bind = FALSE)
  f <- withr::local_tempfile(fileext = ".html")
  gl_write(fig, f)
  back <- gl_read(f)
  expect_null(back$derived$bindings)
  expect_error(gl_bindings(back), "bind = FALSE")
  # a bundle from before bindings were stored: no derived files, no reason
  files <- bundle_files(fig)
  man <- json_read(bytes_text(files[["manifest.json"]]))
  man$status <- list()
  man$derived <- NULL
  files[["manifest.json"]] <- as_bytes(json_write(man))
  old <- figure_from_files(files)
  expect_error(gl_bindings(old), "holds no bindings")
  # geometry read from a plain SVG has none either
  svg <- withr::local_tempfile(fileext = ".svg")
  writeLines(c("<svg xmlns='http://www.w3.org/2000/svg' width='72pt' height='36pt' viewBox='0 0 72 36'>",
               "<circle cx='10' cy='10' r='2'/></svg>"), svg)
  expect_error(gl_bindings(gl_read(svg)), "holds no bindings")
})

test_that("a dense leaf's bindings travel compactly", {
  skip_if_no("ggplot2")
  set.seed(4)
  d <- data.frame(x = rnorm(12000), y = rnorm(12000))
  p <- ggplot2::ggplot(d, ggplot2::aes(x, y)) + ggplot2::geom_point(size = 0.3)
  fig <- gloss(p, width = 5, height = 4, context = FALSE)
  expect_equal(nrow(gl_bindings(fig)), 12000L)
  files <- bundle_files(fig)
  el <- json_read(bytes_text(files[["substrate/derived/bindings/elements.json"]]))
  # elements and leaves by position, repeated strings by code, deviations
  # in thousandths: no column stored as 12000 strings or doubles
  enc <- vapply(el$columns, function(col) col$encoding %||% "text", "")
  expect_true(all(enc == "i32le-shuffle-base64"))
  f <- withr::local_tempfile(fileext = ".html")
  gl_write(fig, f)
  expect_identical(gl_read(f)$derived, fig$derived)
})
