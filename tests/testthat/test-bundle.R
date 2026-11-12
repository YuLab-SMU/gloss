files_equal <- function(a, b) {
  fa <- sort(list.files(a, recursive = TRUE))
  fb <- sort(list.files(b, recursive = TRUE))
  if (!identical(fa, fb)) return(FALSE)
  all(vapply(fa, function(f) {
    identical(readBin(file.path(a, f), "raw", file.size(file.path(a, f))),
              readBin(file.path(b, f), "raw", file.size(file.path(b, f))))
  }, logical(1)))
}

test_that("directory -> single file -> directory is byte-identical", {
  skip_if_no("ggplot2")
  fig <- suppressWarnings(gloss(p_facet(), width = 7, height = 4))
  d1 <- withr::local_tempdir()
  d2 <- withr::local_tempdir()
  gl_write(fig, file.path(d1, "fig.gloss"), embed = "all")
  for (ext in c("html", "svg")) {
    single <- withr::local_tempfile(fileext = paste0(".", ext))
    gl_write(gl_read(file.path(d1, "fig.gloss")), single, embed = "all")
    gl_write(gl_read(single), file.path(d2, paste0(ext, ".gloss")), embed = "all")
    expect_true(files_equal(file.path(d1, "fig.gloss"), file.path(d2, paste0(ext, ".gloss"))), label = ext)
  }
})

test_that("a figure read back from a bundle is identical to the one written", {
  skip_if_no("ggplot2")
  fig <- suppressWarnings(gloss(p_facet(), width = 7, height = 4))
  for (path in c(withr::local_tempfile(fileext = ".html"), withr::local_tempfile(fileext = ".svg"),
                 file.path(withr::local_tempdir(), "x.gloss"))) {
    gl_write(fig, path, embed = "all")
    back <- gl_read(path)
    expect_identical(back$substrate, fig$substrate, label = path)
    expect_identical(back$tables, fig$tables, label = path)
    expect_identical(back$meta, fig$meta, label = path)
    expect_identical(back$plugins, fig$plugins, label = path)
    expect_identical(back$status, fig$status, label = path)
    expect_equal(back$context, fig$context, label = path)
  }
})

test_that("withheld tables and panels keep their reasons through a bundle", {
  skip_if_no("ggplot2")
  registerS3method("print", "gloss_test_bundle_print", function(x, ...) {
    y <- x
    class(y) <- setdiff(class(x), "gloss_test_bundle_print")
    print(y)
    invisible(x)
  }, envir = baseenv())
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  class(p) <- c("gloss_test_bundle_print", class(p))
  fig <- gloss(p, width = 4, height = 3, context = FALSE)
  expect_equal(nrow(fig$status$withheld), 2L)
  for (path in c(withr::local_tempfile(fileext = ".html"), file.path(withr::local_tempdir(), "x.gloss"))) {
    gl_write(fig, path, embed = "all")
    back <- gl_read(path)
    expect_identical(back$status, fig$status, label = path)
    expect_identical(back$meta, fig$meta, label = path)
  }
})

test_that("dense leaves round-trip through the index and raster", {
  skip_if_no("ggplot2")
  set.seed(4)
  d <- data.frame(x = rnorm(3000), y = rnorm(3000), g = sample(letters[1:3], 3000, TRUE))
  p <- ggplot2::ggplot(d, ggplot2::aes(x, y, colour = g)) + ggplot2::geom_point()
  fig <- gloss(p, width = 5, height = 4, dense = 1000, context = FALSE)
  expect_true(any(fig$substrate$leaves$dense))
  f <- withr::local_tempfile(fileext = ".html")
  gl_write(fig, f)
  back <- gl_read(f)
  expect_identical(back$substrate, fig$substrate)
  html <- paste(readLines(f, warn = FALSE), collapse = "\n")
  expect_true(grepl("data:image/png;base64,", html, fixed = TRUE))
  expect_false(grepl("gloss-raster:", html, fixed = TRUE))
})

test_that("embed modes control which data travel", {
  skip_if_no("ggplot2")
  df <- data.frame(name = paste0("n", 1:5), a = 1:5, b = c(2, 4, 6, 8, 10), unused = letters[1:5])
  p <- ggplot2::ggplot(df, ggplot2::aes(a, b, label = name)) + ggplot2::geom_text()
  fig <- gloss(p, width = 4, height = 3)
  expect_equal(fig$tables$raw$key, "name")
  expect_equal(fig$tables$raw$key_rule, 2L)
  f <- withr::local_tempfile(fileext = ".html")

  gl_write(fig, f, embed = "default")
  back <- gl_read(f)
  expect_setequal(names(gl_table(back, "raw")), c("name", "a", "b"))
  expect_equal(back$tables$raw$status, "partial_data")
  expect_identical(gl_table(back, "built_layer1"), gl_table(fig, "built_layer1"))

  gl_write(fig, f, embed = "summary")
  back <- gl_read(f)
  expect_null(gl_table(back, "raw"))
  expect_equal(back$status$missing_data, names(fig$tables))
  expect_equal(back$tables$raw$summary$column, names(df))
  expect_equal(back$tables$raw$key, "name")

  gl_write(fig, f, embed = "none")
  back <- gl_read(f)
  expect_null(back$tables$raw$summary)
  expect_null(back$context$data$value$tables[[1]]$columns)
  expect_identical(back$substrate$elements, fig$substrate$elements)
})

test_that("a bundle whose plugin is not installed still restores", {
  skip_if_no("ggplot2")
  fig <- gloss(ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point(), width = 4, height = 3)
  fig$plugins <- rbind(fig$plugins, data.frame(kind = "engine", name = "survival", version = "0.3.0",
                                               package = "ggsurvx", stringsAsFactors = FALSE))
  f <- withr::local_tempfile(fileext = ".html")
  gl_write(fig, f)
  back <- gl_read(f)
  expect_equal(back$status$missing_plugins$name, "survival")
  expect_identical(back$substrate$elements, fig$substrate$elements)
})

test_that("an SVG without an embedded bundle restores geometry only", {
  skip_if_no("ggplot2")
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  f <- withr::local_tempfile(fileext = ".svg")
  svglite::svglite(f, 4, 3)
  print(p)
  grDevices::dev.off()
  fig <- gl_read(f)
  expect_match(fig$status$restored, "geometry only")
  expect_equal(sum(fig$substrate$elements$tag == "circle"), 32L)
  expect_true(all(is.na(fig$substrate$elements$leaf)))
  expect_equal(fig$meta$width, 4)
})

test_that("an SVG from outside with a node over the parser's limit is refused with the reason", {
  # gloss's own pages are parsed without libxml2's 10^7-byte limit (plan
  # 2026-11-11-tree-binding, Task 1); a document from outside keeps it, and
  # what the parser refuses is refused with its reason, not its bare error.
  f <- withr::local_tempfile(fileext = ".svg")
  writeLines(paste0('<svg xmlns="http://www.w3.org/2000/svg" width="72pt" height="72pt">',
                    '<image width="72" height="72" href="data:image/png;base64,',
                    strrep("A", 1.1e7), '"/></svg>'), f)
  expect_error(gl_read(f), "XML parser refused")
  expect_error(gl_read(f), "read only from pages gloss drew")
})

test_that("tampered files are reported by the integrity check", {
  fig <- gloss(grid::rectGrob(), width = 2, height = 2, context = FALSE)
  d <- file.path(withr::local_tempdir(), "t.gloss")
  gl_write(fig, d)
  scene <- file.path(d, "substrate", "scene.svg")
  writeLines(sub("<rect", "<rect data-x='1'", readLines(scene)), scene)
  back <- gl_read(d)
  expect_equal(back$status$integrity, "substrate/scene.svg")
})

test_that("writing over a directory that is not a bundle is refused", {
  fig <- gloss(grid::rectGrob(), width = 2, height = 2, context = FALSE)
  d <- withr::local_tempdir()
  writeLines("keep me", file.path(d, "notes.txt"))
  expect_error(gl_write(fig, d), "not a gloss bundle")
  expect_true(file.exists(file.path(d, "notes.txt")))
})

test_that("a 1e5-point scatter is written as a single file under 3 MB", {
  skip_if_no("ggplot2")
  skip_on_cran()
  set.seed(5)
  big <- data.frame(x = rnorm(1e5), y = rnorm(1e5))
  p <- ggplot2::ggplot(big, ggplot2::aes(x, y)) + ggplot2::geom_point(size = 0.3)
  fig <- gloss(p, width = 7, height = 5, context = FALSE)
  expect_equal(sum(fig$substrate$leaves$dense), 1L)
  f <- withr::local_tempfile(fileext = ".html")
  gl_write(fig, f)
  expect_lt(file.size(f), 3 * 1024^2)
  back <- gl_read(f)
  expect_identical(back$substrate$elements, fig$substrate$elements)
  expect_identical(gl_table(back, "built_layer1"), gl_table(fig, "built_layer1"))
})

test_that("an HTML page with an inline SVG but no bundle gives geometry", {
  f <- withr::local_tempfile(fileext = ".html")
  writeLines(c("<!DOCTYPE html><html><body><p>x</p>",
               "<svg xmlns='http://www.w3.org/2000/svg' width='72pt' height='36pt' viewBox='0 0 72 36'>",
               "<circle cx='10' cy='10' r='2'/><text x='20' y='20' style='font-size: 10px;'>hi</text></svg>",
               "</body></html>"), f)
  fig <- gl_read(f)
  expect_equal(fig$substrate$elements$tag, c("circle", "text"))
  expect_equal(fig$meta$width, 1)
})
