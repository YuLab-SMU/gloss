test_that("workbench_live_handler serves bundle, proposes checked records, dry-runs checks, and attaches context", {
  skip_if_no("ggplot2")
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, colour = factor(cyl))) +
    ggplot2::geom_point()
  fig <- gloss(p, width = 6, height = 4, context = FALSE)
  e1 <- gl_bindings(fig)$element[1L]

  state <- new.env(parent = emptyenv())
  state$fig <- fig
  state$embed <- "all"
  state$mode <- "full"
  state$theme <- "paper"
  state$initial_stage <- NULL
  state$title <- "Live Test Figure"
  state$template <- NULL

  handler <- gloss:::workbench_live_handler(state)

  # 1. GET / serves live-enabled workbench HTML
  r_root <- handler(list(REQUEST_METHOD = "GET", PATH_INFO = "/"))
  expect_equal(r_root$status, 200L)
  expect_match(r_root$body, "__GLOSS_LIVE_API__", fixed = TRUE)

  # 2. GET /api/status
  r_status <- handler(list(REQUEST_METHOD = "GET", PATH_INFO = "/api/status"))
  expect_equal(r_status$status, 200L)
  st <- jsonlite::fromJSON(r_status$body)
  expect_true(isTRUE(st$live))
  expect_equal(st$engine, "ggplot")

  # 3. GET /api/bundle
  r_bun <- handler(list(REQUEST_METHOD = "GET", PATH_INFO = "/api/bundle"))
  expect_equal(r_bun$status, 200L)
  bun <- jsonlite::fromJSON(r_bun$body)
  expect_equal(bun$format, "gloss-bundle-embed")
  expect_true(nzchar(bun$payload))

  # 4. POST /api/check dry-runs gl_check()
  chk_req <- jsonlite::toJSON(list(
    table = "built_layer1",
    kind = "trend",
    args = list(response = "y", predictor = "x", expect = "negative")
  ), auto_unbox = TRUE)
  r_chk <- handler(list(REQUEST_METHOD = "POST", PATH_INFO = "/api/check", rook.input = chk_req))
  expect_equal(r_chk$status, 200L)
  chk_res <- jsonlite::fromJSON(r_chk$body)
  expect_true(isTRUE(chk_res$ok))
  expect_equal(chk_res$check$status, "verified")

  # 5. POST /api/propose commits a verified claim and updates state$fig
  prop_req <- jsonlite::toJSON(list(
    layer = "claim",
    anchor = list(element = e1),
    body = list(
      text = "Heavier cars have lower mpg.",
      check = list(
        kind = "trend", table = "built_layer1",
        args = list(response = "y", predictor = "x", expect = "negative")
      )
    ),
    by = "live-reviewer"
  ), auto_unbox = TRUE)
  r_prop <- handler(list(REQUEST_METHOD = "POST", PATH_INFO = "/api/propose", rook.input = prop_req))
  expect_equal(r_prop$status, 200L)
  prop_res <- jsonlite::fromJSON(r_prop$body)
  expect_true(isTRUE(prop_res$ok))
  expect_equal(nrow(gl_records(state$fig)), 1L)
  expect_equal(gl_records(state$fig)$status[1L], "verified")

  # 6. POST /api/context attaches external context
  ctx_req <- jsonlite::toJSON(list(
    item = "user_context",
    value = list(question = "Which cylinder group is most efficient?", audience = "engineer"),
    source = "live-ui",
    source_type = "user_prompt"
  ), auto_unbox = TRUE)
  r_ctx <- handler(list(REQUEST_METHOD = "POST", PATH_INFO = "/api/context", rook.input = ctx_req))
  expect_equal(r_ctx$status, 200L)
  expect_true(gl_context(state$fig, "user_context")$found)

  # 7. Invalid proposal returns 422 cleanly
  bad_req <- jsonlite::toJSON(list(
    layer = "meaning", anchor = list(element = "e999999"),
    body = list(text = "missing target")
  ), auto_unbox = TRUE)
  r_bad <- handler(list(REQUEST_METHOD = "POST", PATH_INFO = "/api/propose", rook.input = bad_req))
  expect_equal(r_bad$status, 422L)
  expect_false(isTRUE(jsonlite::fromJSON(r_bad$body)$ok))
})
