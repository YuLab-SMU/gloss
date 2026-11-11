test_that("every built-in plugin passes its contract", {
  pl <- gl_plugins()
  expect_true(all(c("engine", "context", "projection") %in% pl$kind))
  for (i in seq_len(nrow(pl))) {
    eng_pkgs <- gl_plugin(pl$kind[i], pl$name[i])$packages
    if (identical(pl$kind[i], "engine")) {
      pkgs <- setdiff(eng_pkgs, "grid")
      if (any(!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE))) next
    }
    res <- suppressWarnings(gl_test_plugin(pl$kind[i], pl$name[i]))
    expect_false(any(res$passed %in% FALSE),
                 label = paste(pl$kind[i], pl$name[i], paste(res$message[res$passed %in% FALSE], collapse = "; ")))
  }
})

test_that("registration validates the declaration", {
  expect_error(gl_register("nope", "x", "0.1.0"), "must be one of")
  expect_error(gl_register("check", "bad name!", "0.1.0", run = identity), "name")
  expect_error(gl_register("check", "c1", "x.y", run = identity), "version")
  expect_error(gl_register("check", "c1", "0.1.0"), "missing field `run`")
  expect_error(gl_register("check", "c1", "0.1.0", run = 1), "`run` must be a function")
  expect_error(gl_register("check", "c1", "0.1.0", run = identity, api = "9.0.0"), "core API")
  expect_error(gl_register("check", "c1", "0.1.0", run = identity, colour = "red"), "unknown field")
  expect_error(gl_register("check", "c1", "0.1.0", run = identity, schema = list(a = 1)), "schema")
  expect_error(gl_register("layer", "l1", "0.1.0", body = list(x = "nope")), "body")
})

test_that("a third-party plugin registers, lists, runs and unregisters", {
  gl_register("check", "monotone", "0.1.0", package = "ext",
              schema = list(column = "string", direction = c("up", "down")),
              run = function(table, args) {
                d <- diff(table[[args$column]])
                if (args$direction == "up") all(d >= 0) else all(d <= 0)
              })
  on.exit(gl_unregister("check", "monotone"))
  expect_true("monotone" %in% gl_plugins("check")$name)
  p <- gl_plugin("check", "monotone")
  expect_length(gl_schema_validate(list(column = "y", direction = "up"), p$schema), 0L)
  expect_match(gl_schema_validate(list(column = "y", direction = "sideways"), p$schema), "not one of")
  expect_true(p$run(data.frame(y = c(1, 2, 5)), list(column = "y", direction = "up")))
  expect_true(gl_unregister("check", "monotone"))
  expect_null(gl_plugin("check", "monotone", must_exist = FALSE))
})

test_that("a third-party engine is dispatched by class and passes the contract", {
  # ADR-0006 point 4: the engine no longer builds a grob (the toy engine had
  # `grob = function(state) pointsGrob(...)`); the object draws itself through
  # its print() method and gloss captures that page.
  registerS3method("print", "toy_plot", function(x, ...) {
    grid::grid.newpage()
    grid::grid.points(x$x, x$y, pch = 19, default.units = "native",
                      vp = grid::viewport(xscale = c(0, 10), yscale = c(0, 10)))
    invisible(x)
  }, envir = baseenv())
  gl_register("engine", "toy", "0.1.0", package = "ext",
              classes = "toy_plot",
              prepare = function(x, width, height) list(x = x),
              tables = function(state) list(list(name = "raw", data = data.frame(id = c("a", "b"), x = state$x$x, y = state$x$y))),
              example = function() structure(list(x = c(2, 8), y = c(3, 7)), class = "toy_plot"))
  on.exit(gl_unregister("engine", "toy"))
  toy <- structure(list(x = c(2, 8), y = c(3, 7)), class = "toy_plot")
  fig <- gloss(toy, width = 3, height = 3, context = FALSE)
  expect_equal(fig$meta$engine, "toy")
  expect_equal(fig$tables$raw$key, "id")
  expect_equal(sum(fig$substrate$elements$tag == "circle"), 2L)
  res <- gl_test_plugin("engine", "toy")
  expect_false(any(res$passed %in% FALSE))
})

test_that("an engine no longer builds a grob, and a drawing step must draw the input's own page", {
  expect_error(gl_register("engine", "old", "0.1.0", classes = "old_plot",
                           prepare = function(x, width, height) list(x = x),
                           grob = function(state) grid::rectGrob()),
               "no longer part of the engine contract")
  expect_error(gl_register("engine", "bad", "0.1.0", classes = "x", page = "pdf",
                           prepare = function(x, width, height) list(x = x)), "page")
  # A drawing step that keeps what drawing returns, and draws the same page.
  registerS3method("print", "toy_drawn", function(x, ...) {
    grid::grid.newpage()
    grid::grid.circle(r = x$r)
    invisible(x)
  }, envir = baseenv())
  ex <- function() structure(list(r = 0.3), class = "toy_drawn")
  gl_register("engine", "kept", "0.1.0", classes = "toy_drawn",
              prepare = function(x, width, height) list(x = x),
              draw = function(state) {
                print(state$x)
                state$drawn <- "what drawing returned"
                state
              },
              tables = function(state) list(list(name = "kept", data = data.frame(id = "a", v = state$drawn))),
              example = ex)
  on.exit(gl_unregister("engine", "kept"), add = TRUE)
  fig <- gloss(ex(), width = 2, height = 2, context = FALSE)
  expect_equal(fig$tables$kept$data$v, "what drawing returned")
  res <- gl_test_plugin("engine", "kept")
  expect_true(res$passed[res$check == "its drawing step draws the page the input draws"])
  # A drawing step that draws another page fails the contract.
  gl_register("engine", "other", "0.1.0", classes = "toy_drawn",
              prepare = function(x, width, height) list(x = x),
              draw = function(state) {
                grid::grid.newpage()
                grid::grid.rect()
                state
              },
              example = ex)
  on.exit(gl_unregister("engine", "other"), add = TRUE)
  res <- gl_test_plugin("engine", "other")
  hit <- res$check == "its drawing step draws the page the input draws"
  expect_false(res$passed[hit])
  expect_match(res$message[hit], "differs")
})

test_that("the schema language checks shapes", {
  expect_length(gl_schema_check(list(a = "string", "b?" = "number", c = c("x", "y"))), 0L)
  expect_length(gl_schema_check(list(type = "array", items = list(id = "integer"))), 0L)
  expect_match(gl_schema_check(list(type = "wat")), "unknown type")
  s <- list(a = "string", "b?" = "number", "tags?" = list(type = "array", items = "string", max = 2))
  expect_length(gl_schema_validate(list(a = "x"), s), 0L)
  expect_length(gl_schema_validate(list(a = "x", b = 2, tags = c("p", "q")), s), 0L)
  expect_match(gl_schema_validate(list(b = 2), s), "missing field 'a'")
  expect_match(gl_schema_validate(list(a = "x", z = 1), s), "unknown field")
  expect_match(gl_schema_validate(list(a = "x", tags = c("p", "q", "r")), s), "at most 2")
  expect_match(gl_schema_validate(list(a = 1), s), "single string")
})
