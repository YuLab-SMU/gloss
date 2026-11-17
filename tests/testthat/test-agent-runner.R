# M4 scripted aisdk path and cache replay.

m4_scripted_model <- function(steps) {
  R6::R6Class("gloss_m4_scripted_model", inherit = aisdk::LanguageModelV1,
    public = list(
      steps = NULL,
      seen = 0L,
      initialize = function(steps) {
        super$initialize(provider = "scripted", model_id = "m4-scripted")
        self$steps <- steps
      },
      format_tool_result = function(tool_call_id, tool_name, result_content) {
        list(role = "tool", tool_call_id = tool_call_id, name = tool_name, content = result_content)
      },
      do_generate = function(params) {
        self$seen <- self$seen + 1L
        i <- self$seen
        step <- self$steps[[min(i, length(self$steps))]]
        usage <- list(prompt_tokens = 3, completion_tokens = 2, total_tokens = 5)
        if (is.character(step)) return(list(text = step, tool_calls = NULL, finish_reason = "stop", usage = usage))
        list(text = "", finish_reason = "tool_calls", usage = usage,
             tool_calls = list(list(id = paste0("m4-call", i), name = step$name, arguments = step$arguments)))
      }
    ))$new(steps)
}

test_that("a scripted stage commits a checked semantic record", {
  skip_if_no("ggplot2", "aisdk", "R6")
  withr::local_options(aisdk.skip_internet_check = TRUE)
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  fig <- gloss(p, context = FALSE)
  element <- gl_elements(fig)$id[1]
  model <- m4_scripted_model(list(
    list(name = "overview", arguments = list()),
    list(name = "propose", arguments = list(layer = "meaning", anchor = element,
                                             body = list(text = "point meaning", provenance = "speculative"))),
    "done"
  ))
  out <- gloss:::run_stage(fig, "meaning", model = model, max_steps = 5L,
                           cache_dir = withr::local_tempdir())
  expect_equal(length(out$report$committed), 1L)
  expect_equal(gl_records(out$fig, "meaning")$status, "speculative")
  expect_false(out$report$cache_hit)
})

test_that("stage cache replays through validation and misses after a substrate change", {
  skip_if_no("ggplot2", "aisdk", "R6")
  withr::local_options(aisdk.skip_internet_check = TRUE)
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  fig <- gloss(p, context = FALSE)
  element <- gl_elements(fig)$id[1]
  cache <- withr::local_tempdir()
  model <- m4_scripted_model(list(
    list(name = "propose", arguments = list(layer = "meaning", anchor = element,
                                             body = list(text = "cached meaning", provenance = "speculative"))),
    "done"
  ))
  first <- gloss:::run_stage(fig, "meaning", model = model, max_steps = 4L, cache_dir = cache)
  expect_false(first$report$cache_hit)
  second <- gloss:::run_stage(fig, "meaning", model = model, max_steps = 4L, cache_dir = cache)
  expect_true(second$report$cache_hit)
  expect_equal(gl_records(second$fig, "meaning")$status, "speculative")

  edited <- gloss(ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
                    ggplot2::geom_point() + ggplot2::labs(title = "edited"), context = FALSE)
  third <- gloss:::run_stage(edited, "meaning", model = model, max_steps = 4L, cache_dir = cache)
  expect_false(third$report$cache_hit)
})

test_that("gl_annotate returns an ordered stage report", {
  skip_if_no("ggplot2", "aisdk", "R6")
  withr::local_options(aisdk.skip_internet_check = TRUE)
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  fig <- gloss(p, context = FALSE)
  element <- gl_elements(fig)$id[1]
  model <- m4_scripted_model(list(
    "done",
    "done",
    list(name = "propose", arguments = list(layer = "meaning", anchor = element,
                                             body = list(text = "ordered", provenance = "speculative"))),
    "done"
  ))
  result <- gl_annotate(fig, stages = "meaning", model = model, max_steps = 4L,
                        cache_dir = withr::local_tempdir())
  expect_s3_class(result, "gloss_annotation_run")
  expect_equal(names(result$reports), c("classify", "bind", "meaning"))
  expect_equal(gl_records(result$fig, "meaning")$status, "speculative")
})

test_that("prepared visual context becomes a multimodal stage task", {
  skip_if_no("aisdk")
  task <- gloss:::agent_stage_task("meaning", list(image = "data:image/png;base64,AAAA", condition = "prepared_visual"))
  expect_type(task, "list")
  expect_equal(task[[1]]$role, "user")
  expect_true(any(vapply(task[[1]]$content, function(x) identical(x$type, "input_image"), logical(1))))
})
