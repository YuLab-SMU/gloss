#!/usr/bin/env Rscript

# Deterministic M5 checks for true and false claims, transformed data, masked
# binding and controlled record updates. This script makes no model calls.

suppressMessages(pkgload::load_all(".", quiet = TRUE, export_all = FALSE, helpers = FALSE))
if (!requireNamespace("ggplot2", quietly = TRUE)) stop("ggplot2 is required")
`%||%` <- function(a, b) if (is.null(a) || !length(a)) b else a
out_dir <- file.path("bench", "runs", "2026-11-17-m5-deterministic")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

make_fixture <- function(kind) {
  d <- mtcars
  if (kind == "perturbed") {
    set.seed(20261117)
    d <- d[sample.int(nrow(d)), , drop = FALSE]
    d$dvx <- d$wt * 2.7 + 4.1
    d$hlr <- d$mpg * 1.9 - 7.3
    p <- ggplot2::ggplot(d, ggplot2::aes(dvx, hlr)) + ggplot2::geom_point()
  } else {
    d$x <- d$wt
    d$y <- if (kind == "counterfactual") max(d$mpg) + min(d$mpg) - d$mpg else d$mpg
    p <- ggplot2::ggplot(d, ggplot2::aes(x, y)) + ggplot2::geom_point()
  }
  list(kind = kind, fig = gloss::gloss(p, context = FALSE))
}

fixtures <- stats::setNames(lapply(c("original", "perturbed", "counterfactual"), make_fixture),
                            c("original", "perturbed", "counterfactual"))
cases <- list(
  original_true = list(fixture = "original", response = "y", predictor = "x", expect = "negative", expected = "verified"),
  original_false = list(fixture = "original", response = "y", predictor = "x", expect = "positive", expected = "failed"),
  perturbed_true = list(fixture = "perturbed", response = "y", predictor = "x", expect = "negative", expected = "verified"),
  counterfactual_false = list(fixture = "counterfactual", response = "y", predictor = "x", expect = "negative", expected = "failed")
)

claim_rows <- do.call(rbind, lapply(names(cases), function(id) {
  x <- cases[[id]]
  f <- fixtures[[x$fixture]]$fig
  body <- list(text = id, check = list(kind = "trend", table = "built_layer1",
                                       args = list(response = x$response, predictor = x$predictor, expect = x$expect)))
  check <- gl_check(gloss::gl_table(f, "built_layer1"), "trend", body$check$args)
  rec <- tryCatch(gloss::gl_record(f, "claim", gloss::gl_elements(f)$id[1L], body, by = "m5"),
                  error = function(e) e)
  status <- if (inherits(rec, "error")) "error" else tail(gloss::gl_records(rec, "claim")$status, 1L)
  record_match <- if (x$expected == "failed") status %in% c("failed", "rejected") else status == x$expected
  data.frame(id = id, expected = x$expected, check_status = check$status, record_status = status,
             check_matches = check$status == x$expected, record_matches = record_match,
             stringsAsFactors = FALSE)
}))
write.csv(claim_rows, file.path(out_dir, "claims.csv"), row.names = FALSE)

markup <- tryCatch(gloss::gl_propose(fixtures$original$fig, layer = "claim",
                                     anchor = gloss::gl_elements(fixtures$original$fig)$id[1L],
                                     body = list(text = "<script>alert(1)</script>")), error = function(e) e)
markup_rejected <- inherits(markup, "error") || identical(markup$outcome, "rejected")

f <- fixtures$original$fig
b <- gloss::gl_bindings(f)
b <- utils::head(b[b$status == "verified" & !is.na(b$row), , drop = FALSE], 20L)
masked <- if (nrow(b)) do.call(rbind, lapply(seq_len(nrow(b)), function(i) {
  z <- b[i, ]
  wrong <- if (z$row == 1L) 2L else 1L
  right <- gl_propose(f, list(kind = "binding", element = z$element, table = z$table, row = z$row))
  bad <- gl_propose(f, list(kind = "binding", element = z$element, table = z$table, row = wrong))
  data.frame(element = z$element, right = right$outcome, wrong = bad$outcome, stringsAsFactors = FALSE)
})) else data.frame()
write.csv(masked, file.path(out_dir, "masked-binding.csv"), row.names = FALSE)

base_plot <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point() +
  ggplot2::geom_smooth(method = "lm", se = FALSE)
base <- gloss::gloss(base_plot, context = FALSE)
anchor <- gloss::gl_bindings(base)$element[1L]
recorded <- gloss::gl_record(base, "meaning", anchor, list(text = "m5 anchor"), by = "m5")
edited <- list(
  title = base_plot + ggplot2::labs(title = "edited"),
  colour = ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point(colour = "red") + ggplot2::geom_smooth(method = "lm", se = FALSE),
  subset = ggplot2::ggplot(mtcars[mtcars$cyl != 6, , drop = FALSE], ggplot2::aes(wt, mpg)) + ggplot2::geom_point() + ggplot2::geom_smooth(method = "lm", se = FALSE),
  add_layer = base_plot + ggplot2::geom_text(data = mtcars[1, , drop = FALSE], ggplot2::aes(label = "one")),
  delete_layer = ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
)
updates <- do.call(rbind, lapply(names(edited), function(id) {
  out <- tryCatch(gloss::gl_rebase(recorded, edited[[id]]), error = function(e) e)
  if (inherits(out, "error")) return(data.frame(update = id, rebase = "error", invalid = NA_integer_))
  rr <- gloss::gl_records(out, "meaning")
  data.frame(update = id, rebase = "ok", invalid = sum(rr$status == "invalid"))
}))
write.csv(updates, file.path(out_dir, "updates.csv"), row.names = FALSE)

summary <- list(
  claims = list(total = nrow(claim_rows), check_matches = sum(claim_rows$check_matches), record_matches = sum(claim_rows$record_matches)),
  markup_rejected = markup_rejected,
  masked_binding = list(tried = nrow(masked), right_accepted = sum(masked$right == "accepted"), wrong_rejected = sum(masked$wrong == "rejected")),
  updates = list(total = nrow(updates), successful = sum(updates$rebase == "ok"), invalid = sum(updates$invalid, na.rm = TRUE))
)
jsonlite::write_json(summary, file.path(out_dir, "summary.json"), auto_unbox = TRUE, pretty = TRUE)
writeLines(c(
  sprintf("claims %d/%d check matches, %d/%d record matches", summary$claims$check_matches, summary$claims$total, summary$claims$record_matches, summary$claims$total),
  sprintf("markup rejected %s; masked right %d, wrong rejected %d", summary$markup_rejected, summary$masked_binding$right_accepted, summary$masked_binding$wrong_rejected),
  sprintf("updates %d/%d successful; invalid records %d", summary$updates$successful, summary$updates$total, summary$updates$invalid)
), file.path(out_dir, "README.txt"))
print(summary)
