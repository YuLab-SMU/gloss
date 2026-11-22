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

  # 7. POST /api/context/assemble returns a bounded packet for a focused turn
  assemble_req <- jsonlite::toJSON(list(
    question = "Explain Mazda",
    focus = list(query = "Mazda"),
    disclose = "rows"
  ), auto_unbox = TRUE)
  r_assemble <- handler(list(REQUEST_METHOD = "POST", PATH_INFO = "/api/context/assemble",
                             rook.input = assemble_req))
  expect_equal(r_assemble$status, 200L)
  assembled <- jsonlite::fromJSON(r_assemble$body, simplifyVector = FALSE)
  expect_true(isTRUE(assembled$ok))
  expect_equal(assembled$packet$request$intent, "explain")
  expect_equal(vapply(assembled$packet$sections$data$selected_rows$raw, function(row) as.integer(row$.row), integer(1)), c(1L, 2L))

  # 8. MCP discovery and tool calls use the same live figure state
  mcp_init <- jsonlite::toJSON(list(
    jsonrpc = "2.0", id = 1L, method = "initialize",
    params = list(protocolVersion = "2025-11-25", stage = "meaning")
  ), auto_unbox = TRUE)
  r_mcp_init <- handler(list(REQUEST_METHOD = "POST", PATH_INFO = "/mcp", rook.input = mcp_init))
  expect_equal(r_mcp_init$status, 200L)
  init_res <- jsonlite::fromJSON(r_mcp_init$body)
  expect_equal(init_res$result$protocolVersion, "2025-11-25")

  mcp_discover <- jsonlite::toJSON(list(
    jsonrpc = "2.0", id = 11L, method = "server/discover", params = list()
  ), auto_unbox = TRUE)
  r_mcp_discover <- handler(list(REQUEST_METHOD = "POST", PATH_INFO = "/mcp",
                                 rook.input = mcp_discover))
  expect_equal(r_mcp_discover$status, 200L)
  discover_res <- jsonlite::fromJSON(r_mcp_discover$body)
  expect_true("2026-07-28" %in% discover_res$result$protocolVersions)

  modern_meta <- list(
    `_meta` = list(
      `io.modelcontextprotocol/protocolVersion` = "2026-07-28",
      `io.modelcontextprotocol/clientInfo` = list(name = "test-client", version = "1.0"),
      `io.modelcontextprotocol/clientCapabilities` = list()
    )
  )
  modern_discover <- jsonlite::toJSON(list(
    jsonrpc = "2.0", id = 12L, method = "server/discover", params = modern_meta
  ), auto_unbox = TRUE)
  r_modern_discover <- handler(list(
    REQUEST_METHOD = "POST", PATH_INFO = "/mcp", rook.input = modern_discover,
    HTTP_MCP_PROTOCOL_VERSION = "2026-07-28", HTTP_MCP_METHOD = "server/discover",
    HTTP_ACCEPT = "application/json, text/event-stream"
  ))
  expect_equal(r_modern_discover$status, 200L)
  modern_result <- jsonlite::fromJSON(r_modern_discover$body)
  expect_true("2026-07-28" %in% modern_result$result$supportedVersions)

  r_bad_header <- handler(list(
    REQUEST_METHOD = "POST", PATH_INFO = "/mcp", rook.input = modern_discover,
    HTTP_MCP_PROTOCOL_VERSION = "2025-11-25", HTTP_MCP_METHOD = "server/discover",
    HTTP_ACCEPT = "application/json, text/event-stream"
  ))
  expect_equal(r_bad_header$status, 400L)
  expect_equal(jsonlite::fromJSON(r_bad_header$body)$error$code, -32020)

  mcp_list <- jsonlite::toJSON(list(jsonrpc = "2.0", id = 2L, method = "tools/list", params = list()),
                               auto_unbox = TRUE)
  r_mcp_list <- handler(list(REQUEST_METHOD = "POST", PATH_INFO = "/mcp", rook.input = mcp_list))
  expect_equal(r_mcp_list$status, 200L)
  list_res <- jsonlite::fromJSON(r_mcp_list$body)
  expect_true("assemble_context" %in% list_res$result$tools$name)

  mcp_call <- jsonlite::toJSON(list(
    jsonrpc = "2.0", id = 3L, method = "tools/call",
    params = list(name = "assemble_context", arguments = list(question = "Explain Mazda", focus = list(query = "Mazda")))
  ), auto_unbox = TRUE)
  r_mcp_call <- handler(list(REQUEST_METHOD = "POST", PATH_INFO = "/mcp", rook.input = mcp_call))
  expect_equal(r_mcp_call$status, 200L)
  call_res <- jsonlite::fromJSON(r_mcp_call$body)
  expect_false(isTRUE(call_res$result$isError))

  modern_call <- jsonlite::toJSON(list(
    jsonrpc = "2.0", id = 4L, method = "tools/call",
    params = c(list(name = "assemble_context", arguments = list(question = "Explain Mazda")), modern_meta)
  ), auto_unbox = TRUE)
  r_modern_call <- handler(list(
    REQUEST_METHOD = "POST", PATH_INFO = "/mcp", rook.input = modern_call,
    HTTP_MCP_PROTOCOL_VERSION = "2026-07-28", HTTP_MCP_METHOD = "tools/call",
    HTTP_MCP_NAME = "assemble_context", HTTP_ACCEPT = "application/json, text/event-stream"
  ))
  expect_equal(r_modern_call$status, 200L)
  expect_false(isTRUE(jsonlite::fromJSON(r_modern_call$body)$result$isError))

  # 9. Invalid proposal returns 422 cleanly
  bad_req <- jsonlite::toJSON(list(
    layer = "meaning", anchor = list(element = "e999999"),
    body = list(text = "missing target")
  ), auto_unbox = TRUE)
  r_bad <- handler(list(REQUEST_METHOD = "POST", PATH_INFO = "/api/propose", rook.input = bad_req))
  expect_equal(r_bad$status, 422L)
  expect_false(isTRUE(jsonlite::fromJSON(r_bad$body)$ok))
})
