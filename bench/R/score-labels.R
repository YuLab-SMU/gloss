# Check and compare role labels (M1 plan 2026-11-11-m1-roles-and-binding,
# Task 1; vocabulary and units in bench/labels/guideline.md).
#
#   Rscript bench/R/score-labels.R check <labels dir> [sheets dir]
#     every label resolves to a leaf of the current sheets (same key and
#     occurrence, same class, same number of elements), every leaf with
#     elements is covered exactly once, roles and kinds are in the vocabulary.
#     Any failure stops the run with the list; nothing is skipped.
#   Rscript bench/R/score-labels.R agree <dir A> <dir B> [sheets dir]
#     the same checks on both, then agreement on the figures both labelled:
#     Cohen's kappa on roles (leaf-weighted: the plan's criterion; and
#     element-weighted), on role and kind, the confusion of roles, splits and
#     minutes per figure.
# Sheets default to bench/labels/sheets. Reads CSV files only; draws nothing.

source("bench/R/sheet.R")

# Roles and their kinds: one file, shared with the label workbench.
vocabulary <- local({
  v <- jsonlite::read_json("bench/labels/vocabulary.json")$roles
  stats::setNames(lapply(v, function(r) vapply(r$kinds, function(k) k$kind, "")), vapply(v, function(r) r$role, ""))
})

read_chr <- function(f) utils::read.csv(f, stringsAsFactors = FALSE, colClasses = "character", na.strings = character())

# One annotator's labels of one figure, expanded to one row per element.
# Returns the rows, or stops listing every problem found.
expand_labels <- function(file, sheets) {
  id <- sub("\\.csv$", "", basename(file))
  sf <- file.path(sheets, paste0(id, ".csv"))
  if (!file.exists(sf)) stop(sprintf("%s: no sheet %s", file, sf), call. = FALSE)
  sh <- read_chr(sf)
  sh$n <- as.integer(sh$n_elements)
  lb <- read_chr(file)
  need <- c("key", "occurrence", "class", "n_elements", "elements", "role", "kind")
  miss <- setdiff(need, names(lb))
  if (length(miss)) stop(sprintf("%s: columns missing: %s", file, paste(miss, collapse = ", ")), call. = FALSE)
  problems <- character()
  at <- match(paste(lb$key, lb$occurrence), paste(sh$key, sh$occurrence))
  bad <- is.na(at)
  if (any(bad)) problems <- c(problems, sprintf("row %d: key '%s' #%s resolves to no leaf", which(bad), lb$key[bad], lb$occurrence[bad]))
  ok <- !bad
  diff <- ok & (lb$class != sh$class[at] | lb$n_elements != sh$n_elements[at])
  diff[is.na(diff)] <- FALSE
  if (any(diff)) problems <- c(problems, sprintf("row %d: leaf k %s is now %s with %s elements, the label says %s with %s",
                                                which(diff), sh$k[at[diff]], sh$class[at[diff]], sh$n_elements[at[diff]],
                                                lb$class[diff], lb$n_elements[diff]))
  ok <- ok & !diff
  role_ok <- lb$role %in% names(vocabulary)
  kind_ok <- role_ok & mapply(function(r, k) k %in% vocabulary[[r]] , ifelse(role_ok, lb$role, "data"), lb$kind)
  lab <- ok & sh$n[ifelse(is.na(at), 1L, at)] > 0
  if (any(lab & !role_ok)) problems <- c(problems, sprintf("row %d: role '%s' not in the vocabulary", which(lab & !role_ok), lb$role[lab & !role_ok]))
  if (any(lab & role_ok & !kind_ok)) problems <- c(problems, sprintf("row %d: kind '%s' is not a kind of %s",
                                                                   which(lab & role_ok & !kind_ok), lb$kind[lab & role_ok & !kind_ok], lb$role[lab & role_ok & !kind_ok]))
  rows <- list()
  for (i in which(lab)) {
    n <- sh$n[at[i]]
    idx <- tryCatch(parse_elements(lb$elements[i], n), error = function(e) {
      problems <<- c(problems, sprintf("row %d: %s", i, conditionMessage(e))); integer()
    })
    if (length(idx)) rows[[length(rows) + 1L]] <- data.frame(figure = id, k = as.integer(sh$k[at[i]]), n = n, index = idx,
                                                             role = lb$role[i], kind = lb$kind[i], stringsAsFactors = FALSE)
  }
  el <- if (length(rows)) do.call(rbind, rows) else data.frame(figure = character(), k = integer(), n = integer(), index = integer(), role = character(), kind = character())
  # coverage: every element of every leaf with elements, exactly once
  want <- sh[sh$n > 0, ]
  for (j in seq_len(nrow(want))) {
    got <- el$index[el$k == as.integer(want$k[j])]
    twice <- unique(got[duplicated(got)])
    none <- setdiff(seq_len(want$n[j]), got)
    if (length(twice)) problems <- c(problems, sprintf("leaf k %s: elements %s labelled more than once", want$k[j], paste(twice, collapse = ",")))
    if (length(none)) problems <- c(problems, sprintf("leaf k %s (%s, %d elements): elements %s not labelled", want$k[j], want$class[j], want$n[j],
                                                      if (length(none) == want$n[j]) "all" else paste(utils::head(none, 10), collapse = ",")))
  }
  if (length(problems)) stop(sprintf("%s:\n  %s", file, paste(problems, collapse = "\n  ")), call. = FALSE)
  el$weight <- 1 / el$n
  el
}

read_dir <- function(dir, sheets) {
  files <- list.files(dir, pattern = "\\.csv$", full.names = TRUE)
  files <- files[basename(files) != "time.csv"]
  if (!length(files)) stop(sprintf("%s: no label files", dir), call. = FALSE)
  errs <- character()
  out <- lapply(files, function(f) tryCatch(expand_labels(f, sheets), error = function(e) { errs <<- c(errs, conditionMessage(e)); NULL }))
  if (length(errs)) stop(sprintf("%d of %d label files do not resolve on %s:\n%s", length(errs), length(files), sheets,
                                 paste(errs, collapse = "\n")), call. = FALSE)
  do.call(rbind, out)
}

kappa_w <- function(a, b, w) {
  lv <- union(a, b)
  po <- sum(w[a == b]) / sum(w)
  pa <- tapply(w, factor(a, lv), sum) / sum(w); pa[is.na(pa)] <- 0
  pb <- tapply(w, factor(b, lv), sum) / sum(w); pb[is.na(pb)] <- 0
  pe <- sum(pa * pb)
  c(kappa = if (pe < 1) (po - pe) / (1 - pe) else NA_real_, agreement = po)
}

splits <- function(el) {
  r <- tapply(el$role, paste(el$figure, el$k), function(x) length(unique(x)))
  c(split = sum(r > 1), leaves = length(r))
}

summary_dir <- function(el, label) {
  cat(sprintf("== %s: %d figures, %d leaves, %d elements\n", label, length(unique(el$figure)),
              length(unique(paste(el$figure, el$k))), nrow(el)))
  s <- splits(el)
  cat(sprintf("split leaves (more than one role): %d of %d (%.1f%%)\n", s[1], s[2], 100 * s[1] / s[2]))
  by <- data.frame(leaves = tapply(el$weight, el$role, sum), elements = as.vector(table(el$role)[names(tapply(el$weight, el$role, sum))]))
  by$leaves <- round(by$leaves, 1)
  print(by)
}

args <- commandArgs(trailingOnly = TRUE)
if (!length(args) || !args[1] %in% c("check", "agree")) stop("usage: score-labels.R check <dir> [sheets] | agree <dir A> <dir B> [sheets]")
if (args[1] == "check") {
  sheets <- if (length(args) > 2) args[3] else "bench/labels/sheets"
  el <- read_dir(args[2], sheets)
  cat(sprintf("every label in %s resolves on %s\n", args[2], sheets))
  summary_dir(el, args[2])
} else {
  sheets <- if (length(args) > 3) args[4] else "bench/labels/sheets"
  a <- read_dir(args[2], sheets)
  b <- read_dir(args[3], sheets)
  cat(sprintf("every label in %s and %s resolves on %s\n", args[2], args[3], sheets))
  common <- intersect(unique(a$figure), unique(b$figure))
  cat(sprintf("figures labelled by both: %d (%s)\n", length(common), paste(sort(common), collapse = " ")))
  m <- merge(a[a$figure %in% common, ], b[b$figure %in% common, c("figure", "k", "index", "role", "kind")],
             by = c("figure", "k", "index"), suffixes = c(".a", ".b"))
  ra <- kappa_w(m$role.a, m$role.b, m$weight)
  re <- kappa_w(m$role.a, m$role.b, rep(1, nrow(m)))
  ka <- kappa_w(paste(m$role.a, m$kind.a), paste(m$role.b, m$kind.b), m$weight)
  ke <- kappa_w(paste(m$role.a, m$kind.a), paste(m$role.b, m$kind.b), rep(1, nrow(m)))
  cat(sprintf("\nroles, leaf-weighted (criterion, >= 0.8): kappa %.3f, agreement %.3f\n", ra[1], ra[2]))
  cat(sprintf("roles, element-weighted: kappa %.3f, agreement %.3f\n", re[1], re[2]))
  cat(sprintf("role and kind, leaf-weighted: kappa %.3f, agreement %.3f; element-weighted: kappa %.3f\n", ka[1], ka[2], ke[1]))
  cat("\n== confusion of roles, leaf-weighted (rows A, columns B)\n")
  print(round(stats::xtabs(weight ~ role.a + role.b, m), 1))
  cat("\n== by figure: roles, leaf-weighted\n")
  for (f in common) {
    x <- m[m$figure == f, ]
    k <- kappa_w(x$role.a, x$role.b, x$weight)
    cat(sprintf("%s: kappa %.3f, agreement %.3f, leaves %d\n", f, k[1], k[2], length(unique(x$k))))
  }
  cat("\n== leaves the annotators label differently (role)\n")
  d <- m[m$role.a != m$role.b, ]
  if (nrow(d)) {
    g <- stats::aggregate(index ~ figure + k + role.a + kind.a + role.b + kind.b, d, length)
    names(g)[names(g) == "index"] <- "elements"
    print(g[order(g$figure, g$k), ], row.names = FALSE)
  } else cat("none\n")
  for (x in list(list(a, args[2]), list(b, args[3]))) {
    s <- splits(x[[1]][x[[1]]$figure %in% common, ])
    cat(sprintf("\n%s: split leaves %d of %d (%.1f%%)", x[[2]], s[1], s[2], 100 * s[1] / s[2]))
    tf <- file.path(x[[2]], "time.csv")
    if (file.exists(tf)) {
      t <- read_chr(tf)
      t <- t[t$figure %in% common, ]
      cat(sprintf("; minutes per figure: %s (median %.1f)", paste(sprintf("%s %s", t$figure, t$minutes), collapse = ", "),
                  stats::median(as.numeric(t$minutes))))
    } else cat("; no time.csv")
  }
  cat("\n")
}
