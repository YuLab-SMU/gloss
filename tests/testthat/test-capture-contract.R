test_that("new_gloss_capture constructs and validates canonical capture objects", {
  raw_df <- data.frame(
    patient_id = c("P1", "P2", "P3"),
    survival = c(0.85, 0.42, 0.99),
    stringsAsFactors = FALSE
  )

  cap <- new_gloss_capture(
    page = list(engine = "ggplot", draw_method = "ggplot_gtable", width_in = 7, height_in = 5),
    svg_original = "<svg><circle cx='10' cy='10' r='2'/></svg>",
    svg_scene = "<svg><g id='L001'><circle cx='10' cy='10' r='2'/></g></svg>",
    tables = list(
      raw = list(role = "raw", key = "patient_id", data = raw_df),
      built_layer1 = raw_df
    )
  )

  expect_true(is_gloss_capture(cap))
  expect_identical(cap$schema_version, "1.2.0")
  expect_identical(cap$package_version, gloss_package_version())
  expect_true(grepl("^sha256:[0-9a-f]{64}$", cap$capture_id))
  expect_equal(cap$page$width_pt, 504.0)
  expect_equal(cap$page$height_pt, 360.0)
  expect_equal(cap$page$pages, 1L)

  expect_equal(cap$svg$original$bytes, utf8_nbytes(cap$svg$original$text))
  expect_equal(cap$svg$scene$sha256, sha256_text(cap$svg$scene$text))
  expect_identical(cap$tables$raw$key, "patient_id")
  expect_identical(cap$tables$built_layer1$role, "raw")
  expect_s3_class(cap$scene$leaves, "data.frame")
  expect_s3_class(cap$scene$elements, "data.frame")
  expect_s3_class(cap$lineage, "data.frame")

  # Same inputs yield identical deterministic capture_id
  cap2 <- new_gloss_capture(
    page = list(engine = "ggplot", draw_method = "ggplot_gtable", width_in = 7, height_in = 5),
    svg_original = "<svg><circle cx='10' cy='10' r='2'/></svg>",
    svg_scene = "<svg><g id='L001'><circle cx='10' cy='10' r='2'/></g></svg>"
  )
  expect_identical(cap$capture_id, cap2$capture_id)

  # Print method formats cleanly without error
  out <- capture.output(print(cap))
  expect_true(any(grepl("<gloss_capture sha256:", out, fixed = TRUE)))
  expect_true(any(grepl("engine : ggplot", out, fixed = TRUE)))
})

test_that("validate_gloss_capture rejects malformed objects", {
  expect_error(validate_gloss_capture(list()), "gloss_capture")

  bad <- structure(list(schema_version = "1.0.0"), class = "gloss_capture")
  expect_error(validate_gloss_capture(bad), "missing required field")

  expect_error(
    new_gloss_capture(
      page = list(engine = "grid"),
      svg_original = "<svg/>",
      svg_scene = "<svg/>",
      tables = list(data.frame(a = 1))
    ),
    "must be named"
  )
})

test_that("JSON, CSV, and table schema helpers emit standard open formats", {
  tmp <- withr::local_tempdir()

  # JSON helper
  json_path <- file.path(tmp, "sub", "meta.json")
  write_gloss_json(list(a = 1L, b = NULL, c = "hello"), json_path)
  expect_true(file.exists(json_path))
  parsed <- jsonlite::fromJSON(json_path, simplifyVector = TRUE)
  expect_identical(parsed$a, 1L)
  expect_null(parsed$b)
  expect_identical(parsed$c, "hello")
  expect_equal(nchar(sha256_file(json_path)), 64L)

  # CSV helper with explicit 1-based _row_id and list column support
  df <- data.frame(
    grp = factor(c("B", "A", "B"), levels = c("A", "B"), ordered = TRUE),
    val = c(1.5, NA_real_, 3.25),
    ts = as.POSIXct(c("2026-01-01 00:00:00", "2026-01-02 00:00:00", "2026-01-03 00:00:00"), tz = "UTC"),
    stringsAsFactors = FALSE
  )
  df$meta <- I(list(list(k = 1), list(k = 2), list(k = 3)))

  csv_path <- file.path(tmp, "tables", "sample.csv")
  write_gloss_csv(df, csv_path)
  expect_true(file.exists(csv_path))

  roundtrip <- utils::read.csv(csv_path, stringsAsFactors = FALSE, check.names = FALSE)
  expect_identical(names(roundtrip)[1L], "_row_id")
  expect_identical(roundtrip[["_row_id"]], 1:3)
  expect_identical(roundtrip$grp, c("B", "A", "B"))
  expect_true(is.na(roundtrip$val[2L]))

  # Table column summaries & schema spec
  summaries <- table_column_summaries(df)
  expect_equal(length(summaries), 4L)
  expect_identical(summaries[[1L]]$type, "ordered_factor")
  expect_identical(summaries[[1L]]$distinct, 2L)
  expect_identical(summaries[[2L]]$type, "double")
  expect_equal(summaries[[2L]]$min, 1.5)
  expect_equal(summaries[[2L]]$max, 3.25)
  expect_identical(summaries[[2L]]$n_na, 1L)

  schema <- table_schema_spec(df)
  expect_identical(schema[[1L]]$name, "_row_id")
  expect_identical(schema[[2L]]$levels, list("A", "B"))
  expect_true(schema[[2L]]$ordered)
  expect_identical(schema[[4L]]$timezone, "UTC")
})
