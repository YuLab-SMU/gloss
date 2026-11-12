# S4 (2026-11-10): what page capture does at its edges. Host, no third-party code.
# Run from the repository root: Rscript dev_docs/research/capture-fidelity/s4-unknowns.R
suppressMessages(pkgload::load_all(".", quiet = TRUE, export_all = TRUE, helpers = FALSE))
source("dev_docs/research/capture-fidelity/page-capture.R")
library(ggplot2)

open_svg <- function() {
  s <- svglite::svgstring(width = 7, height = 5, standalone = TRUE)
  grDevices::dev.control("enable")
  s
}
verdict <- function(sub, A) {
  a <- scene_signatures(sub$scene); b <- scene_signatures(A)
  sprintf("identical=%-5s differ=%d", identical(a, b), diffn(a, b))
}
msg <- function(e) substr(gsub("\\s+", " ", conditionMessage(e)), 1, 110)

cat("== A. random numbers: where must the RNG state be saved? ==\n")
# jitter draws at build time, ggrepel (no seed) at draw time
d <- transform(mtcars, name = rownames(mtcars))
pj <- ggplot(d, aes(factor(cyl), mpg, label = name)) + geom_jitter(width = .3) + ggrepel::geom_text_repel()
# (1) follow print(), RNG restored to its state before print()
s <- open_svg(); set.seed(11); rs <- .Random.seed
print(pj); A <- last_page(s)
assign(".Random.seed", rs, envir = globalenv())
cat("  print(p), state before print() restored   :", verdict(capture_grid_page(s), A), "\n")
# (2) the engine builds, then draws: the state before the draw is known
s <- open_svg(); set.seed(11)
built <- ggplot_build(pj); gt <- ggplot_gtable(built); rs <- .Random.seed
grid::grid.draw(gt); A <- last_page(s)
assign(".Random.seed", rs, envir = globalenv())
sub <- capture_grid_page(s)
cat("  build, then draw; state before draw restored:", verdict(sub, A), "\n")
# does that page equal what print(p) draws from the same seed?
P <- plain_svg(function() { set.seed(11); print(pj) }, 7, 5)
cat("  ... and equals print(p) from the same seed  :", verdict(sub, P), "\n")
# (3) nothing restored
s <- open_svg(); set.seed(11); print(pj); A <- last_page(s)
cat("  print(p), nothing restored                  :", verdict(capture_grid_page(s), A), "\n")

# (4) the state when the page starts, taken by a grid.newpage hook. print.ggplot
# starts its page BEFORE it builds, so this state precedes the build's draws.
hook_env <- new.env()
hook <- function() hook_env$seed <- get0(".Random.seed", envir = globalenv())
setHook("grid.newpage", hook, "append")
s <- open_svg(); set.seed(11); hook_env$seed <- NULL
print(pj); A <- last_page(s)
assign(".Random.seed", hook_env$seed, envir = globalenv())
cat("  print(p), state at page start (hook) restored:", verdict(capture_grid_page(s), A), "\n")
setHook("grid.newpage", Filter(function(h) !identical(h, hook), getHook("grid.newpage")), "replace")
# (5) what gloss can always do: redraw the page untouched (A1) and wrapped (B)
# from one saved state. B = A1 says wrapping changed nothing; A1 = A0 says the
# figure draws the same way twice.
s <- open_svg(); set.seed(11); print(pj); A0 <- last_page(s)
rs <- .Random.seed
grid::grid.refresh(); A1 <- last_page(s)
assign(".Random.seed", rs, envir = globalenv())
sub <- capture_grid_page(s)
cat("  self-check: wrapped B against plain redraw A1 :", verdict(sub, A1), "\n")
cat("  self-check: plain redraw A1 against the page A0:", verdict(list(scene = A1), A0), "\n")

cat("\n== B. a page recorded on another device, replayed on svglite ==\n")
p <- ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) + geom_point() + facet_wrap(~am) + labs(title = "A title")
for (dv in c("svglite", "pdf")) {
  if (dv == "svglite") s0 <- svglite::svgstring(width = 7, height = 5) else grDevices::pdf(NULL, width = 7, height = 5)
  grDevices::dev.control("enable"); print(p); rp <- grDevices::recordPlot(); invisible(grDevices::dev.off())
  r <- tryCatch({
    s <- open_svg(); grDevices::replayPlot(rp); A <- last_page(s)
    k <- page_kind()$kind
    sub <- capture_grid_page(s)
    P <- plain_svg(function() print(p), 7, 5)
    sprintf("page kind %s | wrapped = replayed: %s | replayed = print(p) on svglite: %s", k, verdict(sub, A),
            verdict(list(scene = A), P))
  }, error = function(e) paste("ERROR", msg(e)))
  cat(sprintf("  recorded on %-8s: %s\n", dv, r))
}

cat("\n== C. what the in-place route refuses or keeps (same checks as the grob route) ==\n")
cases <- list(
  gradient = grid::rectGrob(width = .8, height = .6, gp = grid::gpar(fill = grid::linearGradient(c("red", "blue")))),
  pattern = grid::rectGrob(gp = grid::gpar(fill = grid::pattern(
    grid::circleGrob(r = .1, gp = grid::gpar(fill = "black")), width = .2, height = .2, extend = "repeat"))),
  clip_path = grid::gTree(children = grid::gList(grid::rectGrob(gp = grid::gpar(fill = "grey")),
                                                 grid::pointsGrob(c(.2, .5, .8), c(.5, .5, .5), pch = 19)),
                          vp = grid::viewport(clip = grid::circleGrob(r = .3))),
  gtree_alpha = grid::gTree(children = grid::gList(grid::rectGrob(gp = grid::gpar(fill = "red")),
                                                   grid::circleGrob(r = .2, gp = grid::gpar(fill = "blue"))),
                            gp = grid::gpar(alpha = .5)),
  rotated_vp = grid::gTree(children = grid::gList(grid::rectGrob(name = "r")),
                           vp = grid::viewport(angle = 30, width = .5, height = .5)),
  mask = grid::gTree(children = grid::gList(grid::rectGrob(gp = grid::gpar(fill = "red"))),
                     vp = grid::viewport(mask = grid::circleGrob(r = .3, gp = grid::gpar(fill = "black")))),
  own_group = grid::gTree(children = grid::gList(grid::groupGrob(grid::rectGrob(gp = grid::gpar(fill = "red"))),
                                                 grid::circleGrob(r = .2))),
  # a clipping grob is a leaf: inside a group its clip ends with the group
  clip_grob = grid::gTree(children = grid::gList(grid::clipGrob(width = .4, height = .4),
                                                 grid::circleGrob(r = .45, gp = grid::gpar(fill = "blue"))))
)
for (nm in names(cases)) {
  g <- cases[[nm]]
  r <- tryCatch({
    s <- open_svg(); grid::grid.draw(g); A <- last_page(s)
    sub <- capture_grid_page(s)
    paste(verdict(sub, A), "| leaves", nrow(sub$leaves), "| mismatch", sum(sub$leaves$status == "count_mismatch"))
  }, error = function(e) paste("REFUSED:", msg(e)))
  old <- tryCatch({
    f <- gloss(g, width = 7, height = 5, context = FALSE)
    paste("captured,", verdict(f$substrate, plain_svg(function() grid::grid.draw(g), 7, 5)))
  }, error = function(e) paste("refused:", substr(msg(e), 1, 40)))
  cat(sprintf("  %-12s %s   [gloss() today: %s]\n", nm, r, old))
}
# pushed viewports left open, drawing in pieces, a grob edited after drawing
r <- tryCatch({
  s <- open_svg()
  grid::pushViewport(grid::viewport(width = .6, height = .6, name = "open"))
  grid::grid.rect(name = "box"); grid::grid.text("inside", name = "lbl")
  grid::grid.edit("box", gp = grid::gpar(fill = "orange"))       # redraws the page
  A <- last_page(s)
  sub <- capture_grid_page(s)
  paste(verdict(sub, A), "| leaves", nrow(sub$leaves), "| vp of box:", sub$leaves$vp[sub$leaves$name == "box"])
}, error = function(e) paste("ERROR", msg(e)))
cat("  viewport left open, grid.edit() after drawing:", r, "\n")

cat("\n== D. pages the code can leave behind ==\n")
kinds <- list(
  nothing = function() invisible(NULL),
  `base then grid on top` = function() { plot(1:10); grid::grid.text("grid on base", .5, .9) },
  `grid then base on top` = function() { grid::grid.newpage(); grid::grid.rect(width = .3, height = .3); par(new = TRUE); plot(1:10) },
  `4 base pages` = function() plot(lm(mpg ~ wt, mtcars)),
  `2 grid pages` = function() { print(p); print(p + theme_bw()) },
  `2 ggplots, no new page between` = function() { print(p); print(p + theme_void(), newpage = FALSE) }
)
for (nm in names(kinds)) {
  s <- open_svg(); suppressWarnings(kinds[[nm]]())
  pk <- page_kind(); n <- length(as.character(s())); invisible(grDevices::dev.off())
  cat(sprintf("  %-32s pages %d | page kind %-6s | base entries %d, grid grobs %d\n", nm, n, pk$kind,
              sum(grepl("^C_", pk$ops)), pk$grid_grobs))
}

cat("\n== E. cost of drawing the page twice and comparing (host) ==\n")
time_it <- function(expr) { t0 <- Sys.time(); force(expr); as.numeric(difftime(Sys.time(), t0, units = "secs")) }
for (n in c(1e3, 1e4, 1e5)) {
  set.seed(1); big <- data.frame(x = rnorm(n), y = rnorm(n))
  pb <- ggplot(big, aes(x, y)) + geom_point(size = .3)
  t_now <- time_it(gloss(pb, dense = Inf, context = FALSE))
  t_page <- time_it({ s <- open_svg(); print(pb); A <- last_page(s); sub <- capture_grid_page(s) })
  t_sigA <- time_it(a <- scene_signatures(A)); t_sigB <- time_it(b <- scene_signatures(sub$scene))
  cat(sprintf("  %6.0f points: gloss() today %.2f s | page capture %.2f s | comparing (two signature passes) %.2f s | identical=%s\n",
              n, t_now, t_page, t_sigA + t_sigB, identical(a, b)))
}
