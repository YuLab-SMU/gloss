# M4 stage capabilities, disclosure and deferred semantic commits.

stage_fig <- function() {
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, colour = factor(cyl))) +
    ggplot2::geom_point()
  gloss(p, context = FALSE)
}

stage_run_spec <- function(specs, name, args = list()) {
  jsonlite::fromJSON(specs$run(name, args), simplifyVector = TRUE)
}

test_that("built-in agent stages have explicit capabilities and prompts", {
  skip_if_no("ggplot2")
  stages <- gl_stages()
  expect_equal(nrow(stages), 10L)
  expect_true(all(c("meaning", "relation", "claim", "review", "repair") %in% stages$name))
  expect_true(all(vapply(c("meaning", "claim", "review"), function(nm) {
    all(gl_test_plugin("stage", nm)$passed)
  }, logical(1))))
  expect_equal(gloss:::stage_dependency_order(c("claim")), c("classify", "bind", "meaning", "relation", "claim"))
})

test_that("stage disclosure hides rows and binding answers until rows are enabled", {
  skip_if_no("ggplot2")
  fig <- stage_fig()
  summary_tools <- gloss:::tool_specs(fig, stage = "claim", disclose = "summary")
  hidden <- stage_run_spec(summary_tools, "get_rows", list(table = "built_layer1", rows = 1L))
  expect_true(is.character(hidden$error) && grepl("disclosure", hidden$error[1]))
  binding_hidden <- stage_run_spec(summary_tools, "get_binding", list(element = gl_elements(fig)$id[1]))
  expect_true(is.character(binding_hidden$error) && grepl("disclosure", binding_hidden$error[1]))

  row_tools <- gloss:::tool_specs(fig, stage = "claim", disclose = "rows")
  rows <- stage_run_spec(row_tools, "get_rows", list(table = "built_layer1", rows = 1L))
  expect_equal(rows$row, 1L)
  binding <- stage_run_spec(row_tools, "get_binding", list(element = gl_bindings(fig)$element[1]))
  expect_true(isTRUE(binding$bound))
})

test_that("stage capabilities reject undeclared layers and unsafe payloads", {
  skip_if_no("ggplot2")
  fig <- stage_fig()
  specs <- gloss:::tool_specs(fig, stage = "claim", disclose = "summary")
  bad_layer <- stage_run_spec(specs, "propose", list(
    layer = "meaning", anchor = gl_elements(fig)$id[1], body = list(text = "x")))
  expect_equal(bad_layer$outcome, "rejected")
  expect_equal(bad_layer$stage, "capability")
  unsafe <- stage_run_spec(specs, "propose", list(
    layer = "claim", anchor = gl_elements(fig)$id[1], body = list(text = "https://example.com")))
  expect_equal(unsafe$outcome, "rejected")
  expect_match(unsafe$reasons, "URL")
})

test_that("semantic proposals commit only after validation and keep statuses", {
  skip_if_no("ggplot2")
  fig <- stage_fig()
  specs <- gloss:::tool_specs(fig, stage = "claim", disclose = "summary")
  element <- gl_elements(fig)$id[1]
  wrong <- stage_run_spec(specs, "propose", list(
    layer = "claim", anchor = element,
    body = list(text = "false", table = "built_layer1",
                check = list(kind = "count", args = list(equals = 999L)))))
  expect_equal(wrong$outcome, "rejected")
  speculative <- stage_run_spec(specs, "propose", list(
    layer = "claim", anchor = element,
    body = list(text = "open-world interpretation", provenance = "speculative")))
  expect_equal(speculative$outcome, "accepted")
  committed <- gloss:::stage_commit(fig, specs$state)
  rows <- gl_records(committed$fig, "claim")
  expect_equal(nrow(rows), 1L)
  expect_equal(rows$status, "speculative")
  expect_false(record_is_factual(attr(rows, "records")[[1]]))
  expect_identical(fig$substrate$scene, committed$fig$substrate$scene)
})

test_that("stage candidates survive bundle round trips", {
  skip_if_no("ggplot2")
  fig <- stage_fig()
  specs <- gloss:::tool_specs(fig, stage = "meaning", disclose = "summary")
  stage_run_spec(specs, "propose", list(
    layer = "meaning", anchor = gl_elements(fig)$id[1],
    body = list(text = "a plotted observation", provenance = "speculative")))
  out <- gloss:::stage_commit(fig, specs$state)$fig
  path <- withr::local_tempfile(fileext = ".html")
  gl_write(out, path)
  back <- gl_read(path)
  expect_identical(gl_records(back, "meaning")$status, gl_records(out, "meaning")$status)
  expect_identical(back$substrate$scene, out$substrate$scene)
})

test_that("review candidates are limited to listed conflicts", {
  skip_if_no("ggplot2")
  fig <- stage_fig()
  element <- gl_elements(fig)$id[1]
  a <- gl_record(fig, "claim", element, list(text = "A", provenance = "speculative"), by = "one")
  a <- gl_record(a, "claim", element, list(text = "B", provenance = "speculative"), by = "two")
  conflicts <- gl_conflicts(a)
  expect_equal(nrow(conflicts), 1L)
  state <- gloss:::agent_stage_state(a, "review", metadata = list(run_id = "review-test"))
  good <- gloss:::agent_validate_resolution(a, state, conflicts$records[[1]], conflicts$records[[1]][1],
                                            "keep the first for this fixture", list(source = "fixture"))
  expect_equal(good$outcome, "accepted")
  gloss:::agent_store_candidate(state, good)
  resolved <- gloss:::stage_commit(a, state)$fig
  expect_true(any(gl_records(resolved, "claim")$body[[nrow(gl_records(resolved, "claim"))]]$type == "resolution"))
})

test_that("repair candidates stay within invalid records", {
  skip_if_no("ggplot2")
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  fig <- gloss(p, context = FALSE)
  old <- gl_bindings(fig)$element[1]
  fig <- gl_record(fig, "meaning", old, list(text = "old"), by = "fixture")
  edited <- ggplot2::ggplot(mtcars[mtcars$cyl != 6, ], ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  rebased <- gl_rebase(fig, edited)
  invalid <- gl_repair(rebased)
  expect_equal(nrow(invalid), 1L)
  state <- gloss:::agent_stage_state(rebased, "repair", metadata = list(run_id = "repair-test"))
  candidate <- gloss:::agent_validate_repair(rebased, state, invalid$id[1], "retract")
  expect_equal(candidate$outcome, "accepted")
  gloss:::agent_store_candidate(state, candidate)
  repaired <- gloss:::stage_commit(rebased, state)$fig
  expect_equal(gl_records(repaired, "meaning")$status[nrow(gl_records(repaired, "meaning"))], "retracted")
})
