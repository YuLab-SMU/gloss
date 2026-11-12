# gl_propose(): a pairing given as data, checked from the figure alone, with
# three outcomes: accepted, rejected (the check ran and failed, or the
# proposal is not valid data), refused (the check cannot run on this figure).
# Plan 2026-11-12-agent-path, Task 3, step 2.

binding <- function(element, table, row) list(kind = "binding", element = element, table = table, row = row)

p_scatter <- function() ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()

test_that("every element the binder verified is accepted with its own row and rejected with another's", {
  skip_if_no("ggplot2")
  fig <- suppressWarnings(gloss(p_facet(), width = 7, height = 4, context = FALSE))
  b <- gl_bindings(fig)
  b <- b[b$n_rows == 1L & b$status %in% c("verified", "ambiguous"), ]
  expect_gt(nrow(b), 30L)
  ctx <- propose_context(fig)
  for (i in seq_len(nrow(b))) {
    r <- check_proposal(ctx, binding(b$element[i], b$table[i], b$row[i]))
    expect_equal(r$outcome, "accepted", label = b$element[i])
    expect_equal(r$record$status, b$status[i], label = b$element[i])
    expect_equal(r$record[c("element", "leaf", "table", "row")],
                 list(element = b$element[i], leaf = b$leaf[i], table = b$table[i], row = b$row[i]))
    expect_lt(abs(r$record$dev - b$dev[i]), 0.01)
  }
  # the next element's row, in the same table: another place on the page
  v <- b[b$status == "verified", ]
  for (i in seq_len(nrow(v))) {
    other <- v$row[v$table == v$table[i] & v$element != v$element[i]][1]
    if (is.na(other)) next
    r <- check_proposal(ctx, binding(v$element[i], v$table[i], other))
    expect_equal(r$outcome, "rejected", label = v$element[i])
    expect_match(r$reasons, "pt from|another panel", label = v$element[i])
    expect_null(r$record)
  }
})

test_that("gl_propose() answers the same on a figure read back from a bundle", {
  skip_if_no("ggplot2")
  fig <- gloss(p_scatter(), width = 7, height = 5, context = FALSE)
  b <- gl_bindings(fig)
  f <- withr::local_tempfile(fileext = ".html")
  gl_write(fig, f)
  back <- gl_read(f)
  right <- binding(b$element[4], "built_layer1", b$row[4])
  wrong <- binding(b$element[4], "built_layer1", b$row[5])
  expect_s3_class(gl_propose(fig, right), "gloss_proposal")
  expect_identical(gl_propose(back, right), gl_propose(fig, right))
  expect_identical(gl_propose(back, wrong), gl_propose(fig, wrong))
  expect_equal(gl_propose(back, right)$outcome, "accepted")
  expect_equal(gl_propose(back, wrong)$outcome, "rejected")
  # also without the bindings made at capture: the check does not read them
  bare <- gloss(p_scatter(), width = 7, height = 5, context = FALSE, bind = FALSE)
  expect_equal(gl_propose(bare, right)$outcome, "accepted")
  expect_equal(gl_propose(bare, wrong)$outcome, "rejected")
})

test_that("a proposal that is not valid data is rejected before any check", {
  skip_if_no("ggplot2")
  fig <- gloss(p_scatter(), width = 7, height = 5, context = FALSE)
  el <- gl_bindings(fig)$element[1]
  bad <- list(
    list(kind = "binding", element = el, table = "built_layer1"),
    list(kind = "binding", element = el, table = "built_layer1", row = 1L, note = "<b>hi</b>"),
    list(kind = "style", element = el, table = "built_layer1", row = 1L),
    list(kind = "binding", element = el, table = "built_layer1", row = "1"),
    list(kind = "binding", element = el, table = "built_layer1", row = 1.5),
    list(kind = "binding", element = c(el, el), table = "built_layer1", row = 1L),
    "binding"
  )
  for (p in bad) {
    r <- gl_propose(fig, p)
    expect_equal(r$outcome, "rejected")
    expect_equal(r$stage, "schema")
    expect_null(r$record)
  }
  # well formed, naming what is not there
  for (p in list(binding("e99999", "built_layer1", 1L), binding(el, "https://example.org/x", 1L),
                 binding(el, "built_layer1", 33L), binding(el, "built_layer1", 0L))) {
    r <- gl_propose(fig, p)
    expect_equal(r$outcome, "rejected")
    expect_equal(r$stage, "exists")
  }
  # a value that is not in the figure is not echoed back at length
  long <- paste(rep("x", 500), collapse = "")
  expect_lt(nchar(gl_propose(fig, binding(long, "built_layer1", 1L))$reasons), 120L)
})

test_that("a row of another panel is rejected even where its values are the same", {
  skip_if_no("ggplot2")
  d <- data.frame(x = c(1, 2, 1, 2), y = c(1, 2, 1, 2), f = c("a", "a", "b", "b"))
  p <- ggplot2::ggplot(d, ggplot2::aes(x, y)) + ggplot2::geom_point() + ggplot2::facet_wrap(~f)
  fig <- gloss(p, width = 6, height = 3, context = FALSE)
  b <- gl_bindings(fig)
  expect_equal(b$status, rep("verified", 4))
  first <- b[b$row == 1L, ]
  expect_equal(gl_propose(fig, binding(first$element, "built_layer1", 1L))$outcome, "accepted")
  r <- gl_propose(fig, binding(first$element, "built_layer1", 3L))
  expect_equal(r$outcome, "rejected")
  expect_match(r$reasons, "another panel")
})

test_that("an element drawn outside the layers is rejected, not paired by chance", {
  skip_if_no("ggplot2")
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, colour = factor(cyl))) + ggplot2::geom_point()
  fig <- gloss(p, width = 7, height = 5, context = FALSE)
  el <- gl_elements(fig)
  keys <- el$id[el$tag == "circle" & !el$id %in% gl_bindings(fig)$element]
  expect_equal(length(keys), 3L)
  for (k in keys) expect_equal(gl_propose(fig, binding(k, "built_layer1", 1L))$outcome, "rejected")
})

test_that("what the figure does not let it check is refused with the reason, never rejected or accepted", {
  skip_if_no("ggplot2")
  polar <- gloss(p_scatter() + ggplot2::coord_polar(), width = 5, height = 5, context = FALSE)
  b <- gl_bindings(polar)
  r <- gl_propose(polar, binding(b$element[1], b$table[1], b$row[1]))
  expect_equal(r$outcome, "refused")
  expect_match(r$reasons, "scales")
  expect_null(r$record)
  # an element that draws a whole group of rows
  d <- data.frame(x = rep(1:5, 2), y = c(1, 3, 2, 5, 4, 2, 2, 4, 3, 6), g = rep(c("a", "b"), each = 5))
  lines <- gloss(ggplot2::ggplot(d, ggplot2::aes(x, y, group = g)) + ggplot2::geom_line(),
                 width = 5, height = 4, context = FALSE)
  bl <- gl_bindings(lines)
  r <- gl_propose(lines, binding(bl$element[1], bl$table[1], bl$row[1]))
  expect_equal(r$outcome, "refused")
  expect_match(r$reasons, "group")
  # engines whose tables the figure cannot place yet
  base <- gloss(base_scatter, width = 5, height = 4, context = FALSE)
  bb <- gl_bindings(base)
  r <- gl_propose(base, binding(bb$element[1], bb$table[1], bb$row[1]))
  expect_equal(r$outcome, "refused")
  expect_match(r$reasons, "base")
  # and that is said before the row is looked at: a heatmap's binding names a
  # cell of the matrix, a number beyond the table's rows, and "outside the
  # table" was the answer (bench run 2026-11-12-1918-bundle-dev, 8 pairings)
  r <- gl_propose(base, binding(bb$element[1], bb$table[1], 100000L))
  expect_equal(r$outcome, "refused")
  expect_match(r$reasons, "base")
})

test_that("a flipped panel and a dense leaf are checked like any other", {
  skip_if_no("ggplot2")
  fig <- gloss(p_scatter() + ggplot2::coord_flip(), width = 7, height = 5, context = FALSE)
  b <- gl_bindings(fig)
  expect_equal(gl_propose(fig, binding(b$element[3], b$table[3], b$row[3]))$outcome, "accepted")
  expect_equal(gl_propose(fig, binding(b$element[3], b$table[3], b$row[9]))$outcome, "rejected")
  set.seed(4)
  d <- data.frame(x = rnorm(12000), y = rnorm(12000))
  dense <- gloss(ggplot2::ggplot(d, ggplot2::aes(x, y)) + ggplot2::geom_point(size = 0.3),
                 width = 5, height = 4, context = FALSE)
  bd <- gl_bindings(dense, where = list(status = "verified"))
  ctx <- propose_context(dense)
  for (i in c(1L, 500L, nrow(bd))) {
    r <- check_proposal(ctx, binding(bd$element[i], bd$table[i], bd$row[i]))
    expect_equal(r$outcome, "accepted")
    expect_equal(r$record$status, "verified")
  }
  far <- bd$row[which.max(abs(d$x[bd$row] - d$x[bd$row[1]]))]
  expect_equal(check_proposal(ctx, binding(bd$element[1], bd$table[1], far))$outcome, "rejected")
})

# Two layers that draw at the same places: every point twice, the second as
# an open circle around the first.
p_twice <- function() {
  d <- data.frame(x = c(1, 2, 3, 4), y = c(2, 4, 1, 3))
  ggplot2::ggplot(d, ggplot2::aes(x, y)) + ggplot2::geom_point() + ggplot2::geom_point(shape = 1, size = 5)
}

test_that("a row of another layer drawn at the same place is rejected: the figure says which layer drew the leaf", {
  # The pilot's arm without a model (bench run 2026-11-12-1906-pilot-enumerate):
  # trying every row had a row of another layer accepted on 7 of 30 questions,
  # where two layers draw at one place. Which layer drew a leaf the engine
  # reads from the plot's own structure at capture, and the bindings keep it.
  skip_if_no("ggplot2")
  fig <- gloss(p_twice(), context = FALSE)
  b <- gl_bindings(fig)
  b <- b[b$status == "verified", ]
  tabs <- c("built_layer1", "built_layer2")
  expect_equal(as.integer(table(b$table)[tabs]), c(4L, 4L))
  ctx <- propose_context(fig)
  for (i in seq_len(nrow(b))) {
    own <- check_proposal(ctx, binding(b$element[i], b$table[i], b$row[i]))
    expect_equal(own$outcome, "accepted", label = b$element[i])
    expect_true(own$record$layer_known)
    r <- check_proposal(ctx, binding(b$element[i], setdiff(tabs, b$table[i]), b$row[i]))
    expect_equal(r$outcome, "rejected", label = b$element[i])
    expect_equal(r$stage, "check")
    # the reason names the table of the layer that drew the leaf
    expect_match(r$reasons, sprintf("'%s'", b$table[i]), fixed = TRUE)
  }
  # trying every row of every table finds each element's own row and nothing else
  for (i in seq_len(nrow(b))) {
    hits <- 0L
    for (t in tabs) for (row in 1:4) hits <- hits + (check_proposal(ctx, binding(b$element[i], t, row))$outcome == "accepted")
    expect_equal(hits, 1L, label = b$element[i])
  }
  # and the same on the figure read back from a bundle
  f <- withr::local_tempfile(fileext = ".html")
  gl_write(fig, f)
  back <- gl_read(f)
  expect_equal(gl_propose(back, binding(b$element[1], setdiff(tabs, b$table[1]), b$row[1]))$outcome, "rejected")
  expect_equal(gl_propose(back, binding(b$element[1], b$table[1], b$row[1]))$outcome, "accepted")
})

test_that("a figure without bindings is checked by place alone, and an acceptance says so", {
  skip_if_no("ggplot2")
  b <- gl_bindings(gloss(p_twice(), context = FALSE))
  b <- b[b$status == "verified", ]
  bare <- gloss(p_twice(), context = FALSE, bind = FALSE)
  other <- setdiff(c("built_layer1", "built_layer2"), b$table[1])
  r <- gl_propose(bare, binding(b$element[1], other, b$row[1]))
  expect_equal(r$outcome, "accepted")
  expect_false(r$record$layer_known)
  expect_output(print(r), "by its place only")
  own <- gl_propose(gloss(p_twice(), context = FALSE), binding(b$element[1], b$table[1], b$row[1]))
  expect_true(own$record$layer_known)
  expect_output(print(own), "accepted")
  expect_false(any(grepl("by its place only", utils::capture.output(print(own)))))
})
