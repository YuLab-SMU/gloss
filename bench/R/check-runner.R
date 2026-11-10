# Self-check for the runner (bench v0, Task 3):
#   Rscript bench/R/check-runner.R
# Part 1 runs scripts written here (no third-party code) and checks that the
# runner finds exactly the figures a person sees, recovers them from
# truncated code, and captures them; that a ggplot failing only when printed
# stops the run; that a Gallery post with a no-break space and the site's
# includeHTML() chunk runs cleanly. Part 1c checks outcome classes, package
# names read from errors, install reasons and URL rewrites on the messages the
# first full harvest recorded.
# Part 2 runs three PSUs outside the sample (two Gallery posts, one
# ComplexHeatmap help topic). It executes third-party code, so it only runs
# when GLOSS_BENCH_THIRD_PARTY=true.

source("bench/R/runner.R")

check <- function(name, script, expect_engines) {
  dir <- file.path(tempdir(), "check-runner", name)
  r <- run_script(script, dir, seed = 1, timeout = 300)
  got <- r$candidates$engine
  cat("\n==", name, ":", nrow(r$candidates), "figures,", r$n_expr, "expressions,",
      if (!is.null(r$error)) paste("stopped:", r$error$stage, r$error$message), "\n")
  print(r$candidates)
  ok <- identical(got, expect_engines)
  if (!ok) cat("!! expected", paste(expect_engines, collapse = ", "), "\n")
  for (k in seq_len(nrow(r$candidates))) {
    c1 <- r$candidates[k, ]
    frozen <- list(setup = script$setup, chunks = truncate_script(script, c1$chunk, c1$expr))
    r2 <- run_script(frozen, dir, seed = 1, timeout = 300, offline = TRUE, recover = TRUE, capture = TRUE)
    cat(sprintf("  figure %d: recovered %s/%s, capture %s, %s elements, %s leaves%s\n", k,
                r2$recovered$kind, r2$recovered$engine, r2$capture$status, r2$capture$elements %||% NA,
                r2$capture$leaves %||% NA, if (is.null(r2$capture$message)) "" else paste(":", r2$capture$message)))
    if (!identical(r2$recovered$engine, c1$engine) || !identical(r2$capture$status, "captured")) ok <- FALSE
  }
  ok
}

synthetic <- list(
  setup = character(),
  chunks = list(
    # 1: data only, no figure
    c("d <- data.frame(x = 1:10, y = (1:10)^2)"),
    # 2: one base figure built over three expressions
    c("plot(d$x, d$y)", "lines(d$x, d$y)", "abline(h = 50)"),
    # 3: two base figures in one chunk (a new page starts at the second plot)
    c("hist(d$y)", "barplot(d$y)"),
    # 4: an assigned ggplot (no figure), then the visible object
    c("library(ggplot2)", "p <- ggplot(d, aes(x, y)) + geom_point()", "p"),
    # 5: print() of a ggplot counts once, as an object
    c("print(p + geom_line())"),
    # 6: a grid scene drawn directly
    c("grid::grid.newpage()", "grid::grid.rect(gp = grid::gpar(fill = 'grey90'))", "grid::grid.points(grid::unit(c(.2, .5), 'npc'), grid::unit(c(.3, .6), 'npc'))"),
    # 7: a ComplexHeatmap drawn with draw()
    c("m <- matrix(seq_len(20) / 3, 4)", "ComplexHeatmap::draw(ComplexHeatmap::Heatmap(m))"),
    # 8: a lattice plot: a visible trellis value draws only when auto-printed
    c("lattice::xyplot(y ~ x, d)"),
    # 9: an htmlwidget-like visible value and an error: no figure, run stops
    c("structure(list(), class = 'htmlwidget')", "stop('boom')", "plot(1)")
  )
)
expect <- c("base", "base", "base", "ggplot", "ggplot", "grid", "heatmap", "grid")
ok <- check("synthetic", synthetic, expect)

# Part 1a: a ggplot whose error surfaces only when printed stops the run there,
# as it stops knitr; it is not a figure.
broken <- list(setup = character(), chunks = list(
  c("library(ggplot2)", "d <- data.frame(x = 1:3, y = 1:3)"),
  c("ggplot(d, aes(x, y)) + geom_point(aes(colour = no_such_column))"),
  c("plot(1)")))
r <- run_script(broken, file.path(tempdir(), "check-runner", "broken"), seed = 1)
cat("\n== broken:", nrow(r$candidates), "figures;", if (is.null(r$error)) "no error" else
  paste("stopped:", r$error$stage, "in chunk", r$error$chunk), "\n")
if (nrow(r$candidates) != 0L || !identical(r$error$chunk, 2L)) {
  cat("!! expected no figure and a stop in chunk 2\n"); ok <- FALSE
}

# Part 1a': a Gallery post as published: a no-break space (U+00A0) pasted from
# a web page, and the site's closing includeHTML() chunk, whose file is not in
# the repository. Expect one base figure and a clean run.
post_dir <- file.path(tempdir(), "check-runner", "gallery")
dir.create(post_dir, recursive = TRUE, showWarnings = FALSE)
writeLines(enc2utf8(c("```{r}", "plot(1:3, 1:3)", "```", "",
                      "```{r, echo=FALSE}", "htmltools::includeHTML(\"htmlChunkRelatedPartOfWhole.html\")", "```")),
           file.path(post_dir, "post.Rmd"), useBytes = TRUE)
r <- tryCatch(run_script(gallery_script("post.Rmd", root = post_dir), file.path(post_dir, "run"), seed = 1),
              error = function(e) list(candidates = data.frame(engine = character()),
                                       error = list(stage = "check", message = conditionMessage(e))))
cat("== gallery post:", nrow(r$candidates), "figures;", if (is.null(r$error)) "clean run" else
  paste("stopped:", r$error$stage, r$error$message), "\n")
if (!identical(r$candidates$engine, "base") || !is.null(r$error)) {
  cat("!! expected one base figure and a clean run\n"); ok <- FALSE
}

# Part 1b: freeze each synthetic figure the way harvest.R does, then rerun the
# frozen copy offline (no third-party code).
source("bench/R/harvest.R")
figures_root <- file.path(tempdir(), "check-runner", "figures")
r <- run_script(synthetic, file.path(tempdir(), "check-runner", "freeze"), seed = 1)
for (k in seq_len(nrow(r$candidates))) {
  id <- sprintf("synthetic-%03d", k)
  meta <- list(id = id, stratum = "synthetic", kind = "synthetic", psu = "check-runner.R", rewrites = list())
  dir <- freeze_figure(id, synthetic, r$candidates[k, ], tempdir(), meta)
  e <- check_eligibility(dir, r$candidates$engine[k])
  cat(sprintf("  frozen %s (%s): eligible %s\n", id, r$candidates$engine[k], e$ok))
  if (!e$ok) ok <- FALSE
}

# Part 1c: outcome classes, package names read from errors, install reasons
# and URL rewrites (pure functions; no code runs). The messages are the ones
# the first full harvest recorded.
check_pure <- function() {
  good <- TRUE
  none <- data.frame(chunk = integer(), expr = integer(), kind = character(), class = character(),
                     engine = character())
  run_of <- function(message, out_classes = character())
    list(candidates = none, out_classes = out_classes,
         error = list(chunk = 1L, expr = 1L, stage = "eval", message = message))
  cases <- list(
    list(run_of("cannot open the connection", "collapsibleTree htmlwidget"), "outside population"),
    list(run_of("cannot open URL 'data/tissue_lowres_5a.jpeg'"), "missing data"),
    list(run_of("cannot open URL 'https://example.org/x.csv'"), "needs network"),
    list(run_of("Required packages are missing: randomForest"), "missing package"),
    list(run_of("Cannot open \"data/x.shp\"; The source could be corrupt or not supported."), "missing data"))
  for (k in seq_along(cases)) {
    got <- psu_outcome(cases[[k]][[1]], failed = character())$outcome
    if (!identical(got, cases[[k]][[2]])) {
      cat("!! outcome case", k, ": got", got, ", expected", cases[[k]][[2]], "\n"); good <- FALSE
    }
  }
  pk <- list(list("Required packages are missing: randomForest, e1071", c("randomForest", "e1071")),
             list("there is no package called ‘waffle’", "waffle"),
             list("The package \"ggrepel\" is required.", "ggrepel"),
             list("object 'x' not found", character()))
  for (p in pk) if (!identical(packages_in_error(p[[1]]), p[[2]])) {
    cat("!! packages_in_error(", p[[1]], ") gave", packages_in_error(p[[1]]), "\n"); good <- FALSE
  }
  notes <- c("package ‘ggpol’ is not available for this version of R\n\nA version of this package ...",
             "download of package ‘ggerror’ failed")
  if (!identical(install_reason("ggpol", notes), "package ‘ggpol’ is not available for this version of R") ||
      !identical(install_reason("ggerror", notes), "download of package ‘ggerror’ failed")) {
    cat("!! install_reason\n"); good <- FALSE
  }
  # a URL that download.file() fetches stays a URL (file://); elsewhere it becomes a path
  rw <- rewrite_literal(list(c('download.file("https://x.org/a.jpeg", destfile = "a.jpeg")',
                               'img <- jpeg::readJPEG("https://x.org/a.jpeg")')),
                        '"https://x.org/a.jpeg"', "data/a.jpeg")[[1]]
  if (!identical(rw, c('download.file("file://data/a.jpeg", destfile = "a.jpeg")',
                       'img <- jpeg::readJPEG("data/a.jpeg")'))) {
    cat("!! rewrite_literal gave:", rw, sep = "\n"); good <- FALSE
  }
  good
}
pure_ok <- tryCatch(check_pure(), error = function(e) { cat("!! pure checks:", conditionMessage(e), "\n"); FALSE })
cat("\n== outcome classes, package names, install reasons, URL rewrites:", if (pure_ok) "OK" else "FAILED", "\n")
if (!pure_ok) ok <- FALSE

if (identical(Sys.getenv("GLOSS_BENCH_THIRD_PARTY"), "true")) {
  smp <- read_csv(file.path(bench_root, "sample.csv"))
  # Expected figures, counted from the sources: 13-scatter-plot has four
  # plot() calls (chunks 2-5); 164-area-chart-ggplot2 two ggplots (chunks 2
  # and 4; chunk 6 includes HTML); densityHeatmap's examples four visible
  # heatmaps (three densityHeatmap() calls and one %v% list).
  # (ComplexHeatmap::Heatmap was used here first: its examples are only
  # "# There is no example" and NULL, so it tested nothing.)
  stopifnot(!c("13-scatter-plot.Rmd", "164-area-chart-ggplot2.Rmd", "ComplexHeatmap::densityHeatmap") %in% smp$psu)
  third <- list(
    list("gallery-base", gallery_script("13-scatter-plot.Rmd"), rep("base", 4)),
    list("gallery-ggplot", gallery_script("164-area-chart-ggplot2.Rmd"), rep("ggplot", 2)),
    list("heatmap-topic", topic_script("ComplexHeatmap", "densityHeatmap"), rep("heatmap", 4))
  )
  for (t in third) {
    inst <- ensure_packages(code_packages(unlist(t[[2]]$chunks)))
    if (any(inst$status == "failed")) cat("!! packages failed:", inst$package[inst$status == "failed"], "\n")
    r <- run_script(t[[2]], file.path(tempdir(), "check-runner", t[[1]]), seed = 1, timeout = 300)
    cat("\n==", t[[1]], ":", nrow(r$candidates), "figures,", r$n_expr, "expressions,",
        if (!is.null(r$error)) paste("stopped:", r$error$stage, r$error$message), "\n")
    print(r$candidates)
    if (!identical(r$candidates$engine, t[[3]])) {
      cat("!! expected", paste(t[[3]], collapse = ", "), "\n"); ok <- FALSE
    }
  }
} else {
  cat("\n(part 2 skipped: set GLOSS_BENCH_THIRD_PARTY=true to run third-party code)\n")
}
cat(if (ok) "\nrunner check: OK\n" else "\nrunner check: FAILED\n")
