# P3 (2026-11-11): page-capture plan, Task 3 (assumption 2, second half, and
# assumption 3). Package code on the page route against the tag
# engine-route-final (same R/ as aef42f2), each in its own R process.
#
#   A. points_1e4 (the test fixture) with the default dense = 10000: the dense
#      leaf's raster, pixel for pixel, and its element index.
#   B. the 10^5-point figure of the slow bundle test: bundle size (HTML).
#   C. time of gloss() at 10^3, 10^4, 10^5 points (dense = Inf, context =
#      FALSE, as in s4), five runs after one warm-up, median and range; on the
#      page route also the self-check alone (reading the page drawn, two page
#      signatures and their comparison), five runs.
#
# Host. Run from the repository root, with the tag checked out in a worktree:
#   git worktree add /tmp/gloss-engine-route engine-route-final
#   Rscript dev_docs/research/capture-fidelity/p3-time.R /tmp/gloss-engine-route
args <- commandArgs(trailingOnly = TRUE)
old_root <- if (length(args)) args[1] else "/tmp/gloss-engine-route"

run_in <- function(root, page_route) {
  out <- tempfile(fileext = ".rds")
  code <- sprintf('
    suppressMessages(pkgload::load_all("%s", quiet = TRUE, export_all = TRUE, helpers = FALSE))
    source(file.path("%s", "tests/testthat/helper-figures.R"))
    res <- list()
    pb <- six_inputs()$points_1e4$x
    fig <- gloss(pb, width = 7, height = 5, context = FALSE)
    id <- fig$substrate$leaves$id[fig$substrate$leaves$dense]
    res$raster <- fig$substrate$rasters[[id]]
    res$dense_elements <- fig$substrate$elements[fig$substrate$elements$leaf %%in%% id, ]
    set.seed(5)
    big <- data.frame(x = rnorm(1e5), y = rnorm(1e5))
    p5 <- ggplot2::ggplot(big, ggplot2::aes(x, y)) + ggplot2::geom_point(size = 0.3)
    f <- tempfile(fileext = ".html")
    gl_write(gloss(p5, width = 7, height = 5, context = FALSE), f)
    res$bundle_bytes <- file.size(f)
    tm <- function(expr) { t0 <- proc.time()[[3]]; force(expr); proc.time()[[3]] - t0 }
    res$time <- list()
    for (n in c(1e3, 1e4, 1e5)) {
      set.seed(1)
      d <- data.frame(x = rnorm(n), y = rnorm(n))
      p <- ggplot2::ggplot(d, ggplot2::aes(x, y)) + ggplot2::geom_point(size = 0.3)
      invisible(gloss(p, dense = Inf, context = FALSE))
      total <- vapply(1:5, function(i) tm(gloss(p, dense = Inf, context = FALSE)), 1)
      check <- rep(NA_real_, 5)
      if (%s) {
        cap <- capture_page(p, list(gl_plugin("engine", "ggplot")), 7, 5)
        doc <- inline_groups(cap)
        check <- vapply(1:5, function(i) tm({
          a <- page_signature(xml2::read_xml(cap$drawn))
          b <- page_signature(doc)
          identical(a, b)
        }), 1)
      }
      res$time[[as.character(n)]] <- list(total = total, check = check)
    }
    saveRDS(res, "%s")', root, root, if (page_route) "TRUE" else "FALSE", out)
  f <- tempfile(fileext = ".R")
  writeLines(code, f)
  if (system2(file.path(R.home("bin"), "Rscript"), f) != 0) stop("run failed in ", root)
  readRDS(out)
}

old <- run_in(old_root, FALSE)
new <- run_in(normalizePath("."), TRUE)

cat("== A. points_1e4, dense leaf ==\n")
pix <- function(r) png::readPNG(r)
same_bytes <- identical(old$raster, new$raster)
po <- pix(old$raster)
pn <- pix(new$raster)
cat(sprintf("  raster: %d x %d px, bytes identical=%s, pixels identical=%s, pixels differing=%d\n",
            dim(pn)[2], dim(pn)[1], same_bytes, identical(po, pn), sum(po != pn)))
cols <- setdiff(names(new$dense_elements), "leaf")
cat(sprintf("  index: %d / %d elements, identical apart from the leaf id=%s\n",
            nrow(old$dense_elements), nrow(new$dense_elements),
            identical(old$dense_elements[cols], new$dense_elements[cols])))

cat("\n== B. 10^5 points, HTML bundle ==\n")
cat(sprintf("  engine route %.2f MB, page route %.2f MB (limit 3 MB)\n",
            old$bundle_bytes / 1024^2, new$bundle_bytes / 1024^2))

cat("\n== C. time of gloss(), 5 runs: median [min, max] s ==\n")
fmt <- function(v) sprintf("%.2f [%.2f, %.2f]", stats::median(v), min(v), max(v))
for (n in names(new$time)) {
  o <- old$time[[n]]$total
  t <- new$time[[n]]$total
  k <- new$time[[n]]$check
  cat(sprintf("  %6s points: engine route %s | page route %s, of which self-check %s | ratio of medians %.2f\n",
              format(as.numeric(n), scientific = FALSE, big.mark = ","), fmt(o), fmt(t), fmt(k),
              stats::median(t) / stats::median(o)))
}
