# Task-scoped context plans and packets are deterministic, bounded projections
# over the substrate. They do not call a model or write the figure.

context_assembly_fig <- function(context = FALSE) {
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, colour = factor(cyl))) +
    ggplot2::geom_point()
  gloss(p, width = 4, height = 3, context = context)
}

test_that("context plans resolve data queries and are deterministic", {
  skip_if_no("ggplot2")
  fig <- context_assembly_fig()

  first <- gl_context_plan(fig, question = "Explain Mazda", focus = list(query = "Mazda"),
                           disclose = "rows")
  second <- gl_context_plan(fig, question = "Explain Mazda", focus = list(query = "Mazda"),
                            disclose = "rows")

  expect_identical(first$digest, second$digest)
  expect_equal(first$intent, "explain")
  expect_equal(first$focus$rows$raw, c(1L, 2L))
  expect_length(first$focus$unresolved, 0L)

  packet <- gl_context_assemble(fig, plan = first)
  expect_s3_class(packet, "gloss_context_packet")
  expect_equal(vapply(packet$sections$data$selected_rows$raw, function(row) row$.row, integer(1)), c(1L, 2L))
  decoded <- jsonlite::fromJSON(gloss:::json_write(packet, pretty = FALSE), simplifyVector = FALSE)
  expect_identical(as.character(decoded$digest), packet$digest)
})

test_that("element focus assembles checked evidence and semantic records", {
  skip_if_no("ggplot2")
  fig <- context_assembly_fig(context = FALSE)
  element <- gl_bindings(fig)$element[1L]
  fig <- gl_record(
    fig,
    layer = "meaning",
    anchor = gl_anchor(element = element),
    body = list(type = "entity", text = "selected point"),
    by = "test"
  )

  plan <- gl_context_plan(fig, question = "Verify this point", intent = "verify",
                          focus = list(elements = element), disclose = "rows")
  packet <- gl_context_assemble(fig, plan = plan)

  expect_equal(packet$request$intent, "verify")
  expect_equal(unname(packet$sections$focus$elements[[1L]]$id), element)
  expect_length(packet$sections$evidence$bindings, 1L)
  expect_length(packet$sections$semantics, 1L)
  expect_equal(unname(packet$sections$semantics[[1L]]$body$text), "selected point")
  expect_true(any(vapply(packet$actions, function(x) identical(x$name, "check"), logical(1))))
})

test_that("disclosure records omitted reads and a continuation action", {
  skip_if_no("ggplot2")
  fig <- context_assembly_fig(context = FALSE)
  element <- gl_bindings(fig)$element[1L]
  packet <- gl_context_assemble(fig, question = "Inspect this point", intent = "inspect",
                                focus = list(elements = element), disclose = "summary")

  omitted_sources <- vapply(packet$omitted, function(x) x$source %||% "", "")
  expect_true("data.rows" %in% omitted_sources)
  expect_true(any(vapply(packet$actions, function(x) identical(x$name, "get_rows"), logical(1))))
  expect_equal(packet$disclosure, "summary")
})

test_that("the MCP-shaped interface works without aisdk and commits checked writes", {
  skip_if_no("ggplot2")
  fig <- context_assembly_fig(context = FALSE)
  session <- gl_mcp_session(fig, stage = "meaning", disclose = "summary")
  tool_definitions <- gl_mcp_tools(session)
  names <- vapply(tool_definitions, function(x) x$name, "")
  expect_true("assemble_context" %in% names)
  expect_true("propose" %in% names)
  assembly_schema <- tool_definitions[[match("assemble_context", names)]]$inputSchema
  expect_equal(assembly_schema$properties$sources$items$type, "string")

  element <- gl_bindings(fig)$element[1L]
  call <- gl_mcp_call(session, "propose", list(
    layer = "meaning",
    anchor = list(element = element),
    body = list(text = "MCP note")
  ))
  expect_false(isTRUE(call$is_error))
  expect_equal(call$result$committed, 1L)
  expect_equal(nrow(gl_records(call$session$fig, "meaning")), 1L)

  assembled <- gl_mcp_call(call$session, "assemble_context", list(
    question = "Inspect this point",
    focus = list(elements = element)
  ))
  expect_false(isTRUE(assembled$is_error))
  expect_equal(assembled$result$request$intent, "inspect")
})

test_that("an agent packet honors the host's stage and disclosure", {
  skip_if_no("ggplot2")
  fig <- context_assembly_fig()
  el <- gl_bindings(fig)$element[1]
  fig <- gl_record(fig, "narrative", gl_anchor(element = el), list(text = "unread narrative"))
  fig <- gl_add_context(fig, "code", list(script = list(code = "private script")))
  sess <- gl_mcp_session(fig, stage = "claim", disclose = "summary")
  wide <- gl_mcp_call(sess, "assemble_context", list(disclose = "rows"))
  expect_true(wide$is_error)
  packet <- gl_mcp_call(sess, "assemble_context", list(focus = list(elements = el)))$result
  expect_length(packet$sections$semantics, 0)
  expect_false(grepl("private script", tool_json(packet), fixed = TRUE))
  expect_length(packet$request$focus$rows, 0)
  rows <- gl_context_assemble(fig, focus = list(table = "raw", rows = 1:12),
                              disclose = "rows", max_rows = 2)
  expect_length(rows$sections$data$selected_rows$raw, 2)
  expect_length(rows$request$focus$rows$raw, 2)
  expect_true(any(vapply(rows$omitted, function(x) identical(x$source, "raw"), logical(1))))
})

test_that("follow-up sources, stale plans and unresolved scopes are explicit", {
  skip_if_no("ggplot2")
  fig <- context_assembly_fig()
  fig <- gl_add_context(fig, "analysis_method", list(method = "linear regression"),
                        source = "methods appendix")
  plan <- gl_context_plan(fig, question = "How was this fitted?", sources = "analysis_method",
                          focus = list(table = "absent"), disclose = "rows")
  packet <- gl_context_assemble(fig, plan)
  expect_equal(packet$sections$context$analysis_method$value$method, "linear regression")
  expect_length(packet$request$focus$unresolved, 1)
  expect_length(packet$sections$semantics, 0)
  new_fig <- fig
  new_fig$meta$id <- "another-substrate"
  expect_error(gl_context_assemble(new_fig, plan), "substrate")
})
