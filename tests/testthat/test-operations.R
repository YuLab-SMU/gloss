test_that("built-in operations are registered through the plugin registry", {
  expect_setequal(gl_plugins("operation")$name,
                  c("select", "style", "show", "hide", "raise", "lower",
                    "focus", "link", "unlink", "overlay", "tooltip"))
  for (nm in gl_plugins("operation")$name) {
    result <- gl_test_plugin("operation", nm)
    expect_false(any(result$passed %in% FALSE), label = nm)
  }
})

test_that("operations resolve targets and preserve the captured scene", {
  skip_if_no("ggplot2")
  fig <- gloss(ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
                 ggplot2::geom_point(), context = FALSE)
  original <- fig$substrate$scene
  ids <- fig$substrate$elements$id[1:2]
  out <- gl_apply(fig, list(
    list(op = "select", target = ids[1]),
    list(op = "style", target = ids[1], style = "highlight"),
    list(op = "hide", target = ids[2]),
    list(op = "show", target = ids[2]),
    list(op = "focus", target = ids[1]),
    list(op = "raise", target = ids[1]),
    list(op = "lower", target = ids[2]),
    list(op = "tooltip", target = ids[1], text = "a point"),
    list(op = "link", from = ids[1], to = ids[2], relation = "related"),
    list(op = "unlink", from = ids[1], to = ids[2], relation = "related")
  ))
  expect_identical(fig$substrate$scene, original)
  expect_equal(length(out$operations$specs), 10L)
  scene <- gloss:::scene_with_operations(out)
  expect_true(grepl("data-gloss-element", scene, fixed = TRUE))
  expect_true(grepl("gloss-selected", scene, fixed = TRUE))
  expect_true(grepl("data-gloss-tooltip=\"a point\"", scene, fixed = TRUE))
  expect_true(grepl("data-gloss-visible=\"true\"", scene, fixed = TRUE))
  expect_error(gl_apply(fig, list(op = "unknown", target = ids[1])), "No operation plugin")
  expect_error(gl_apply(fig, list(op = "overlay", target = ids[1], kind = "box",
                                  text = "claim")), "verified record")
})

test_that("verified claims can support an overlay and operation state round-trips", {
  skip_if_no("ggplot2")
  fig <- gloss(ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
                 ggplot2::geom_point(), context = FALSE)
  id <- fig$substrate$elements$id[1L]
  body <- list(
    text = "weight and fuel economy trend down together",
    check = list(kind = "trend", table = "built_layer1",
                 args = list(response = "y", predictor = "x", expect = "negative"))
  )
  fig <- gl_record(fig, "claim", id, body, by = "fixture")
  claim_id <- gl_records(fig, "claim")$id[1L]
  expect_equal(gl_records(fig, "claim")$status, "verified")
  out <- gl_apply(fig, list(op = "overlay", target = id, kind = "leader",
                             text = "verified claim", basis = claim_id))
  scene <- gloss:::scene_with_operations(out)
  expect_true(grepl("gloss-overlay", scene, fixed = TRUE))
  expect_true(grepl("verified claim", scene, fixed = TRUE))
  path <- withr::local_tempfile(fileext = ".html")
  gl_write(out, path)
  back <- gl_read(path)
  expect_equal(length(back$operations$specs), 1L)
  expect_equal(back$operations$specs[[1L]]$op, "overlay")
  expect_identical(back$operations$specs[[1L]]$basis, claim_id)
  expect_identical(back$operations$state$focus, character())
})

test_that("the browser runtime is dependency-free and syntactically valid", {
  node <- Sys.which("node")
  skip_if(!nzchar(node), "node is unavailable")
  root <- system.file("js", package = "gloss")
  if (!nzchar(root)) {
    root <- normalizePath(file.path(testthat::test_path(), "..", "..", "inst", "js"),
                         mustWork = TRUE)
  }
  files <- c(file.path(root, "gloss-core.js"),
             list.files(file.path(root, "ops"), full.names = TRUE))
  for (file in files) {
    expect_equal(system2(node, c("--check", file), stdout = FALSE, stderr = FALSE), 0L,
                 label = file)
  }
  raw <- unlist(lapply(files, function(file) readBin(file, "raw", file.info(file)$size)),
                use.names = FALSE)
  compressed <- memCompress(raw, type = "gzip")
  expect_lt(length(compressed), 15 * 1024)
})
