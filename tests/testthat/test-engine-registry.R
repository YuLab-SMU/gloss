test_that("gl_register_engine validates inputs and manages registry", {
  withr::defer(reset_engine_registry(register_builtins = TRUE))
  reset_engine_registry(register_builtins = FALSE)

  expect_error(gl_register_engine("", "foo", identity), "non-empty")
  expect_error(gl_register_engine("e1", character(), identity), "non-empty")
  expect_error(gl_register_engine("e1", "foo", "not_a_fn"), "function")

  spec <- gl_register_engine(
    name = "demo",
    classes = c("demo_plot", "demo_alt"),
    capture_fn = function(x, ...) x,
    version = "1.2.3",
    description = "Demo plotting engine"
  )

  expect_s3_class(spec, "gloss_engine")
  expect_identical(get_engine("demo")$name, "demo")
  expect_identical(engine_version_string(spec), "1.2.3")

  expect_error(
    gl_register_engine("demo", "demo_plot", identity, overwrite = FALSE),
    "already registered"
  )

  # Overwrite replaces cleanly
  gl_register_engine("demo", "demo_plot", identity, version = "2.0.0", overwrite = TRUE)
  expect_identical(get_engine("demo")$version, "2.0.0")

  out <- capture.output(print(get_engine("demo")))
  expect_true(any(grepl("<gloss_engine demo>", out, fixed = TRUE)))

  expect_true(unregister_engine("demo"))
  expect_null(get_engine("demo"))
})

test_that("resolve_engine respects class specificity, priority, and recency", {
  withr::defer(reset_engine_registry(register_builtins = TRUE))
  reset_engine_registry(register_builtins = FALSE)

  gl_register_engine("base_gg", classes = "ggplot", capture_fn = function(x, ...) "base_gg")
  gl_register_engine("pw", classes = "patchwork", capture_fn = function(x, ...) "pw")

  # Subclass specificity: patchwork comes before ggplot in class(x)
  pw_obj <- structure(list(), class = c("patchwork", "ggplot"))
  expect_identical(resolve_engine(pw_obj)$name, "pw")

  # Explicit override wins over class dispatch
  expect_identical(resolve_engine(pw_obj, engine = "base_gg")$name, "base_gg")

  # Recency tie-breaker when priority is equal
  gl_register_engine("gg_newer", classes = "ggplot", capture_fn = function(x, ...) "gg_newer")
  gg_obj <- structure(list(), class = "ggplot")
  expect_identical(resolve_engine(gg_obj)$name, "gg_newer")

  # Higher priority beats recency
  gl_register_engine("gg_hi", classes = "ggplot", capture_fn = function(x, ...) "gg_hi", priority = 10L)
  gl_register_engine("gg_lo_recent", classes = "ggplot", capture_fn = function(x, ...) "gg_lo_recent", priority = 0L)
  expect_identical(resolve_engine(gg_obj)$name, "gg_hi")
})

test_that("resolve_engine handles missing packages and unknown classes cleanly", {
  withr::defer(reset_engine_registry(register_builtins = TRUE))
  reset_engine_registry(register_builtins = FALSE)

  gl_register_engine(
    name = "needs_missing_pkg",
    classes = "special_cls",
    capture_fn = identity,
    packages = "nonexistent_pkg_xyz_999"
  )

  obj <- structure(list(), class = "special_cls")
  expect_error(resolve_engine(obj), "nonexistent_pkg_xyz_999")
  expect_error(resolve_engine(obj, engine = "needs_missing_pkg"), "nonexistent_pkg_xyz_999")
  expect_null(resolve_engine(obj, error = FALSE))

  unknown <- structure(list(), class = "unknown_cls")
  expect_error(resolve_engine(unknown), "No registered gloss engine")
  expect_null(resolve_engine(unknown, error = FALSE))
  expect_error(resolve_engine(unknown, engine = "does_not_exist"), "Unknown gloss engine")
})

test_that("resolve_engine_candidates supports page_kind disambiguation", {
  withr::defer(reset_engine_registry(register_builtins = TRUE))
  reset_engine_registry(register_builtins = FALSE)

  gl_register_engine("e_grid", classes = "function", capture_fn = identity, page_kind = "grid")
  gl_register_engine("e_base", classes = "function", capture_fn = identity, page_kind = "base")
  gl_register_engine("e_any", classes = "function", capture_fn = identity, page_kind = "any", priority = -5L)

  fn <- function() NULL
  all_cands <- resolve_engine_candidates(fn)
  expect_equal(length(all_cands), 3L)

  # Exact page_kind match wins ahead of "any"
  expect_identical(resolve_engine(fn, page_kind = "grid")$name, "e_grid")
  expect_identical(resolve_engine(fn, page_kind = "base")$name, "e_base")
  # Unknown page kind falls back to "any"
  expect_identical(resolve_engine(fn, page_kind = "mixed")$name, "e_any")
})
