# M2: append-only records, anchors, JSONL logs and rebasing.

record_fixture <- function() {
  skip_if_no("ggplot2")
  ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
}

test_that("built-in semantic layers are registered through the plugin registry", {
  expect_setequal(gl_plugins("layer")$name,
                  c("structure", "binding", "meaning", "relation", "claim",
                    "narrative", "behavior", "overlay"))
  expect_true(all(vapply(gl_plugins("layer")$name, function(nm) {
    isTRUE(gl_test_plugin("layer", nm)$passed[1L])
  }, logical(1))))
})

test_that("structured anchors resolve by id, data key and role", {
  skip_if_no("ggplot2")
  fig <- gloss(record_fixture(), context = FALSE)
  b <- gl_bindings(fig)
  row <- b$row[b$status == "verified"][1L]
  tab <- b$table[b$status == "verified"][1L]
  el <- b$element[b$status == "verified"][1L]
  vals <- as.list(fig$tables[[tab]]$data[row, fig$tables[[tab]]$key, drop = FALSE])
  names(vals) <- fig$tables[[tab]]$key
  expect_equal(gl_resolve_anchor(fig, gl_anchor(element = el))$status, "unique")
  expect_equal(gl_resolve_anchor(fig, gl_anchor(data_key = list(table = tab, key = vals)))$target, el)
  expect_equal(gl_resolve_anchor(fig, list(type = "role", role = "data"))$status, "ambiguous")
  expect_equal(gl_resolve_anchor(fig, list(type = "element_id", id = "e-does-not-exist"))$status, "missing")
  conservative <- list(selectors = list(
    list(type = "element_id", id = "e-does-not-exist"),
    list(type = "element_id", id = el)
  ))
  expect_equal(gl_resolve_anchor(fig, conservative)$status, "ambiguous")
})

test_that("records append, failed checks stay rejected, and JSONL survives a bundle", {
  skip_if_no("ggplot2")
  fig <- gloss(record_fixture(), context = FALSE)
  el <- gl_bindings(fig)$element[1L]
  fig <- gl_record(fig, "meaning", el, list(text = "a point"), by = "person")
  body <- list(
    text = "weight and fuel economy trend down together",
    check = list(kind = "trend", table = "built_layer1",
                 args = list(response = "y", predictor = "x", expect = "negative"))
  )
  fig <- gl_record(fig, "claim", el, body, by = list(by = "agent", model = "fixture"))
  rows <- gl_records(fig)
  expect_equal(nrow(rows), 2L)
  expect_equal(rows$status, c("proposed", "verified"))
  bad <- body
  bad$check$args$expect <- "positive"
  fig <- gl_record(fig, "claim", el, bad, by = "agent")
  expect_equal(tail(gl_records(fig, "claim")$status, 1L), "rejected")
  d <- withr::local_tempdir()
  gl_write(fig, file.path(d, "x.gloss"), embed = "all")
  expect_true(file.exists(file.path(d, "x.gloss", "layers", "claim.jsonl")))
  back <- gl_read(file.path(d, "x.gloss"))
  expect_identical(back$layers, fig$layers)
  expect_identical(gl_records(back)$status, gl_records(fig)$status)
})

test_that("revision, retraction and conflict resolution preserve history", {
  skip_if_no("ggplot2")
  fig <- gloss(record_fixture(), context = FALSE)
  el <- gl_bindings(fig)$element[1L]
  fig <- gl_record(fig, "meaning", el, list(text = "old"), by = "a")
  id <- gl_records(fig)$id[1L]
  fig <- gl_revise(fig, id, list(text = "new"), by = "b")
  now <- gl_records(fig, "meaning")
  expect_true(any(now$status == "superseded"))
  expect_true(any(vapply(attr(now, "records"), function(r) identical(r$body$text, "new"), logical(1))))
  fig <- gl_record(fig, "meaning", el, list(text = "other"), by = "c")
  expect_equal(nrow(gl_conflicts(fig)), 1L)
  cf <- gl_conflicts(fig)
  fig <- gl_resolve(fig, cf, keep = id, rationale = "new evidence", by = "reviewer")
  rr <- gl_records(fig, "meaning")
  expect_true(any(vapply(attr(rr, "records"), function(r) identical(r$body$type, "resolution"), logical(1))))
  latest <- tail(gl_records(fig, "meaning")$id, 1L)
  fig <- gl_retract(fig, latest, by = "reviewer")
  expect_equal(tail(gl_records(fig, "meaning")$status, 1L), "retracted")
})

test_that("rebase invalidates an element id whose stable data target disappeared", {
  skip_if_no("ggplot2")
  p <- record_fixture()
  fig <- gloss(p, context = FALSE)
  el <- gl_bindings(fig)$element[1L]
  fig <- gl_record(fig, "meaning", el, list(text = "row one"))
  edited <- ggplot2::ggplot(mtcars[mtcars$cyl != 6, ], ggplot2::aes(wt, mpg)) +
    ggplot2::geom_point()
  rebased <- gl_rebase(fig, edited)
  expect_equal(gl_status(rebased)$status, "invalid")
  expect_equal(nrow(gl_repair(rebased)), 1L)
  expect_true(length(rebased$layers$meaning$log) >= 2L)
})
