test_that("collect_sources_inventory handles explicit files, categories, inline text, and missing files", {
  tmp <- withr::local_tempdir()
  code_file <- file.path(tmp, "plot_km.R")
  doc_file <- file.path(tmp, "methods.md")
  dup_dir <- file.path(tmp, "sub")
  dir.create(dup_dir)
  dup_code <- file.path(dup_dir, "plot_km.R")
  missing_file <- file.path(tmp, "does_not_exist.csv")

  writeLines("plot(1:10)", code_file)
  writeLines("# Methods\nSample note.", doc_file)
  writeLines("plot(10:1)", dup_code)

  cap <- gloss(
    grid::rectGrob(width = 0.5, height = 0.5, name = "box"),
    sources = list(
      code = c(plot_script = code_file, dup_script = dup_code),
      docs = doc_file,
      data = missing_file,
      inline_note = list(kind = "doc", text = "Inline caption draft", filename = "caption.md")
    )
  )

  srcs <- gl_sources(cap)
  expect_s3_class(srcs, "data.frame")
  expect_true(all(c("plot_script", "dup_script", "methods", "does_not_exist", "inline_note", "session") %in% srcs$source_id))

  # Explicit found & missing entries recorded neutrally
  ps <- srcs[srcs$source_id == "plot_script", ]
  expect_identical(ps$kind, "code")
  expect_identical(ps$provenance_mode, "explicit")
  expect_true(ps$found)
  expect_true(ps$readable)
  expect_identical(ps$path, "sources/code/plot_km.R")

  # Duplicate basename disambiguated
  ds <- srcs[srcs$source_id == "dup_script", ]
  expect_identical(ds$path, "sources/code/plot_km_2.R")

  # Missing file recorded without error
  ms <- srcs[srcs$source_id == "does_not_exist", ]
  expect_identical(ms$kind, "data")
  expect_false(ms$found)
  expect_false(ms$readable)
  expect_true(is.na(ms$bytes))
  expect_true(is.na(ms$sha256))

  # Runtime session entry always present
  sess <- srcs[srcs$source_id == "session", ]
  expect_identical(sess$provenance_mode, "runtime_observed")
  expect_identical(sess$path, "sources/session.json")
  expect_true(sess$found && sess$readable)
  expect_true("gloss" %in% names(cap$session$loaded_packages))
})

test_that("explicit character vector sources infer kind from file extension", {
  tmp <- withr::local_tempdir()
  r_file <- file.path(tmp, "fig.R")
  csv_file <- file.path(tmp, "raw.csv")
  writeLines("# R code", r_file)
  writeLines("a,b\n1,2", csv_file)

  cap <- gloss(
    grid::circleGrob(r = 0.2),
    sources = c(script = r_file, input_csv = csv_file)
  )

  srcs <- gl_sources(cap)
  expect_identical(srcs$kind[srcs$source_id == "script"], "code")
  expect_identical(srcs$kind[srcs$source_id == "input_csv"], "data")
})

test_that("inline source filenames are sanitized against path traversal and NA paths are safe", {
  cap <- gloss(
    grid::rectGrob(),
    sources = list(
      evil = list(kind = "doc", text = "safe content", filename = "../../escape.md"),
      missing_na = NA_character_
    )
  )

  srcs <- gl_sources(cap)
  ev <- srcs[srcs$source_id == "evil", ]
  expect_identical(ev$path, "sources/docs/escape.md")
  expect_false(grepl("\\.\\.", ev$path))

  na_row <- srcs[srcs$source_id == "missing_na", ]
  expect_false(na_row$found)
  expect_false(na_row$readable)

  tmp <- withr::local_tempdir()
  bdir <- gl_asset_bundle(cap, path = file.path(tmp, "safe.gloss"))
  expect_true(file.exists(file.path(bdir, "sources/docs/escape.md")))
  expect_false(file.exists(file.path(tmp, "escape.md")))
})
