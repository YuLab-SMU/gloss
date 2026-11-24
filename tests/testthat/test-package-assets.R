make_rich_test_capture <- function(tmp_dir) {
  code_file <- file.path(tmp_dir, "fig2.R")
  doc_file <- file.path(tmp_dir, "methods.md")
  missing_file <- file.path(tmp_dir, "missing.txt")
  writeLines("# fig2 script\nplot(1:5)", code_file)
  writeLines("# Methods\nCohort A vs Cohort B.", doc_file)

  raw_df <- data.frame(
    patient_id = paste0("P", 1:6),
    cohort = factor(c("A", "A", "A", "B", "B", "B"), levels = c("A", "B")),
    survival = c(0.95, 0.80, 0.72, 0.65, 0.44, 0.30),
    stringsAsFactors = FALSE
  )
  built_df <- data.frame(
    x = c(1, 2, 3, 4, 5, 6),
    y = c(0.95, 0.80, 0.72, 0.65, 0.44, 0.30),
    colour = c("#0072B2", "#0072B2", "#0072B2", "#D55E00", "#D55E00", "#D55E00"),
    stringsAsFactors = FALSE
  )

  draw_counter <- new.env(parent = emptyenv())
  draw_counter$n <- 0L

  withr::defer(reset_engine_registry(register_builtins = TRUE), envir = parent.frame())
  gl_register_engine(
    name = "mock_km",
    classes = "mock_km_plot",
    capture_fn = function(x, ctx) {
      draw_counter$n <- draw_counter$n + 1L
      grid::grid.newpage()
      grid::pushViewport(grid::viewport(
        x = 0.5, y = 0.5, width = 0.7, height = 0.7,
        xscale = c(0, 7), yscale = c(0, 1), name = "panel-1-1"
      ))
      grid::grid.points(
        x = grid::unit(built_df$x, "native"),
        y = grid::unit(built_df$y, "native"),
        pch = 16,
        name = "km_pts"
      )
      grid::grid.text("Survival Curve", y = 0.95, name = "km_title")
      grid::popViewport()
      sc <- ctx$capture_grid(draw_method = "mock_km_draw")

      lineage <- data.frame(
        leaf_id = sc$leaves$leaf_id,
        grob_name = sc$leaves$grob_name,
        layout_slot = sc$leaves$layout_slot,
        panel_id = c("P1", NA_character_),
        layer_id = c(1L, NA_integer_),
        table_id = c("built_layer1", NA_character_),
        cardinality = c("1:1", "unlinked"),
        n_rows = c(6L, NA_integer_),
        n_elements = sc$leaves$n_elements,
        stringsAsFactors = FALSE
      )

      list(
        scene = sc,
        ir = list(
          panels = list(list(
            panel_id = "P1",
            facet_vars = stats::setNames(list(), character()),
            bbox_pt = c(sc$leaves$bbox_x0[1L], sc$leaves$bbox_y0[1L], sc$leaves$bbox_x1[1L], sc$leaves$bbox_y1[1L]),
            x_domain = c(0, 7),
            y_domain = c(0, 1),
            coord = "CoordCartesian",
            flipped = FALSE
          )),
          layers = list(list(
            layer_id = 1L,
            geom = "GeomPoint",
            stat = "StatIdentity",
            position = "PositionIdentity",
            aes = list(x = "time", y = "survival", colour = "cohort"),
            raw_table = "raw",
            built_table = "built_layer1"
          )),
          scales = list(list(
            aesthetic = "colour",
            field = "cohort",
            scale_type = "discrete",
            map = list(
              list(domain = "A", value = "#0072B2", label = "Cohort A"),
              list(domain = "B", value = "#D55E00", label = "Cohort B")
            )
          )),
          orders = stats::setNames(list(), character())
        ),
        tables = list(
          raw = list(role = "raw", key = "patient_id", data = raw_df),
          built_layer1 = list(role = "built", key = character(), layer_id = 1L, data = built_df)
        ),
        lineage = lineage
      )
    }
  )

  cap <- gloss(
    structure(list(), class = "mock_km_plot"),
    sources = list(code = code_file, docs = doc_file, missing = missing_file),
    dense = 5
  )
  list(cap = cap, draw_counter = draw_counter)
}

test_that("gl_asset_map produces schema-compliant JSON without redrawing", {
  tmp <- withr::local_tempdir()
  fx <- make_rich_test_capture(tmp)
  cap <- fx$cap

  map_path <- file.path(tmp, "asset-map.json")
  map <- gl_asset_map(cap, path = map_path)

  expect_s3_class(map, "gloss_asset_map")
  expect_identical(fx$draw_counter$n, 1L)
  expect_true(file.exists(map_path))

  # Parse JSON with simplifyVector = FALSE to verify arrays stay JSON arrays even for length 1
  raw_json <- jsonlite::fromJSON(map_path, simplifyVector = FALSE)
  expect_identical(raw_json$format, "gloss-asset-map")
  expect_identical(raw_json$schema_version, "1.0.0")
  expect_identical(raw_json$capture_id, cap$capture_id)
  expect_identical(raw_json$page$engine, "mock_km")
  expect_identical(raw_json$scene$n_panels, 1L)
  expect_identical(raw_json$scene$n_leaves, 2L)
  expect_true(is.list(raw_json$scene$dense_leaves))
  expect_identical(raw_json$scene$dense_leaves[[1L]], "L001")

  expect_true(is.list(raw_json$ir$panels) && length(raw_json$ir$panels) == 1L)
  expect_true(is.list(raw_json$ir$layers) && length(raw_json$ir$layers) == 1L)
  expect_true(is.list(raw_json$ir$scales) && length(raw_json$ir$scales) == 1L)
  expect_true(is.list(raw_json$tables) && length(raw_json$tables) == 2L)
  # Length-1 key stays a JSON array ["patient_id"]
  expect_true(is.list(raw_json$tables[[1L]]$key))
  expect_identical(raw_json$tables[[1L]]$key[[1L]], "patient_id")

  out <- capture.output(print(map))
  expect_true(any(grepl("<gloss_asset_map sha256:", out, fixed = TRUE)))
})

test_that("gl_asset_bundle writes complete .gloss directory with verified manifest and rasters", {
  tmp <- withr::local_tempdir()
  fx <- make_rich_test_capture(tmp)
  cap <- fx$cap

  bundle_dir <- file.path(tmp, "fig2.gloss")
  out_path <- gl_asset_bundle(cap, path = bundle_dir, format = "dir")

  # Still only drawn once across gloss() + gl_asset_bundle()
  expect_identical(fx$draw_counter$n, 1L)
  expect_true(dir.exists(out_path))

  expected_files <- c(
    "manifest.json",
    "asset-map.json",
    "omitted.json",
    "assets/original.svg",
    "scene/scene.svg",
    "scene/leaves.json",
    "scene/elements.json",
    "scene/rasters/L001.png",
    "tables/schema.json",
    "tables/raw.csv",
    "tables/built_layer1.csv",
    "sources/code/fig2.R",
    "sources/docs/methods.md",
    "sources/session.json"
  )
  for (rf in expected_files) {
    expect_true(file.exists(file.path(bundle_dir, rf)), info = paste("missing:", rf))
  }

  # Verify manifest digests & byte sizes match every file on disk
  manifest <- jsonlite::fromJSON(file.path(bundle_dir, "manifest.json"), simplifyVector = FALSE)
  expect_identical(manifest$format, "gloss-asset-bundle")
  expect_identical(manifest$capture_id, cap$capture_id)
  expect_null(manifest$parent_manifest_sha256)
  manifest_paths <- vapply(manifest$files, `[[`, character(1L), "path")
  expect_true(all(setdiff(expected_files, "manifest.json") %in% manifest_paths))

  for (fent in manifest$files) {
    full <- file.path(bundle_dir, fent$path)
    expect_true(file.exists(full))
    expect_identical(as.integer(file.info(full)$size), fent$bytes)
    expect_identical(sha256_file(full), fent$sha256)
  }

  # Verify omitted.json logged the missing explicit source file
  omitted <- jsonlite::fromJSON(file.path(bundle_dir, "omitted.json"), simplifyVector = FALSE)
  missing_rec <- Filter(function(o) identical(o$id, "missing"), omitted$omitted)
  expect_equal(length(missing_rec), 1L)
  expect_identical(missing_rec[[1L]]$reason, "not_found")

  # Verify CSV table has 1-based _row_id and schema.json preserves factor levels
  raw_csv <- utils::read.csv(file.path(bundle_dir, "tables/raw.csv"), check.names = FALSE, stringsAsFactors = FALSE)
  expect_identical(names(raw_csv)[1L], "_row_id")
  expect_identical(raw_csv[["_row_id"]], 1:6)
  expect_identical(raw_csv$patient_id, paste0("P", 1:6))

  schema <- jsonlite::fromJSON(file.path(bundle_dir, "tables/schema.json"), simplifyVector = FALSE)
  expect_identical(schema$tables$raw$columns[[1L]]$name, "_row_id")
  expect_identical(schema$tables$raw$columns[[1L]]$role, "row_id")
  cohort_col <- schema$tables$raw$columns[[3L]]
  expect_identical(cohort_col$name, "cohort")
  expect_identical(cohort_col$type, "factor")
  expect_identical(cohort_col$levels, list("A", "B"))

  # overwrite = FALSE refuses cleanly
  expect_error(gl_asset_bundle(cap, path = bundle_dir, overwrite = FALSE), "already exists")
})

test_that("gl_asset_bundle supports select, column projection, row filtering, and zip format", {
  tmp <- withr::local_tempdir()
  fx <- make_rich_test_capture(tmp)
  cap <- fx$cap

  filtered_dir <- file.path(tmp, "filtered.gloss")
  gl_asset_bundle(
    cap,
    path = filtered_dir,
    select = list(
      tables = list(raw = c("patient_id", "survival")),
      sources = c("fig2", "session"),
      elements = FALSE
    ),
    rows = list(raw = function(df) df$survival >= 0.70)
  )

  expect_false(file.exists(file.path(filtered_dir, "scene/elements.json")))
  expect_false(file.exists(file.path(filtered_dir, "tables/built_layer1.csv")))
  expect_false(file.exists(file.path(filtered_dir, "sources/docs/methods.md")))
  expect_true(file.exists(file.path(filtered_dir, "sources/code/fig2.R")))

  raw_csv <- utils::read.csv(file.path(filtered_dir, "tables/raw.csv"), check.names = FALSE, stringsAsFactors = FALSE)
  expect_identical(names(raw_csv), c("_row_id", "patient_id", "survival"))
  expect_identical(raw_csv[["_row_id"]], 1:3)

  omitted <- jsonlite::fromJSON(file.path(filtered_dir, "omitted.json"), simplifyVector = FALSE)
  reasons <- vapply(omitted$omitted, function(x) paste0(x$kind, ":", x$id, ":", x$reason), character(1L))
  expect_true("scene:elements:excluded_by_select" %in% reasons)
  expect_true("table:built_layer1:excluded_by_select" %in% reasons)
  expect_true("table_rows:raw:filtered_by_rows" %in% reasons)
  expect_true("table_columns:raw:excluded_by_select" %in% reasons)

  # ZIP archive format
  zip_path <- file.path(tmp, "fig2.gloss.zip")
  gl_asset_bundle(cap, path = zip_path, format = "zip")
  expect_true(file.exists(zip_path))

  unzip_dir <- file.path(tmp, "unzipped")
  utils::unzip(zip_path, exdir = unzip_dir)
  expect_true(file.exists(file.path(unzip_dir, "manifest.json")))
  expect_true(file.exists(file.path(unzip_dir, "asset-map.json")))
  expect_true(file.exists(file.path(unzip_dir, "assets/original.svg")))
  expect_true(file.exists(file.path(unzip_dir, "scene/rasters/L001.png")))

  # Bundle asset-map.json reflects exact table/source inclusion & bundle_nrow
  fmap <- jsonlite::fromJSON(file.path(filtered_dir, "asset-map.json"), simplifyVector = FALSE)
  expect_false(fmap$scene$elements_included)
  tbl_by_id <- stats::setNames(fmap$tables, vapply(fmap$tables, `[[`, character(1L), "table_id"))
  expect_true(tbl_by_id$raw$included)
  expect_identical(tbl_by_id$raw$bundle_nrow, 3L)
  expect_false(tbl_by_id$built_layer1$included)
  expect_identical(tbl_by_id$built_layer1$bundle_nrow, 0L)

  # Character shorthand select respects elements inclusion explicitly
  char_dir <- file.path(tmp, "char_sel.gloss")
  gl_asset_bundle(cap, path = char_dir, select = c("raw"))
  expect_false(file.exists(file.path(char_dir, "scene/elements.json")))
  expect_true(file.exists(file.path(char_dir, "tables/raw.csv")))

  char_with_el <- file.path(tmp, "char_sel_el.gloss")
  gl_asset_bundle(cap, path = char_with_el, select = c("raw", "elements"))
  expect_true(file.exists(file.path(char_with_el, "scene/elements.json")))
})

test_that("write_gloss_csv handles matrix columns cleanly and capture_id reflects raster digests", {
  tmp <- withr::local_tempdir()
  df_mat <- data.frame(id = c("A", "B"), stringsAsFactors = FALSE)
  df_mat$coords <- matrix(c(1, 2, 3, 4), nrow = 2L)
  csv_p <- file.path(tmp, "mat.csv")
  write_gloss_csv(df_mat, csv_p)
  rt <- utils::read.csv(csv_p, check.names = FALSE, stringsAsFactors = FALSE)
  expect_identical(names(rt), c("_row_id", "id", "coords"))

  c_a <- new_gloss_capture(
    page = list(engine = "grid"),
    svg_original = "<svg/>",
    svg_scene = "<svg/>",
    rasters = list(L001 = as.raw(c(1, 2, 3)))
  )
  c_b <- new_gloss_capture(
    page = list(engine = "grid"),
    svg_original = "<svg/>",
    svg_scene = "<svg/>",
    rasters = list(L001 = as.raw(c(1, 2, 4)))
  )
  expect_false(identical(c_a$capture_id, c_b$capture_id))
})
