test_that("gl_scene, gl_tables, and gl_query inspect and slice in-memory captures", {
  withr::defer(reset_engine_registry(register_builtins = TRUE))

  df <- data.frame(
    id = c("S1", "S2", "S3", "S4"),
    val = c(10, 20, 30, 40),
    stringsAsFactors = FALSE
  )

  gl_register_engine(
    name = "query_demo",
    classes = "query_demo_plot",
    capture_fn = function(x, ctx) {
      grid::grid.newpage()
      grid::grid.rect(x = 0.2, y = 0.5, width = 0.2, height = 0.2, name = "left_box")
      grid::grid.rect(x = 0.8, y = 0.5, width = 0.2, height = 0.2, name = "right_box")
      sc <- ctx$capture_grid(draw_method = "query_demo")
      lineage <- data.frame(
        leaf_id = sc$leaves$leaf_id,
        grob_name = sc$leaves$grob_name,
        layout_slot = sc$leaves$layout_slot,
        panel_id = c("P1", "P2"),
        layer_id = c(1L, 1L),
        table_id = c("tbl_a", "tbl_b"),
        cardinality = c("1:1", "1:1"),
        n_rows = c(4L, 4L),
        n_elements = sc$leaves$n_elements,
        stringsAsFactors = FALSE
      )
      list(
        scene = sc,
        ir = list(
          panels = list(list(panel_id = "P1"), list(panel_id = "P2")),
          layers = list(),
          scales = list(),
          orders = stats::setNames(list(), character())
        ),
        tables = list(tbl_a = df, tbl_b = df),
        lineage = lineage
      )
    }
  )

  cap <- gloss(structure(list(), class = "query_demo_plot"), width = 7, height = 5)

  # gl_scene
  sc <- gl_scene(cap)
  expect_s3_class(sc, "gloss_scene")
  expect_equal(nrow(sc$leaves), 2L)
  expect_equal(length(sc$panels), 2L)
  out_sc <- capture.output(print(sc))
  expect_true(any(grepl("<gloss_scene query_demo", out_sc, fixed = TRUE)))

  # gl_tables
  all_t <- gl_tables(cap)
  expect_identical(names(all_t), c("tbl_a", "tbl_b"))
  expect_identical(gl_tables(cap, "tbl_a"), df)
  expect_identical(names(gl_tables(cap, c("tbl_b", "tbl_a"))), c("tbl_b", "tbl_a"))
  expect_error(gl_tables(cap, "nope"), "Unknown table")

  # gl_query by panel automatically selects linked table
  q_p1 <- gl_query(cap, panel = "P1")
  expect_s3_class(q_p1, "gloss_query_result")
  expect_identical(q_p1$leaves$leaf_id, "L001")
  expect_identical(names(q_p1$tables), "tbl_a")
  expect_identical(q_p1$tables$tbl_a[["_row_id"]], 1:4)

  # gl_query by leaf + row predicate preserves original 1-based _row_id
  q_leaf <- gl_query(cap, leaf = "L002", rows = function(d) d$val >= 30)
  expect_identical(q_leaf$leaves$grob_name, "right_box")
  expect_identical(names(q_leaf$tables), "tbl_b")
  expect_identical(q_leaf$tables$tbl_b[["_row_id"]], c(3L, 4L))
  expect_identical(q_leaf$tables$tbl_b$id, c("S3", "S4"))

  # gl_query by spatial box (left half of 504 x 360 pt canvas)
  q_box <- gl_query(cap, box = c(50, 100, 160, 260))
  expect_identical(q_box$leaves$grob_name, "left_box")
  expect_true(all(q_box$elements$leaf_id == "L001"))

  # Print method works cleanly
  out_q <- capture.output(print(q_box))
  expect_true(any(grepl("<gloss_query_result>", out_q, fixed = TRUE)))

  # Validation errors
  expect_error(gl_query(cap, box = c(1, 2, 3)), "length 4")
  expect_error(gl_query(cap, table = "missing_tbl"), "Unknown table")
})
