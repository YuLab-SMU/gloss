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
    r2 <- run_script(frozen, dir, seed = 1, timeout = 300, offline = TRUE, recover = TRUE, capture = TRUE,
                     device = "svg")
    cat(sprintf("  figure %d: recovered %s/%s, capture %s, %s elements, %s leaves, unowned %s (background %s), faithful %s (%s of %s primitives differ)%s\n", k,
                r2$recovered$kind, r2$recovered$engine, r2$capture$status, r2$capture$elements %||% NA,
                r2$capture$leaves %||% NA, r2$capture$unowned %||% NA, r2$capture$unowned_bg %||% NA,
                r2$capture$faithful %||% NA, r2$capture$prims_differ %||% NA, r2$capture$prims_ref %||% NA,
                if (is.null(r2$capture$message)) "" else paste(":", r2$capture$message)))
    cat(sprintf("    reference: untouched by recovery %s, open page = closed page %s\n",
                r2$reference$untouched %||% NA, r2$reference$same_as_closed %||% NA))
    # the fidelity check answers for every figure; where recovery drew nothing
    # the repaired open page equals the closed one; every scene, base pages
    # included, equals what the code drew (base pages are replayed by entry
    # since page-capture plan Task 5; gridGraphics added a background rect).
    fa <- r2$capture$faithful %||% NA
    if (is.na(fa) || isFALSE(r2$reference$same_as_closed) || !isTRUE(fa)) {
      cat("!! fidelity check: faithful", fa, ", open page = closed page", r2$reference$same_as_closed %||% NA, "\n"); ok <- FALSE
    }
    if (!identical(r2$recovered$engine, c1$engine) || !identical(r2$capture$status, "captured")) ok <- FALSE
    # a page the code drew is handed over as the recorded page, never a grid.grab() tree (page-capture plan Task 4)
    if (!identical(r2$recovered$kind, "object") && !identical(r2$recovered$class, "recordedplot")) {
      cat("!! a drawn page was recovered as", r2$recovered$class, "not a recordedplot\n"); ok <- FALSE
    }
    # the background test must give an answer: 0 or 1, never NA; a ggplot draws one
    bg <- r2$capture$unowned_bg %||% NA
    if (is.na(bg) || !bg %in% 0:1 || (identical(c1$engine, "ggplot") && bg != 1L)) {
      cat("!! background test gave", bg, "\n"); ok <- FALSE
    }
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
    # 8: a lattice plot: a visible trellis value draws only when auto-printed,
    # after a static image that is not installed (no figure, no stop)
    c("knitr::include_graphics('figures/not-installed.png')", "lattice::xyplot(y ~ x, d)"),
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
  clean <- function(out_classes = character(), engines = character())
    list(candidates = data.frame(chunk = seq_along(engines), expr = rep(1L, length(engines)), kind = engines, class = engines,
                                 engine = engines),
         out_classes = out_classes, error = NULL)
  cases <- list(
    # a widget and nothing else: outside the population
    list(clean("collapsibleTree htmlwidget"), "outside population"),
    # a table, then a failure before the figures (SPONGE): the error decides
    list(run_of("object 'trained.model' not found", "knitr_kable"), "code error"),
    # a table and a widget, plus a heatmap drawn by a wrapper as a grid scene
    # (ClustAll, heatmap stratum): figures of another engine, not outside
    list(clean(c("knitr_kable", "sankeyNetwork htmlwidget"), "grid"), "no figure"),
    list(run_of("cannot open the connection", "collapsibleTree htmlwidget"), "missing data"),
    list(run_of("cannot open URL 'data/tissue_lowres_5a.jpeg'"), "missing data"),
    list(run_of("cannot open URL 'https://example.org/x.csv'"), "needs network"),
    list(run_of("Required packages are missing: randomForest"), "missing package"),
    list(run_of("Cannot open \"data/x.shp\"; The source could be corrupt or not supported."), "missing data"),
    list(run_of("HTTP 405 Method Not Allowed."), "needs network"))
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
  # package environments: strata map to their era; neither environment's path
  # holds the other's library, even when the session has it on its path
  if (!identical(env_for_stratum("heatmap")$name, "bioc") || !identical(env_for_stratum("bioc")$name, "bioc") ||
      !identical(env_for_stratum("gallery")$name, "cran") || !identical(env_for_stratum("patchwork")$name, "cran")) {
    cat("!! env_for_stratum\n"); good <- FALSE
  }
  old_paths <- .libPaths()
  .libPaths(c(bench_envs$cran$lib, bench_envs$bioc$lib, old_paths))
  lp_b <- bench_libpaths(bench_envs$bioc); lp_c <- bench_libpaths(bench_envs$cran)
  .libPaths(old_paths)
  norm <- function(x) normalizePath(x, mustWork = FALSE)
  if (!identical(norm(lp_b[1]), norm(bench_envs$bioc$lib)) || norm(bench_envs$cran$lib) %in% norm(lp_b) ||
      !identical(norm(lp_c[1]), norm(bench_envs$cran$lib)) || norm(bench_envs$bioc$lib) %in% norm(lp_c)) {
    cat("!! bench_libpaths mixes environments:\n", lp_b, "\n", lp_c, "\n"); good <- FALSE
  }
  if (!identical(figure_env(list(stratum = "heatmap"))$name, "bioc") ||
      !identical(figure_env(list(stratum = "gallery"))$name, "cran") ||
      !identical(figure_env(list(stratum = "synthetic", environment = list(name = "bioc")))$name, "bioc")) {
    cat("!! figure_env\n"); good <- FALSE
  }
  good
}
pure_ok <- tryCatch(check_pure(), error = function(e) { cat("!! pure checks:", conditionMessage(e), "\n"); FALSE })
cat("\n== outcome classes, package names, install reasons, URL rewrites:", if (pure_ok) "OK" else "FAILED", "\n")
if (!pure_ok) ok <- FALSE

# Part 1d: a package that fails to build leaves its build error in the install
# log, installed alone (R's serial path) and beside another package (the
# parallel make path). R CMD INSTALL writes through system2(), outside R's
# sink(), so the bioc-environment harvest's log held no build output at all
# (2026-11-10). A local repository and a throwaway library and environment:
# nothing reaches the bench libraries. BiocManager still checks its version online.
check_install_log <- function() {
  root <- file.path(tempdir(), "check-install-log")
  unlink(root, recursive = TRUE)
  contrib <- file.path(root, "repo", "src", "contrib")
  dir.create(contrib, recursive = TRUE)
  marker <- "GLOSS-BUILD-MARKER broken on purpose"
  old_wd <- setwd(contrib)  # R CMD build writes the tarball here
  on.exit(setwd(old_wd), add = TRUE)
  for (p in c("glossgood", "glossbroken")) {
    d <- file.path(root, "pkgs", p)
    dir.create(file.path(d, "R"), recursive = TRUE)
    writeLines(c(paste("Package:", p), "Version: 0.0.1", "Title: Check Package", "Description: Check package.",
                 "License: MIT", "Author: check", "Maintainer: check <check@example.org>"), file.path(d, "DESCRIPTION"))
    writeLines("", file.path(d, "NAMESPACE"))
    writeLines(if (p == "glossbroken") sprintf('stop("%s")', marker) else "f <- function() 1", file.path(d, "R", "f.R"))
    system2(file.path(R.home("bin"), "R"), c("CMD", "build", "--no-build-vignettes", shQuote(d)),
            stdout = FALSE, stderr = FALSE)
  }
  setwd(old_wd)
  stopifnot(length(Sys.glob(file.path(contrib, "gloss*_0.0.1.tar.gz"))) == 2L)
  tools::write_PACKAGES(contrib, type = "source")
  env <- list(name = "check", cran = paste0("file://", file.path(root, "repo")), lib = file.path(root, "lib"))
  dir.create(env$lib)
  good <- TRUE
  for (pk in list("glossbroken", c("glossgood", "glossbroken"))) {
    log <- file.path(root, paste0("install-", length(pk), ".log"))
    st <- ensure_packages(pk, log = log, tries = 1L, env = env)
    want <- ifelse(st$package == "glossbroken", "failed", "installed")
    has <- file.exists(log) && any(grepl(marker, readLines(log), fixed = TRUE))
    cat(sprintf("  %s: %s; build error in the log: %s\n", paste(pk, collapse = " + "),
                paste(st$package, st$status, collapse = ", "), has))
    if (!identical(st$status, want) || !has) good <- FALSE
  }
  good
}
inst_ok <- tryCatch(check_install_log(), error = function(e) { cat("!! install log check:", conditionMessage(e), "\n"); FALSE })
cat("\n== install log keeps build output:", if (inst_ok) "OK" else "FAILED", "\n")
if (!inst_ok) ok <- FALSE

# Part 1e: capture in the bioc environment. The synthetic figures above run in
# cran; the bioc and heatmap strata capture with gloss loaded against the bioc
# library, which nothing else checks before the capture run (plan Task 6).
use_env(bench_envs$bioc)
hm <- list(setup = character(), chunks = list(c("m <- matrix(seq_len(20) / 3, 4)", "ComplexHeatmap::Heatmap(m)")))
r_bioc <- run_script(hm, file.path(tempdir(), "check-runner", "bioc-capture"), seed = 1, timeout = 300,
                     offline = TRUE, recover = TRUE, capture = TRUE)
use_env(bench_envs$cran)
bioc_ok <- is.null(r_bioc$error) && identical(r_bioc$recovered$engine, "heatmap") &&
  identical(r_bioc$capture$status, "captured") && !is.na(r_bioc$capture$unowned_bg %||% NA)
cat(sprintf("\n== capture in env bioc: recovered %s, capture %s, %s leaves, unowned %s (background %s)%s: %s\n",
            r_bioc$recovered$engine %||% NA, r_bioc$capture$status %||% NA, r_bioc$capture$leaves %||% NA,
            r_bioc$capture$unowned %||% NA, r_bioc$capture$unowned_bg %||% NA,
            if (!is.null(r_bioc$error)) paste(":", r_bioc$error$stage, r_bioc$error$message)
            else if (!is.null(r_bioc$capture$message)) paste(":", r_bioc$capture$message) else "",
            if (bioc_ok) "OK" else "FAILED"))
if (!bioc_ok) ok <- FALSE

# Part 1f: fidelity verdicts. A strict difference is classified from the diff
# itself. Since page-capture plan Task 6 there is no known exception: the one
# extra background rect that gridGraphics added to recorded base pages is a
# difference like any other, and so are its mutations.
check_fidelity <- function() {
  good <- TRUE
  base_cap <- list(faithful = FALSE, dense_leaves = 0L, prims_differ = 1L,
                   diff_scene_n = 1L, diff_ref_n = 0L, prims_scene = 39L, prims_ref = 38L,
                   diff_scene = "rect x=0 y=0 width=1 height=1 ")
  cases <- list(
    list(name = "equal", cap = list(faithful = TRUE), want = "equal"),
    # a figure the bench drew twice with two different pages: its own proof
    list(name = "not deterministic", cap = list(faithful = FALSE, deterministic = FALSE, prims_differ = 5L),
         want = "not_deterministic"),
    list(name = "deterministic, different", cap = list(faithful = FALSE, deterministic = TRUE, prims_differ = 5L),
         want = "different"),
    list(name = "one background rect", cap = base_cap, want = "different"),
    list(name = "two extra primitives", cap = modifyList(base_cap, list(prims_differ = 2L, diff_scene_n = 2L,
                                                                        prims_scene = 40L)), want = "different"),
    list(name = "extra rect and one missing", cap = modifyList(base_cap, list(prims_differ = 2L, diff_ref_n = 1L,
                                                                             prims_ref = 39L)), want = "different"))
  for (cs in cases) {
    got <- tryCatch(fidelity_verdict(cs$cap)$verdict, error = function(e) paste("ERROR", conditionMessage(e)))
    cat(sprintf("  %-26s -> %s\n", cs$name, got))
    if (!identical(got, cs$want)) good <- FALSE
  }
  # The comparator sees clipping: the same primitives without their clip
  # region are a different page (s7-clip-blind-spot: signatures alone could not).
  # svglite and xml2 come from the bench library, as in the workers.
  old_paths <- .libPaths()
  .libPaths(c(bench_libpaths(), old_paths))
  on.exit(.libPaths(old_paths), add = TRUE)
  clip_ref <- local({
    s <- svglite::svgstring(width = 3, height = 3, standalone = TRUE)
    d <- grDevices::dev.cur()
    grid::grid.draw(grid::gTree(children = grid::gList(grid::clipGrob(width = 0.4, height = 0.4),
                                                       grid::circleGrob(r = 0.45))))
    grDevices::dev.off(d)
    pg <- as.character(s())
    pg[length(pg)]
  })
  doc <- xml2::read_xml(clip_ref)
  for (g in xml2::xml_find_all(doc, "//d1:g[@clip-path]", c(d1 = "http://www.w3.org/2000/svg"))) {
    xml2::xml_set_attr(g, "clip-path", NULL)
  }
  unclipped <- as.character(doc)
  cmp_same <- tryCatch(compare_pages(clip_ref, clip_ref), error = function(e) list(faithful = NA))
  cmp_lost <- tryCatch(compare_pages(unclipped, clip_ref), error = function(e) list(faithful = NA))
  cat(sprintf("  %-26s -> faithful %s (same page: %s)\n", "clip lost, prims unchanged", cmp_lost$faithful, cmp_same$faithful))
  if (!isTRUE(cmp_same$faithful) || !isFALSE(cmp_lost$faithful)) good <- FALSE
  # End to end: the three verdicts on real figures, and mismatch leaf ids.
  figs <- list(
    list(name = "ggplot", want = "equal",
         code = c("library(ggplot2)", "d <- data.frame(x=1:20,y=1:20,g=rep(c('a','b'),10))",
                  "ggplot(d, aes(x,y)) + geom_point() + facet_wrap(~g)")),
    list(name = "base", want = "equal", code = c("plot(1:10, (1:10)^2)")),
    # a dense leaf is a raster in the capture; fidelity is judged on the
    # vector page (a second capture with dense = Inf), so it is equal
    list(name = "dense", want = "equal",
         code = c("library(ggplot2)", "set.seed(1); d <- data.frame(x=rnorm(12000),y=rnorm(12000))",
                  "ggplot(d, aes(x,y)) + geom_point(size=0.2)")),
    # every drawing differs: the bench's two plain drawings prove it, and
    # gloss's own self-check says the same
    list(name = "random", want = "not_deterministic",
         code = c("registerS3method('makeContent', 'bench_rnd', function(x) grid::setChildren(x, grid::gList(grid::pointsGrob(stats::runif(5), stats::runif(5), pch = 19))), envir = asNamespace('grid'))",
                  "grid::grid.newpage()", "grid::grid.draw(grid::gTree(cl = 'bench_rnd', name = 'rnd'))")),
    # two figures on one page: the object's reference is the page it draws
    # alone; the page the code left is reported beside it, and differs
    list(name = "two on a page", want = "equal",
         code = c("library(ggplot2)", "p <- ggplot(data.frame(x = 1:5, y = 1:5), aes(x, y)) + geom_point()",
                  "print(p)", "print(p + theme_bw(), vp = grid::viewport(width = 0.5, height = 0.5))")))
  for (f in figs) {
    r <- run_script(list(setup = character(), chunks = list(f$code)),
                    file.path(tempdir(), "check-runner", "fidelity", f$name),
                    seed = 1, timeout = 300, offline = TRUE, recover = TRUE, capture = TRUE, device = "svg")
    cap <- r$capture %||% list()
    cat(sprintf("  %-8s verdict %-16s (%s)\n", f$name, cap$verdict %||% NA, cap$exception %||% NA))
    if (!identical(cap$status, "captured") || !identical(cap$verdict, f$want)) good <- FALSE
    if (identical(f$name, "dense") && !isTRUE(cap$dense_leaves >= 1)) good <- FALSE
    if (!identical(cap$gloss_verdict, f$want)) {
      cat("!! gloss's own verdict", cap$gloss_verdict %||% NA, "against the bench's", f$want, "\n"); good <- FALSE
    }
    if (identical(f$name, "two on a page") && !isFALSE(cap$code_faithful)) {
      cat("!! the page the code left should differ from the object alone\n"); good <- FALSE
    }
    # leaf names per figure (page-capture plan Task 6: base names for design
    # §分类): a base page's points are its plotXY entry
    if (identical(f$name, "base") && !grepl("(^| )plotXY:", cap$leaf_names %||% "")) {
      cat("!! leaf names not recorded:", cap$leaf_names %||% NA, "\n"); good <- FALSE
    }
    # prediction 7 measured count mismatches; the run must now name the leaves
    if (identical(f$name, "ggplot") && !nzchar(cap$mismatch_leaves %||% "")) good <- FALSE
  }
  good
}
fid_ok <- tryCatch(check_fidelity(), error = function(e) { cat("!! fidelity checks:", conditionMessage(e), "\n"); FALSE })
cat("\n== fidelity verdicts and mismatch leaves:", if (fid_ok) "OK" else "FAILED", "\n")
if (!fid_ok) ok <- FALSE

if (identical(Sys.getenv("GLOSS_BENCH_THIRD_PARTY"), "true")) {
  smp <- read_csv(file.path(bench_root, "sample.csv"))
  # Expected figures, counted from the sources: 13-scatter-plot has four
  # plot() calls (chunks 2-5); 164-area-chart-ggplot2 two ggplots (chunks 2
  # and 4; chunk 6 includes HTML); densityHeatmap's examples four visible
  # heatmaps (three densityHeatmap() calls and one %v% list).
  # (ComplexHeatmap::Heatmap was used here first: its examples are only
  # "# There is no example" and NULL, so it tested nothing.)
  stopifnot(!c("13-scatter-plot.Rmd", "164-area-chart-ggplot2.Rmd", "ComplexHeatmap::densityHeatmap") %in% smp$psu)
  # each runs in its stratum's package environment (the heatmap topic: bioc)
  third <- list(
    list("gallery-base", function() gallery_script("13-scatter-plot.Rmd"), rep("base", 4), "cran"),
    list("gallery-ggplot", function() gallery_script("164-area-chart-ggplot2.Rmd"), rep("ggplot", 2), "cran"),
    list("heatmap-topic", function() topic_script("ComplexHeatmap", "densityHeatmap"), rep("heatmap", 4), "bioc")
  )
  # where a figure package loads from, in each environment: its own library, never the other's
  for (e in bench_envs) {
    use_env(e)
    for (p in c("ggplot2", "ComplexHeatmap")) {
      where <- tryCatch(callr::r(function(p) find.package(p), args = list(p = p), libpath = bench_libpaths(e)),
                        error = function(err) NA_character_)
      inside <- !is.na(where) && startsWith(normalizePath(where), normalizePath(e$lib))
      cat(sprintf("== env %s: %s from %s\n", e$name, p, where))
      if (!inside) { cat("!! expected under", e$lib, "\n"); ok <- FALSE }
    }
  }
  for (t in third) {
    use_env(bench_envs[[t[[4]]]])
    t[[2]] <- t[[2]]()
    inst <- ensure_packages(code_packages(unlist(t[[2]]$chunks)))
    if (any(inst$status == "failed")) cat("!! packages failed:", inst$package[inst$status == "failed"], "\n")
    r <- run_script(t[[2]], file.path(tempdir(), "check-runner", t[[1]]), seed = 1, timeout = 300)
    cat("\n==", t[[1]], paste0("[", t[[4]], "]"), ":", nrow(r$candidates), "figures,", r$n_expr, "expressions,",
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
