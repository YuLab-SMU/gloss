# P5 (2026-11-11): page-capture plan, Task 5 (assumption 5: a display-list
# entry is a usable leaf). The 26 hand-built base pages of s2, captured by the
# package on the base route, against the same pages captured at the tag
# engine-route-final (gridGraphics), each route in its own R process.
#
# Per case: is the page the code's own page on svglite (with clip regions)?
# gloss's verdict; elements, leaves, leaves with an expected count and how
# many of those are ok; panels; time. For the cases with points drawn by
# plot() or points(): built from the call's x and y through each panel's
# scales, the largest gap to the drawn circles.
#
# Host. Run from the repository root, with the tag checked out in a worktree:
#   git worktree add /tmp/gloss-engine-route engine-route-final
#   Rscript dev_docs/research/capture-fidelity/p5-base-fixtures.R /tmp/gloss-engine-route
args <- commandArgs(trailingOnly = TRUE)
old_root <- if (length(args)) args[1] else "/tmp/gloss-engine-route"

run_in <- function(root) {
  out <- tempfile(fileext = ".rds")
  code <- sprintf('
    suppressMessages(pkgload::load_all("%s", quiet = TRUE, export_all = TRUE, helpers = FALSE))
    source(file.path("%s", "tests/testthat/helper-figures.R"))
    source("dev_docs/research/capture-fidelity/page-capture.R")
    # only the fixtures: s2 starts with load_all("."), which would load this
    # checkout over the tag (the first two runs of this script did that, so
    # their engine-route column measured the page route)
    for (e in parse("dev_docs/research/capture-fidelity/s2-page-base.R", keep.source = FALSE)) {
      if (is.call(e) && identical(e[[1]], as.name("<-")) && identical(e[[2]], as.name("cases"))) eval(e)
    }
    res <- list()
    for (nm in names(cases)) {
      f <- cases[[nm]]
      native <- suppressWarnings(plain_svg(f, 7, 5))
      t0 <- proc.time()[[3]]
      fig <- tryCatch(suppressWarnings(gloss(f, width = 7, height = 5, dense = Inf, context = FALSE)), error = function(e) e)
      secs <- proc.time()[[3]] - t0
      if (inherits(fig, "error")) { res[[nm]] <- list(error = conditionMessage(fig)); next }
      s <- fig$substrate
      res[[nm]] <- list(
        equal = identical(scene_signatures(s$scene), scene_signatures(native)) &&
          identical(clip_regions(s$scene), clip_regions(native)),
        differ = diffn(scene_signatures(s$scene), scene_signatures(native)),
        verdict = fig$meta$page$verdict %%||%% NA, elements = nrow(s$elements), leaves = nrow(s$leaves),
        known = sum(!is.na(s$leaves$n_expected)), ok = sum(s$leaves$status == "ok"),
        mismatch = sum(s$leaves$status == "count_mismatch"),
        panels = nrow(s$panels), seconds = secs, names = table(s$leaves$name), substrate = s)
    }
    saveRDS(res, "%s")', root, root, out)
  f <- tempfile(fileext = ".R")
  writeLines(code, f)
  if (system2(file.path(R.home("bin"), "Rscript"), f) != 0) stop("run failed in ", root)
  readRDS(out)
}

old <- run_in(old_root)
new <- run_in(normalizePath("."))

cat("== 26 base pages: the code's own page on svglite, gridGraphics (engine route) against replay by entry (page route) ==\n")
cat(sprintf("%-22s | %-30s | %-62s\n", "case", "engine route: equal (differ)", "page route: equal (differ), verdict, elements, leaves, counted/ok/mismatch, panels, s"))
for (nm in names(new)) {
  o <- old[[nm]]
  n <- new[[nm]]
  ot <- if (!is.null(o$error)) paste("error:", substr(o$error, 1, 22)) else sprintf("%-5s (%d)", o$equal, o$differ)
  nt <- if (!is.null(n$error)) paste("error:", substr(n$error, 1, 50)) else
    sprintf("%-5s (%d), %s, %d el, %d leaves, %d/%d/%d, %d panels, %.2f s", n$equal, n$differ, n$verdict,
            n$elements, n$leaves, n$known, n$ok, n$mismatch, n$panels, n$seconds)
  cat(sprintf("%-22s | %-30s | %s\n", nm, ot, nt))
}
ok_old <- sum(vapply(old, function(o) isTRUE(o$equal), TRUE))
ok_new <- sum(vapply(new, function(o) isTRUE(o$equal), TRUE))
cat(sprintf("\nequal to the code's page: engine route %d of %d, page route %d of %d\n", ok_old, length(old), ok_new, length(new)))

cat("\n== leaf names on the page route, over the 26 pages ==\n")
nms <- Reduce(function(a, b) { k <- union(names(a), names(b)); x <- setNames(integer(length(k)), k); x[names(a)] <- x[names(a)] + a; x[names(b)] <- x[names(b)] + b; x },
              lapply(new, function(n) if (is.null(n$names)) integer() else unclass(n$names)))
print(sort(nms, decreasing = TRUE))

cat("\n== data through each panel's scales onto the drawn circles (page route) ==\n")
place <- function(nm, panel, x, y, logx = FALSE, logy = FALSE) {
  s <- new[[nm]]$substrate
  fig <- structure(list(substrate = s, meta = list()), class = "gloss_figure")
  suppressMessages(pkgload::load_all(".", quiet = TRUE, export_all = TRUE, helpers = FALSE))
  lv <- s$leaves[s$leaves$class == "plotXY" & s$leaves$panel %in% panel, ]
  el <- s$elements[s$elements$leaf %in% lv$id[1] & s$elements$tag == "circle", ]
  px <- gl_to_pixel(fig, panel, if (logx) log10(x) else x, if (logy) log10(y) else y)
  cx <- (el$x0 + el$x1) / 2
  cy <- (el$y0 + el$y1) / 2
  cat(sprintf("  %-22s %s: %d circles for %d rows; largest gap %.3f pt (x), %.3f pt (y)\n", nm, panel, nrow(el), length(x),
              max(abs(px$x - cx)), max(abs(px$y - cy))))
}
place("scatter_abline_legend", "panel1", mtcars$wt, mtcars$mpg)
place("log_axes", "panel1", 1:100, (1:100)^2, logx = TRUE, logy = TRUE)
# pairs() fills by column (par(mfcol), j outer, i inner): the second figure is
# row 2, column 1, x = mpg, y = disp. The first run had the columns swapped
# and reported a gap of 1383.889 pt (disp on the mpg scale).
place("pairs", "panel2", mtcars$mpg, mtcars$disp)
place("layout_widths", "panel1", 1:5, 1:5)
