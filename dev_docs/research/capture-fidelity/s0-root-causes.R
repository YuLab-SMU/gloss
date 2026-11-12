# S0 (2026-11-10): root causes of the differences the bench found on the
# development set (run 2026-11-10-1424), reproduced on the host with code
# written for this check. No third-party figure code.
# Run from the repository root: Rscript dev_docs/research/capture-fidelity/s0-root-causes.R
suppressMessages(pkgload::load_all(".", quiet = TRUE, export_all = TRUE, helpers = FALSE))
source("dev_docs/research/capture-fidelity/page-capture.R")
library(ggplot2)
only <- function(a, b) {
  ta <- table(a); tb <- table(b); out <- character()
  for (k in names(ta)) { n <- ta[[k]] - (if (k %in% names(tb)) tb[[k]] else 0L); if (n > 0) out <- c(out, rep(k, n)) }
  out
}

cat("== A. ggExtra (gallery-052): the object against its own print, and against a page holding two figures ==\n")
if (requireNamespace("ggExtra", quietly = TRUE)) {
  p <- ggplot(mtcars, aes(wt, mpg, color = cyl, size = cyl)) + geom_point() + theme(legend.position = "none")
  p1 <- ggExtra::ggMarginal(p, type = "histogram"); p2 <- ggExtra::ggMarginal(p, type = "density")
  cat("  class:", paste(class(p2), collapse = " "), "\n  print.ggExtraPlot:", paste(deparse(body(getS3method("print", "ggExtraPlot"))), collapse = " "), "\n")
  eng <- gl_plugin("engine", "grid")          # the engine gloss chose before the refusal of efe9936
  st <- eng$prepare(p2, 7, 5)
  sub <- build_substrate(capture_scene(function() eng$grob(st), 7, 5), 7, 5, Inf)
  a <- scene_signatures(sub$scene)
  alone <- scene_signatures(plain_svg(function() print(p2), 7, 5))
  both <- scene_signatures(plain_svg(function() { print(p1); print(p2) }, 7, 5))
  cat(sprintf("  captured %d primitives | print(p2) alone %d: identical=%s | print(p1); print(p2) on one page %d: differ=%d\n",
              length(a), length(alone), identical(a, alone), length(both), diffn(a, both)))
  cat("  gloss(p2) today:", tryCatch({ gloss(p2, context = FALSE); "captured" }, error = function(e) substr(conditionMessage(e), 1, 60)), "\n")
}

cat("\n== B. base graphics through gridGraphics against the code drawing on svglite ==\n")
s <- svglite::svgstring(); bg_svg <- par("bg"); invisible(dev.off()); pdf(NULL); bg_pdf <- par("bg"); invisible(dev.off())
cat(sprintf("  par(\"bg\") on svglite: %s | on pdf(NULL), gridGraphics' shadow device: %s\n", bg_svg, bg_pdf))
cmp <- function(label, f, show = 0) {
  fig <- suppressWarnings(gloss(f, width = 7, height = 5, dense = Inf, context = FALSE))
  a <- scene_signatures(fig$substrate$scene); b <- scene_signatures(plain_svg(f, 7, 5))
  cat(sprintf("  %-34s gloss() %4d, native %4d, identical=%-5s differ=%d\n", label, length(a), length(b), identical(a, b), diffn(a, b)))
  if (show) {
    oa <- only(a, b); ob <- only(b, a)
    if (length(oa)) cat(paste0("      gloss() only: ", substr(utils::head(oa, show), 1, 118)), sep = "\n")
    if (length(ob)) cat(paste0("      native only : ", substr(utils::head(ob, show), 1, 118)), sep = "\n")
  }
}
cmp("plain scatter", function() plot(mtcars$wt, mtcars$mpg, pch = 19))
cmp("rect(border = 0)", function() { plot.new(); rect(.2, .2, .8, .8, col = "white", border = 0) }, show = 1)
cmp("rect(border = FALSE)", function() { plot.new(); rect(.2, .2, .8, .8, col = "white", border = FALSE) })
cmp("rect(border = NA)", function() { plot.new(); rect(.2, .2, .8, .8, col = "white", border = NA) })
cmp("pairs (as gallery-008)", function() plot(mtcars[, c(1, 3:6)], pch = 20, cex = 1.5, col = "#69b3a2"), show = 2)
# the extra background rect: a plot recorded on svglite carries par(bg) = white
rec <- function(f) { s <- svglite::svgstring(width = 7, height = 5); dev.control("enable"); f(); rp <- recordPlot(); invisible(dev.off()); rp }
f <- function() plot(mtcars$wt, mtcars$mpg, pch = 19)
a <- scene_signatures(gloss(rec(f), width = 7, height = 5, context = FALSE)$substrate$scene); b <- scene_signatures(plain_svg(f, 7, 5))
cat(sprintf("  %-34s gloss() %4d, native %4d, differ=%d: %s\n", "scatter, recorded on svglite", length(a), length(b), diffn(a, b), substr(only(a, b)[1], 1, 70)))

cat("\n== C. gloss() on a function that does not draw one base page ==\n")
try_gloss <- function(label, f) {
  w <- character()
  r <- tryCatch(withCallingHandlers(gloss(f, context = FALSE), warning = function(c) { w <<- c(w, conditionMessage(c)); invokeRestart("muffleWarning") }),
                error = function(e) e)
  if (inherits(r, "error")) return(cat(sprintf("  %-30s error: %s\n", label, substr(conditionMessage(r), 1, 80))))
  s <- svglite::svgstring(width = 7, height = 5); f(); invisible(dev.off()); pages <- as.character(s())
  cat(sprintf("  %-30s captured (engine %s); the function draws %d page(s); warnings: %s\n", label, r$meta$engine, length(pages),
              if (length(w)) paste(unique(substr(w, 1, 50)), collapse = " / ") else "none"))
}
try_gloss("draws with grid", function() { grid::grid.newpage(); grid::grid.rect(width = .5, height = .5); grid::grid.text("hello") })
try_gloss("prints a ggplot", function() print(ggplot(mtcars, aes(wt, mpg)) + geom_point()))
try_gloss("base, then grid on top", function() { plot(1:10); grid::grid.text("grid on base", .5, .9) })
try_gloss("4 base pages (plot.lm)", function() plot(lm(mpg ~ wt, mtcars)))
