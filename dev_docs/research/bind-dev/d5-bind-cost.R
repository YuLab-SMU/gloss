# What binding costs beside capture, at 10^3, 10^4 and 10^5 points (M1 plan,
# "Done when": time reported at these sizes; Task 6a decides from it whether
# bindings are computed at capture or on demand), and what the stored
# bindings add to a single-file bundle. Hand-built figures, the host, no
# bench figure:
#   Rscript -e 'options(width = 200); source("dev_docs/research/bind-dev/d5-bind-cost.R")'
# Capture is capture_figure(bind = FALSE); the bind step is bind_figure() on
# the engine state of that same capture (the bench's "bind" time is a second
# capture plus this step). Times are the median of 3. Sizes are the HTML
# file gl_write() gives for the figure captured without and with bindings.
# The last block is a base figure of many leaves (one segments() call each).

suppressMessages(devtools::load_all(".", quiet = TRUE))
library(ggplot2)

timed <- function(f, n = 3) {
  secs <- numeric(n)
  value <- NULL
  for (i in seq_len(n)) {
    t0 <- proc.time()[["elapsed"]]
    value <- f()
    secs[i] <- proc.time()[["elapsed"]] - t0
  }
  list(value = value, s = stats::median(secs))
}

one <- function(n, facet = FALSE) {
  set.seed(5)
  d <- data.frame(x = rnorm(n), y = rnorm(n), g = sample(letters[1:4], n, TRUE))
  p <- ggplot(d, aes(x, y)) + geom_point(size = 0.3)
  if (facet) p <- p + facet_wrap(~g) + aes(colour = g)
  eng <- gloss:::engine_candidates(p)
  cap <- timed(function() gloss:::capture_figure(p, eng, width = 7, height = 5, context = FALSE, bind = FALSE))
  res <- cap$value
  bnd <- timed(function() gloss:::bind_figure(res$fig, res$engine, res$state))
  b <- bnd$value
  st <- table(factor(b$elements$status, c("verified", "ambiguous", "failed")))
  size <- function(fig) {
    f <- tempfile(fileext = ".html")
    on.exit(unlink(f))
    gloss::gl_write(fig, f)
    file.size(f)
  }
  with <- gloss::gloss(p, width = 7, height = 5, context = FALSE)
  data.frame(
    points = n, panels = if (facet) 4L else 1L,
    capture_s = round(cap$s, 2), bind_s = round(bnd$s, 2), ratio = round(bnd$s / cap$s, 2),
    elements = nrow(b$elements), verified = st[["verified"]], ambiguous = st[["ambiguous"]],
    failed = st[["failed"]],
    html_kb = round(size(res$fig) / 1024, 1), html_kb_bound = round(size(with) / 1024, 1),
    added_kb = round((size(with) - size(res$fig)) / 1024, 1)
  )
}

out <- do.call(rbind, list(
  one(1e3), one(1e4), one(1e5),
  one(1e3, TRUE), one(1e4, TRUE), one(1e5, TRUE)
))
print(out, row.names = FALSE)

many <- function(n) function() {
  graphics::plot(0:1, 0:1, type = "n")
  set.seed(1)
  for (i in seq_len(n)) graphics::segments(stats::runif(1), stats::runif(1), stats::runif(1), stats::runif(1))
}
leaves <- do.call(rbind, lapply(c(500, 1000, 2000, 5000), function(n) {
  eng <- gloss:::engine_candidates(many(n))
  cap <- timed(function() gloss:::capture_figure(many(n), eng, width = 5, height = 4, context = FALSE, bind = FALSE), n = 1)
  res <- cap$value
  bnd <- timed(function() gloss:::bind_figure(res$fig, res$engine, res$state), n = 1)
  data.frame(leaves = nrow(res$fig$substrate$leaves), capture_s = round(cap$s, 2), bind_s = round(bnd$s, 2),
             ms_per_leaf = round(1000 * bnd$s / nrow(res$fig$substrate$leaves), 2),
             verified = sum(bnd$value$leaves$status == "verified"))
}))
cat("\na base figure of n segments() calls, one leaf each (one run)\n")
print(leaves, row.names = FALSE)
cat(sprintf(
  "\n%s | ggplot2 %s | svglite %s\n", R.version.string,
  utils::packageVersion("ggplot2"), utils::packageVersion("svglite")
))
