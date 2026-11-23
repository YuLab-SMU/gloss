test_that("IR constructors emit normalized structures for panels, layers, and scales", {
  pan <- make_panel_ir(
    panel_id = "P1",
    facet_vars = list(arm = "Treatment"),
    bbox_pt = c(42.5123, 28.0, 248.0, 318.0),
    x_domain = c(0, 24),
    y_domain = c(0, 1),
    coord = "CoordCartesian",
    flipped = FALSE,
    row = 1L,
    col = 1L,
    x_trans = "identity",
    y_trans = "log-10"
  )
  expect_identical(pan$panel_id, "P1")
  expect_identical(pan$facet_vars$arm, "Treatment")
  expect_equal(unlist(pan$bbox_pt), c(42.512, 28, 248, 318))
  expect_identical(pan$y_trans, "log-10")

  lyr <- make_layer_ir(
    layer_id = 1L,
    geom = "GeomPoint",
    stat = "StatIdentity",
    position = "PositionJitter",
    aes = list(x = "wt", y = "mpg"),
    raw_table = "raw",
    built_table = "built_layer1",
    params = list(size = 2)
  )
  expect_identical(lyr$layer_id, 1L)
  expect_identical(lyr$geom, "GeomPoint")
  expect_identical(lyr$position, "PositionJitter")
  expect_identical(lyr$params$size, 2)

  sc <- make_scale_ir(
    aesthetic = "colour",
    field = "cohort",
    scale_type = "discrete",
    map = list(list(domain = "A", value = "#0072B2", label = "Cohort A")),
    domain = c("A")
  )
  expect_identical(sc$aesthetic, "colour")
  expect_identical(sc$scale_type, "discrete")
  expect_equal(length(sc$map), 1L)
})

test_that("infer_lineage_cardinality classifies neutral structural cardinalities", {
  expect_identical(infer_lineage_cardinality("GeomPoint", "StatIdentity", 32L, 32L), "1:1")
  expect_identical(infer_lineage_cardinality("GeomLine", "StatIdentity", 30L, 3L), "N:1")
  expect_identical(infer_lineage_cardinality("GeomPointrange", "StatIdentity", 4L, 8L), "1:M")
  expect_identical(infer_lineage_cardinality("GeomBoxplot", "StatBoxplot", 3L, 15L), "stat_aggregated")
  expect_identical(infer_lineage_cardinality("GeomBar", "StatCount", 3L, 3L), "stat_aggregated")
  expect_identical(infer_lineage_cardinality("GeomPoint", "StatIdentity", 0L, 0L), "empty")
  expect_identical(infer_lineage_cardinality("GeomPoint", "StatIdentity", NA_integer_, 5L), "unknown")
})
