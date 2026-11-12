# S6 (2026-11-10): three details behind S2, S3 and S5. Host, no third-party code.
#   A. is the device's page text append-only while a base plot is replayed, so
#      an entry's primitives can be read from the text added since the last
#      read (linear) instead of parsing the whole page after every entry?
#   B. a base plot recorded on another device (pdf) and replayed on svglite;
#   C. in S5-A the leaves differ only in `name` and `vp`: is that only grid's
#      automatic numbering?
# Run from the repository root: Rscript dev_docs/research/capture-fidelity/s6-details.R
suppressMessages(pkgload::load_all(".", quiet = TRUE, export_all = TRUE, helpers = FALSE))
source("dev_docs/research/capture-fidelity/page-capture.R")
source("tests/testthat/helper-figures.R")

record_on <- function(f, device = c("svglite", "pdf")) {
  device <- match.arg(device)
  if (device == "svglite") s <- svglite::svgstring(width = 7, height = 5) else grDevices::pdf(NULL, width = 7, height = 5)
  grDevices::dev.control("enable"); f(); rp <- grDevices::recordPlot(); invisible(grDevices::dev.off())
  rp
}

cat("== A. incremental reading of the device while replaying by entry ==\n")
prim_re <- "<(circle|rect|line|polyline|polygon|path|text|image)[ />]"
count_new <- function(txt) {
  txt <- gsub("(?s)<defs>.*?</defs>", "", txt, perl = TRUE)   # clip-path definitions hold a rect
  lengths(regmatches(txt, gregexpr(prim_re, txt, perl = TRUE)))
}
replay_incremental <- function(rp, width = 7, height = 5) {
  dl <- as.list(rp[[1]])
  s <- svglite::svgstring(width = width, height = height, standalone = TRUE)
  dev <- grDevices::dev.cur()
  on.exit(if (dev %in% grDevices::dev.list()) grDevices::dev.off(dev), add = TRUE)
  grDevices::dev.control("enable")
  stub <- rp; stub[1] <- list(NULL); grDevices::replayPlot(stub)
  # an open page is read with its open clip groups closed; drop those closing tags
  body <- function() { p <- as.character(s()); if (!length(p)) "" else sub("(\\s*</g>)*\\s*</svg>\\s*$", "", p[length(p)]) }
  prev <- ""; added <- integer(length(dl)); append_only <- TRUE
  for (k in seq_along(dl)) {
    e <- dl[[k]]
    do.call(e[[1]], as.list(e[[2]]), quote = TRUE)
    now <- body()
    if (!startsWith(now, prev)) append_only <- FALSE
    added[k] <- count_new(substr(now, nchar(prev) + 1L, nchar(now)))
    prev <- now
  }
  list(added = added, append_only = append_only)
}
# The same on a file device kept valid while it is written (always_valid):
# only the bytes added since the last read are read, so the cost is linear.
replay_tail <- function(rp, width = 7, height = 5) {
  dl <- as.list(rp[[1]])
  f <- tempfile(fileext = ".svg")
  svglite::svglite(f, width = width, height = height, standalone = TRUE, always_valid = TRUE)
  dev <- grDevices::dev.cur()
  con <- NULL
  on.exit({
    if (!is.null(con)) close(con)
    if (dev %in% grDevices::dev.list()) grDevices::dev.off(dev)
    unlink(f)
  }, add = TRUE)
  grDevices::dev.control("enable")
  stub <- rp; stub[1] <- list(NULL); grDevices::replayPlot(stub)
  pos <- 0; added <- integer(length(dl))
  for (k in seq_along(dl)) {
    e <- dl[[k]]
    do.call(e[[1]], as.list(e[[2]]), quote = TRUE)
    size <- file.size(f)
    if (is.na(size) || size <= pos) next
    if (is.null(con)) con <- file(f, "rb")
    seek(con, pos)
    tail <- rawToChar(readBin(con, "raw", size - pos))
    # the tags that keep the file valid are overwritten by the next write
    closing <- regmatches(tail, regexpr("(\\s*</g>)*\\s*</svg>\\s*$", tail))
    keep <- nchar(tail, "bytes") - if (length(closing)) nchar(closing, "bytes") else 0L
    added[k] <- count_new(substr(tail, 1L, keep))
    pos <- pos + keep
  }
  grDevices::dev.off(dev)
  list(added = added, page = paste(readLines(f, warn = FALSE), collapse = "\n"))
}
many <- function(n) function() { plot(0:1, 0:1, type = "n"); for (i in seq_len(n)) segments(runif(1), runif(1), runif(1), runif(1)) }
for (n in c(100, 1300, 5000)) {
  set.seed(1); rp <- record_on(many(n))
  t1 <- system.time(full <- replay_by_entry(rp))[["elapsed"]]
  t2 <- system.time(inc <- replay_incremental(rp))[["elapsed"]]
  t3 <- system.time(tl <- replay_tail(rp))[["elapsed"]]
  cat(sprintf("  %5d entries: whole page parsed after each entry %6.2f s | page text re-read, new part counted %5.2f s (append-only %s, same counts %s) | file device, new bytes only %5.2f s (same counts %s, same page %s)\n",
              length(rp[[1]]), t1, t2, inc$append_only, identical(cumsum(inc$added), full$seen), t3,
              identical(cumsum(tl$added), full$seen), identical(scene_signatures(tl$page), scene_signatures(full$page))))
}
for (nm in c("pairs", "image", "legend")) {
  f <- switch(nm,
    pairs = function() plot(mtcars[, c(1, 3:6)], pch = 20),
    image = function() { image(volcano); contour(volcano, add = TRUE) },
    legend = function() { par(mfrow = c(1, 2)); barplot(1:3, col = 2:4); legend("top", c("a", "b"), fill = 2:3); plot(1:10); text(5, 5, "a\nb") })
  rp <- record_on(f); full <- replay_by_entry(rp); inc <- replay_incremental(rp); tl <- replay_tail(rp)
  cat(sprintf("  %-7s append-only %s | same counts per entry: re-read %s, file device %s (%d primitives, %d entries)\n", nm, inc$append_only,
              identical(cumsum(inc$added), full$seen), identical(cumsum(tl$added), full$seen),
              full$seen[length(full$seen)], length(full$seen)))
}

cat("\n== B. a base plot recorded on pdf(NULL), replayed on svglite ==\n")
cases <- list(
  scatter = function() { plot(mtcars$wt, mtcars$mpg, pch = 19, main = "A title"); legend("topright", "fit", lty = 1) },
  border_0 = function() { plot.new(); rect(.2, .2, .8, .8, col = "white", border = 0) },
  mfrow_text = function() { par(mfrow = c(1, 2)); plot(1:10, las = 2); barplot(c(alpha = 1, beta = 2)); mtext("outer", outer = TRUE, line = -2) }
)
for (nm in names(cases)) {
  native <- scene_signatures(plain_svg(cases[[nm]], 7, 5))
  for (dv in c("svglite", "pdf")) {
    rp <- record_on(cases[[nm]], dv)
    a <- scene_signatures(replay_by_entry(rp)$page)
    cat(sprintf("  %-10s recorded on %-7s: replay on svglite = the code on svglite: %-5s (differ %d of %d)\n", nm, dv,
                identical(a, native), diffn(a, native), length(native)))
  }
}

cat("\n== C. leaves of the page route against gloss(): do name and vp differ only by grid's numbering? ==\n")
strip_num <- function(x) gsub("[0-9]+", "#", x)
inputs <- six_inputs()
for (nm in setdiff(names(inputs), "base")) {
  inp <- inputs[[nm]]
  old <- suppressWarnings(gloss(inp$x, width = 7, height = 5, dense = Inf, context = FALSE))$substrate$leaves
  set.seed(99)
  s <- svglite::svgstring(width = 7, height = 5); grDevices::dev.control("enable")
  suppressWarnings(inp$draw())
  new <- suppressWarnings(capture_grid_page(s))$leaves
  cat(sprintf("  %-13s names equal %-5s, after replacing digits %-5s | vp equal %-5s, after replacing digits %-5s | paths after replacing digits %s\n", nm,
              identical(old$name, new$name), identical(strip_num(old$name), strip_num(new$name)),
              identical(old$vp, new$vp), identical(strip_num(old$vp), strip_num(new$vp)),
              identical(strip_num(old$path), strip_num(new$path))))
}
