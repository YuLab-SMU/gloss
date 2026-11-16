test_that("ARIA and text projections preserve semantic status", {
  skip_if_no("ggplot2")
  fig <- gloss(ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
                 ggplot2::geom_point(), context = FALSE)
  id <- fig$substrate$elements$id[1L]
  fig <- gl_record(fig, "meaning", id,
                   list(text = "possible domain explanation", provenance = "speculative"),
                   by = "reviewer")
  good <- list(text = "weight and fuel economy trend down together",
               check = list(kind = "trend", table = "built_layer1",
                            args = list(response = "y", predictor = "x", expect = "negative")))
  fig <- gl_record(fig, "claim", id, good, by = "reviewer")
  bad <- good
  bad$check$args$expect <- "positive"
  fig <- gl_record(fig, "claim", id, bad, by = "reviewer")

  aria <- gl_export(fig, "aria")
  parsed <- jsonlite::fromJSON(aria, simplifyVector = FALSE)
  expect_equal(parsed$role, "graphics-document")
  expect_true(any(vapply(parsed$records, function(x) x$status == "verified", logical(1))))
  expect_true(any(vapply(parsed$records, function(x) x$status == "speculative", logical(1))))
  expect_false(any(vapply(parsed$records, function(x) x$status == "rejected", logical(1))))

  txt <- gl_export(fig, "text")
  expect_match(txt, "verified")
  expect_match(txt, "speculative")
  expect_false(grepl("possible domain explanation", txt, fixed = TRUE) == FALSE)

  ann <- gl_export(fig, "annotation")
  ann_parsed <- jsonlite::fromJSON(ann, simplifyVector = FALSE)
  expect_equal(ann_parsed[["@context"]], "http://www.w3.org/ns/anno.jsonld")
  expect_true(length(ann_parsed$items) >= 2L)
  path <- withr::local_tempfile(fileext = ".json")
  gl_export(fig, "aria", path)
  expect_true(file.exists(path))
  expect_gt(file.size(path), 0)
})

test_that("accessibility and annotation projections pass their plugin contracts", {
  for (nm in c("aria", "text", "annotation")) {
    result <- gl_test_plugin("projection", nm)
    expect_false(any(result$passed %in% FALSE), label = nm)
  }
})
