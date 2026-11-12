# gl_tools(): read-only tools over one figure and one `propose` that
# validates on submit (design: agent tools; plan 2026-11-12-agent-path,
# Task 3, step 3). The tools' work is plain R (tool_specs()), tested here
# without aisdk; gl_tools() wraps it for aisdk, tested with a scripted
# model and no network.

tool_fig <- function() {
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, colour = factor(cyl))) + ggplot2::geom_point() +
    ggplot2::facet_wrap(~am)
  gloss(p, width = 7, height = 4, context = FALSE)
}

run_spec <- function(specs, name, args = list()) {
  jsonlite::fromJSON(specs$run(name, args), simplifyVector = TRUE)
}

centre_of <- function(fig, id) {
  e <- gl_elements(fig, list(id = id))
  list(x = (e$x0 + e$x1) / 2, y = (e$y0 + e$y1) / 2, panel = e$panel)
}

test_that("the tools read the figure and return JSON a model can use", {
  skip_if_no("ggplot2")
  fig <- tool_fig()
  specs <- tool_specs(fig)
  expect_setequal(specs$names, c("overview", "find_elements", "get_element", "get_binding", "describe_table",
                                 "get_rows", "find_rows", "to_data", "propose"))
  ov <- run_spec(specs, "overview")
  expect_equal(ov$engine, "ggplot")
  expect_equal(c(ov$width_pt, ov$height_pt), c(504, 288))
  expect_equal(ov$panels$id, c("panel1", "panel2"))
  expect_true(all(c("x_min", "x_max", "y_min", "y_max", "flipped") %in% names(ov$panels)))
  expect_true("built_layer1" %in% ov$tables$name)

  b <- gl_bindings(fig)
  at <- centre_of(fig, b$element[5])
  hit <- run_spec(specs, "find_elements", list(x = at$x, y = at$y))
  expect_equal(hit$id[hit$tag == "circle"][1], b$element[5])
  el <- run_spec(specs, "get_element", list(element = b$element[5]))
  expect_equal(el$panel, at$panel)
  expect_equal(el$tag, "circle")

  gb <- run_spec(specs, "get_binding", list(element = b$element[5]))
  expect_equal(c(gb$table, gb$row, gb$status), c("built_layer1", as.character(b$row[5]), "verified"))

  dt <- run_spec(specs, "describe_table", list(table = "built_layer1"))
  expect_equal(dt$rows, 32L)
  expect_true(all(c("x", "y", "PANEL") %in% dt$columns$name))
  rows <- run_spec(specs, "get_rows", list(table = "built_layer1", rows = c(1L, 5L)))
  expect_equal(rows$row, c(1L, 5L))
  expect_equal(rows$x, gl_table(fig, "built_layer1")$x[c(1, 5)])

  d <- run_spec(specs, "to_data", list(panel = at$panel, x = at$x, y = at$y))
  near <- run_spec(specs, "find_rows", list(table = "built_layer1", panel = at$panel, x = d$x, y = d$y))
  expect_equal(near$row[1], b$row[5])
  expect_true(nrow(near) <= 5L)
})

test_that("propose is the only tool that writes, and it validates on submit", {
  skip_if_no("ggplot2")
  fig <- tool_fig()
  specs <- tool_specs(fig)
  b <- gl_bindings(fig)
  at <- centre_of(fig, b$element[2])
  run_spec(specs, "overview")
  run_spec(specs, "find_elements", list(x = at$x, y = at$y))
  run_spec(specs, "get_element", list(element = b$element[2]))
  run_spec(specs, "get_binding", list(element = b$element[2]))
  run_spec(specs, "describe_table", list(table = "built_layer1"))
  run_spec(specs, "get_rows", list(table = "built_layer1", rows = 1:3))
  run_spec(specs, "find_rows", list(table = "built_layer1", panel = at$panel, x = 3, y = 20))
  run_spec(specs, "to_data", list(panel = at$panel, x = at$x, y = at$y))
  expect_equal(length(specs$state$calls), 8L)
  expect_equal(length(specs$state$proposals), 0L)

  wrong <- run_spec(specs, "propose", list(element = b$element[2], table = "built_layer1", row = b$row[3]))
  expect_equal(wrong$outcome, "rejected")
  expect_match(wrong$reasons, "pt from")
  right <- run_spec(specs, "propose", list(element = b$element[2], table = "built_layer1", row = b$row[2]))
  expect_equal(right$outcome, "accepted")
  expect_equal(right$status, "verified")
  expect_equal(vapply(specs$state$proposals, function(p) p$outcome, ""), c("rejected", "accepted"))
  expect_equal(specs$state$proposals[[2]]$record$row, b$row[2])
})

test_that("a call a tool cannot serve comes back as data, never as an R error", {
  skip_if_no("ggplot2")
  specs <- tool_specs(tool_fig())
  for (bad in list(
    list("find_elements", list(x = "left", y = 3)),
    list("find_elements", list(x = 10)),
    list("get_element", list(element = "e99999")),
    list("get_rows", list(table = "built_layer1", rows = 1:50)),
    list("get_rows", list(table = "nope", rows = 1L)),
    list("find_rows", list(table = "raw", panel = "panel1", x = 1, y = 2)),
    list("to_data", list(panel = "panel7", x = 1, y = 2)),
    list("no_such_tool", list())
  )) {
    out <- run_spec(specs, bad[[1]], bad[[2]])
    expect_true(is.character(out$error) && nzchar(out$error[1]), label = bad[[1]])
  }
  expect_true(all(!vapply(specs$state$calls, function(c) c$ok, TRUE)))
})

test_that("bindings can be hidden for a run, and propose still checks", {
  skip_if_no("ggplot2")
  fig <- tool_fig()
  b <- gl_bindings(fig)
  specs <- tool_specs(fig, hide = unique(b$leaf))
  gb <- run_spec(specs, "get_binding", list(element = b$element[1]))
  expect_true(gb$hidden)
  expect_null(gb$row)
  ok <- run_spec(specs, "propose", list(element = b$element[1], table = b$table[1], row = b$row[1]))
  expect_equal(ok$outcome, "accepted")
})

test_that("the tools work on a figure read back from a bundle", {
  skip_if_no("ggplot2")
  fig <- tool_fig()
  f <- withr::local_tempfile(fileext = ".html")
  gl_write(fig, f)
  specs <- tool_specs(gl_read(f))
  b <- gl_bindings(fig)
  expect_equal(run_spec(specs, "overview")$panels$id, c("panel1", "panel2"))
  expect_equal(run_spec(specs, "propose", list(element = b$element[9], table = b$table[9], row = b$row[9]))$outcome,
               "accepted")
})

# A model that plays a fixed script of tool calls: no network, no key.
scripted_model <- function(steps) {
  Scripted <- R6::R6Class("gloss_scripted_model", inherit = aisdk::LanguageModelV1, public = list(
    steps = NULL, seen = list(),
    initialize = function(steps) {
      super$initialize(provider = "scripted", model_id = "scripted")
      self$steps <- steps
    },
    format_tool_result = function(tool_call_id, tool_name, result_content) {
      list(role = "tool", tool_call_id = tool_call_id, name = tool_name, content = result_content)
    },
    do_generate = function(params) {
      self$seen[[length(self$seen) + 1L]] <- params
      s <- self$steps[[length(self$seen)]]
      usage <- list(prompt_tokens = 1, completion_tokens = 1, total_tokens = 2)
      if (is.character(s)) return(list(text = s, tool_calls = NULL, finish_reason = "stop", usage = usage))
      list(text = "", finish_reason = "tool_calls", usage = usage,
           tool_calls = list(list(id = paste0("call", length(self$seen)), name = s$name, arguments = s$arguments)))
    }
  ))
  Scripted$new(steps)
}

test_that("gl_tools() gives aisdk tools that a model drives to a validated submission", {
  skip_if_no("ggplot2", "aisdk", "R6")
  withr::local_options(aisdk.skip_internet_check = TRUE)
  fig <- tool_fig()
  b <- gl_bindings(fig)
  at <- centre_of(fig, b$element[7])
  tools <- gl_tools(fig)
  expect_true(all(vapply(tools, function(t) inherits(t, "Tool"), TRUE)))
  expect_setequal(vapply(tools, function(t) t$name, ""),
                  c("overview", "find_elements", "get_element", "get_binding", "describe_table", "get_rows",
                    "find_rows", "to_data", "propose"))
  model <- scripted_model(list(
    list(name = "overview", arguments = list()),
    list(name = "find_elements", arguments = list(x = at$x, y = at$y)),
    list(name = "propose", arguments = list(element = b$element[7], table = "built_layer1", row = b$row[8])),
    list(name = "propose", arguments = list(element = b$element[7], table = "built_layer1", row = b$row[7])),
    "done"
  ))
  res <- aisdk::generate_text(model = model, prompt = "Which row does the circle draw?", tools = tools, max_steps = 8)
  expect_equal(res$text, "done")
  state <- gl_tool_state(tools)
  expect_equal(vapply(state$calls, function(c) c$tool, ""), c("overview", "find_elements", "propose", "propose"))
  expect_equal(vapply(state$proposals, function(p) p$outcome, ""), c("rejected", "accepted"))
  # what the model was handed back after the rejected submission: the reason, as JSON
  last <- model$seen[[4]]$messages
  back <- jsonlite::fromJSON(as.character(last[[length(last)]]$content))
  expect_equal(back$outcome, "rejected")
  expect_match(back$reasons, "pt from")
})
