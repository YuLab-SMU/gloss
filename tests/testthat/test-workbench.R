test_that("gl_workbench writes a standalone HTML file that gl_read restores losslessly", {
  skip_if_no("ggplot2")
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, colour = factor(cyl))) +
    ggplot2::geom_point() +
    ggplot2::facet_wrap(~am)
  fig <- gloss(p, width = 7, height = 4, context = FALSE)

  b <- gl_bindings(fig)
  e1 <- b$element[b$status == "verified"][1L]
  fig <- gl_record(
    fig, "meaning", gl_anchor(element = e1),
    list(
      type = "domain_interpretation",
      text = "Mazda RX4 represents a light 6-cylinder manual benchmark car.",
      source = "mtcars dataset documentation",
      source_type = "dataset_metadata",
      evidence = list(wt = 2.62, mpg = 21),
      provenance = "derived",
      confidence = 0.92
    ),
    by = "analyst"
  )
  fig <- gl_record(
    fig, "claim", gl_anchor(element = e1),
    list(
      text = "Weight and fuel economy trend downward across the plotted layer.",
      check = list(
        kind = "trend", table = "built_layer1",
        args = list(response = "y", predictor = "x", expect = "negative")
      )
    ),
    by = "analyst"
  )

  out <- withr::local_tempfile(fileext = ".html")
  gl_workbench(fig, out, embed = "all", theme = "paper", title = "Test </script> Workbench")

  expect_true(file.exists(out))
  expect_gt(file.size(out), 100000)

  txt <- paste(readLines(out, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  expect_true(grepl("id=\"gloss-bundle\"", txt, fixed = TRUE))
  expect_true(grepl("window.__GLOSS_WORKBENCH_CONFIG__=", txt, fixed = TRUE))
  # Closing script sequence inside title config must be escaped
  expect_false(grepl("Test </script> Workbench", txt, fixed = TRUE))

  back <- gl_read(out)
  expect_identical(gl_elements(back), gl_elements(fig))
  expect_identical(gl_bindings(back), gl_bindings(fig))
  recs <- gl_records(back)
  expect_equal(nrow(recs), 2L)
  meaning_body <- recs$body[[which(recs$layer == "meaning")[1L]]]
  expect_equal(meaning_body$source, "mtcars dataset documentation")
  expect_equal(meaning_body$source_type, "dataset_metadata")
  expect_equal(meaning_body$confidence, 0.92)
})

test_that("gl_workbench respects view = 'reader' (default) and view = 'inspector'", {
  skip_if_no("ggplot2")
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  fig <- gloss(p, width = 6, height = 4, context = FALSE)

  out_reader <- withr::local_tempfile(fileext = ".html")
  gl_workbench(fig, out_reader)
  txt_reader <- paste(readLines(out_reader, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  expect_true(grepl('"view":"reader"', txt_reader, fixed = TRUE))

  out_insp <- withr::local_tempfile(fileext = ".html")
  gl_workbench(fig, out_insp, view = "inspector")
  txt_insp <- paste(readLines(out_insp, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  expect_true(grepl('"view":"inspector"', txt_insp, fixed = TRUE))

  expect_identical(gl_elements(gl_read(out_reader)), gl_elements(fig))
  expect_identical(gl_elements(gl_read(out_insp)), gl_elements(fig))
})

test_that("workbench projection plugin passes its contract", {
  res <- gl_test_plugin("projection", "workbench")
  expect_false(any(res$passed %in% FALSE),
               label = paste(res$message[res$passed %in% FALSE], collapse = "; "))
})
