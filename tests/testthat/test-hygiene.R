# AGENTS.md, Safety and CRAN Hygiene: no `<<-`. R CMD check does not flag a
# closure that writes its enclosing function's locals, so the suite does.
test_that("no function of the package uses superassignment", {
  ns <- asNamespace("gloss")
  fns <- Filter(is.function, mget(ls(ns, all.names = TRUE), envir = ns))
  uses <- vapply(fns, function(f) "<<-" %in% all.names(body(f)), logical(1))
  expect_identical(names(fns)[uses], character())
})
