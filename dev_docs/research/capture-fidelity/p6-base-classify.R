# P6 (2026-11-11): page-capture plan, Task 6. Design §分类 measured naming
# rules on one base figure captured through gridGraphics
# (dev_docs/research/capture-groups/classify.R, classify.out: 15 leaves, 60
# elements, 59 classified, 2 of them wrong: legend()'s rect and segments as
# data marks; legend text unclassified). Base leaves are now display-list
# entries named by their call. The same figure, captured by the package on the
# page route, classified by the same rules translated to call names.
#
# Ground truth by call order: bf() calls plot(), abline(), legend(); legend()
# is the last call, so the entries after abline's are the legend's. Roles as
# in classify.R: data marks (points, the fitted line), guides (axes, titles,
# legend), decoration (box).
#
# Host. Run from the repository root:
#   Rscript dev_docs/research/capture-fidelity/p6-base-classify.R
suppressMessages(pkgload::load_all(".", quiet = TRUE, export_all = TRUE, helpers = FALSE))

bf <- function() {
  plot(mtcars$wt, mtcars$mpg, pch = 19, main = "base")
  abline(lm(mpg ~ wt, mtcars))
  legend("topright", "fit", lty = 1)
}
fig <- gloss(bf, width = 7, height = 5, context = FALSE)
lv <- fig$substrate$leaves
entry <- as.integer(sub("^base/([0-9]+)/.*$", "\\1", lv$path))
after_abline <- entry > max(entry[lv$name == "abline"])
truth <- ifelse(after_abline, "guide: legend",
         ifelse(lv$name %in% c("plotXY", "abline"), "data: layer mark",
         ifelse(lv$name == "axis", "guide: axis",
         ifelse(lv$name == "title", "guide: titles",
         ifelse(lv$name == "box", "decoration: plot box", "?")))))

# classify.R's rules_base, matched on the call name instead of gridGraphics'
# path; "points" and "lines" are plotXY (type "p" and "l") on the display list
rule <- function(pat, role, kind) list(pat = pat, role = role, kind = kind)
rules_call <- list(
  rule("^(plotXY|abline|polygon|rect|segments|arrows|symbols|image|contour|persp)$", "data", "layer mark"),
  rule("^axis$", "guide", "axis"),
  rule("^box$", "decoration", "plot box"),
  rule("^(title|mtext)$", "guide", "titles"),
  rule("^legend$", "guide", "legend"),
  rule("^(plot_new|plot_window)$", "decoration", "background"))
role <- rep(NA_character_, nrow(lv))
for (r in rules_call) {
  hit <- is.na(role) & grepl(r$pat, lv$name)
  role[hit] <- paste0(r$role, ": ", r$kind)
}

tab <- data.frame(id = lv$id, entry = entry, name = lv$name, elements = lv$n_drawn,
                  rule = ifelse(is.na(role), "UNCLASSIFIED", role), truth = truth, stringsAsFactors = FALSE)
tab$outcome <- ifelse(tab$rule == "UNCLASSIFIED", "unclassified", ifelse(tab$rule == tab$truth, "right", "wrong"))
cat(sprintf("== base figure of design §分类, page route: %d leaves, %d elements (scene %d, unowned %d)\n",
            nrow(lv), sum(lv$n_drawn), nrow(fig$substrate$elements), sum(is.na(fig$substrate$elements$leaf))))
print(tab, row.names = FALSE)
by <- tapply(tab$elements, tab$outcome, sum)
cat(sprintf("\nelements: right %d, wrong %d, unclassified %d, of %d (gridGraphics route, classify.out: 57 right, 2 wrong, 1 unclassified, of 60)\n",
            by["right"] %||% 0L, by["wrong"] %||% 0L, by["unclassified"] %||% 0L, sum(tab$elements)))
cat(sprintf("verdict %s; names: %s\n", fig$meta$page$verdict, paste(unique(lv$name), collapse = ", ")))
