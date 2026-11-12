test_that("context items are sniffed, and missing ones carry a reason", {
  skip_if_no("ggplot2")
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  fig <- gloss(p, width = 4, height = 3)
  ctx <- gl_context(fig)
  expect_setequal(ctx$item, c("code", "data", "engine", "env", "doc", "git"))
  expect_true(all(ctx$found | !is.na(ctx$reason)))
  expect_equal(gl_context(fig, "code")$value$expr, "p")
  expect_equal(gl_context(fig, "code")$value$call, "gloss(p, width = 4, height = 3)")
  expect_equal(gl_context(fig, "code")$value$call, "gloss(p, width = 4, height = 3)")
  expect_equal(gl_context(fig, "engine")$value$engine, "ggplot")
  expect_equal(gl_context(fig, "engine")$value$describe$layers[[1]]$geom, "GeomPoint")
  env <- gl_context(fig, "env")$value
  expect_equal(env$device$name, "svglite")
  expect_equal(env$r, R.version.string)
  tabs <- gl_context(fig, "data")$value$tables
  expect_equal(tabs[[1]]$key, ".rownames")
  expect_equal(tabs[[1]]$columns$column, names(mtcars))
  expect_false(gl_context(fig, "doc")$found)
  expect_match(gl_context(fig, "doc")$reason, "knitr")
})

test_that("code and data are found in a sourced script", {
  skip_if_no("ggplot2")
  dir <- withr::local_tempdir()
  csv <- file.path(dir, "cars.csv")
  utils::write.csv(mtcars, csv)
  script <- file.path(dir, "plot.R")
  writeLines(c(
    "cars <- read.csv('cars.csv', row.names = 1)",
    "p <- ggplot2::ggplot(cars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()",
    "fig <- gloss(p, width = 4, height = 3)"
  ), script)
  env <- new.env()
  withr::with_dir(dir, sys.source_like(script, env))
  fig <- env$fig
  code <- gl_context(fig, "code")
  expect_true(code$found)
  expect_equal(normalizePath(code$value$script$path), normalizePath(script))
  expect_match(code$value$definition, "ggplot2::ggplot\\(cars")
  data <- gl_context(fig, "data")$value
  expect_equal(data$objects, "cars")
  expect_equal(data$files[[1]]$reader, "read.csv")
  expect_equal(data$files[[1]]$md5, unname(tools::md5sum(csv)))
})

test_that("git reports the commit or says why not", {
  g <- run_sniffer(gl_plugin("context", "git"),
                   list(context = list(code = list(value = list(script = list(path = file.path(tempdir(), "x.R")))))))
  if (g$found) expect_match(g$value$commit, "^[0-9a-f]{40}$") else expect_match(g$reason, "git")
})

test_that("a failing sniffer is reported, not fatal", {
  gl_register("context", "broken", "0.1.0", item = "broken", sniff = function(input) stop("boom"))
  on.exit(gl_unregister("context", "broken"))
  fig <- gloss(grid::rectGrob(), width = 2, height = 2)
  expect_false(gl_context(fig, "broken")$found)
  expect_match(gl_context(fig, "broken")$reason, "boom")
})

test_that("inside knitr the chunk, its label, caption and size are sniffed", {
  skip_if_no("ggplot2", "knitr")
  dir <- withr::local_tempdir()
  rmd <- file.path(dir, "doc.Rmd")
  writeLines(c(
    "---", "title: t", "---", "",
    "```{r cars-plot, fig.cap = 'Weight and fuel use', fig.width = 6, fig.height = 4}",
    "p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()",
    "fig <- gloss(p)",
    "```"
  ), rmd)
  env <- new.env(parent = environment())
  withr::with_dir(dir, knitr::knit(rmd, output = file.path(dir, "doc.md"), envir = env, quiet = TRUE))
  fig <- env$fig
  doc <- gl_context(fig, "doc")
  expect_true(doc$found)
  expect_equal(doc$value$chunk, "cars-plot")
  expect_equal(doc$value$caption, "Weight and fuel use")
  code <- gl_context(fig, "code")$value
  expect_equal(code$chunk$label, "cars-plot")
  expect_match(code$definition, "ggplot2::ggplot\\(mtcars")
  expect_equal(c(fig$meta$width, fig$meta$height), c(6, 4))
  expect_equal(fig$meta$size_basis, "knitr chunk")
  expect_equal(gl_context(fig, "data")$value$objects, "mtcars")
})
