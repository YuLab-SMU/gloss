# What base graphics draws for points() and plot(type = "p"): parts per pch,
# and which arguments of the recorded plot.xy() call remove points or parts
# (plan 2026-11-11-tree-binding, Task 6, base points).
#   Rscript dev_docs/research/point-symbols/base.R

rec <- function(f) { pdf(NULL); dev.control("enable"); f(); r <- recordPlot(); dev.off(); r }
r <- rec(function() plot(1:3, pch = c(3, 8, 1), cex = c(1, 2, 0), lty = 2, lwd = 1))
dl <- r[[1]]
for (e in dl) { a <- as.list(e[[2]]); if (identical(a[[1]]$name, "C_plotXY")) { cat("args:", length(a), "\n"); str(a[-1]) } }
count <- function(f) {
  s <- svglite::svgstring(width = 4, height = 4, standalone = TRUE); f(); dev.off()
  doc <- xml2::read_xml(as.character(s())[1]); xml2::xml_ns_strip(doc)
  n <- xml2::xml_find_all(doc, "//*[not(ancestor::defs) and not(ancestor::clipPath)][self::circle or self::rect or self::line or self::polygon or self::polyline or self::path or self::text]")
  tags <- xml2::xml_name(n); tags <- tags[!(tags == "rect" & xml2::xml_attr(n, "width") %in% "100%")]
  tags
}
pts <- function(...) function() { plot.new(); plot.window(c(0, 4), c(0, 4)); points(1:3, 1:3, ...) }
show <- function(lab, f) { t <- count(f); cat(sprintf("%-40s %d: %s\n", lab, length(t), paste(t, collapse = " "))) }
for (p in c(0:25)) { t <- count(pts(pch = p)); cat(p, length(t) / 3, " ") }; cat("\n")
show("pch c(3, 8, 7)", pts(pch = c(3, 8, 7)))
show("pch '.'", pts(pch = "."))
show("pch c('a', NA, 'b')", pts(pch = c("a", NA, "b")))
show("pch NA", pts(pch = NA))
show("pch 3, lty 0", pts(pch = 3, lty = 0))
show("pch 3, lty 'blank'", pts(pch = 3, lty = "blank"))
show("pch 3, lty c(0, 1, 1) (recycled?)", pts(pch = 3, lty = c(0, 1, 1)))
show("pch 3, lwd NA", pts(pch = 3, lwd = NA))
show("pch 3, lwd c(NA, 1, 1)", pts(pch = 3, lwd = c(NA, 1, 1)))
show("pch c(1, 10, 3), cex 0", pts(pch = c(1, 10, 3), cex = 0))
show("pch 1, cex c(1, 0, NA)", pts(pch = 1, cex = c(1, 0, NA)))
show("pch 3, x NA", function() { plot.new(); plot.window(c(0, 4), c(0, 4)); points(c(1, NA, 3), 1:3, pch = 3) })
show("par(lty = 0); pch 3", function() { plot.new(); plot.window(c(0, 4), c(0, 4)); par(lty = 0); points(1:3, 1:3, pch = 3) })
show("pch c(1, 3, 0), cex -1", pts(pch = c(1, 3, 0), cex = -1))
show("pch c(1, 3, 0), cex 0.001", pts(pch = c(1, 3, 0), cex = 0.001))
show("pch c(26, 31, 128, 256)", pts(pch = c(26, 31, 128, 256)))
show("pch -65", pts(pch = -65))
show("type b? (no: points only)", pts(pch = 9))
show("pch 200, font 5", pts(pch = 200, font = 5))
r2 <- rec(function() { plot.new(); plot.window(c(0, 4), c(0, 4)); par(lty = 0); points(1:3, 1:3, pch = 3, font = 5) })
for (e in r2[[1]]) { a <- as.list(e[[2]]); if (identical(a[[1]]$name, "C_plotXY")) str(a[-(1:2)]) }
