# What a binding run leaves unchecked, by class of reason, and which classes
# no baseline run gave (tree binding plan, Task 7; ADR-0009).
#   Rscript bench/R/score-residue.R <run>-leaves.csv [...] [--against <baseline>-leaves.csv ...]
# Reads leaf tables only; draws nothing and runs no figure code.
#
# Residue: the elements of a leaf that is `unbound` or a `count_mismatch`,
# and the failed elements of a paired leaf. Leaves `outside` the layers and
# `not_paired` leaves are not residue, as in score-bind.R.
#
# A class is the reason with its numbers and names taken out. The table below
# is the one of dev_docs/research/bind-dev/d3-residue.R, which sorted the two
# development sets on 2026-11-12; on those runs this script gives the same
# classes and counts. `lacks` is a reading of the reason's text, one per
# class, not a check made leaf by leaf:
#   contract  a count or a comparison the drawing system itself defines
#   table     nothing to bind to: the engine holds no table for the leaf
#   package   what a package outside gloss's engines does when it draws
#   unread    not looked at
# A reason the table does not know becomes a class of its own ("other: ..."),
# with digits replaced by N, and is `unread`. A failed element's class is
# "failed: <geom>"; a count mismatch that is neither outlines nor sf paths is
# "count mismatch: <geom>".

classes <- rbind(
  c("^the text was drawn as glyph outlines",            "text drawn as glyph outlines (showtext)",            "package"),
  c("makes what it draws when it is drawn",             "made when the layer's grob is drawn",                "package"),
  c("^a copy of ",                                      "a copy of a sibling at one offset",                  "package"),
  c("^the rows' shapes draw",                           "the rows' shapes do not add up to the elements",     "unread"),
  c("neither one per row nor one per group",            "neither one element per row nor one per group",      "unread"),
  c("^engine 'grid' states no bindings",                "the grid engine states no bindings",                 "table"),
  c("^print[.]",                                        "a print method of its own: tables withheld",         "table"),
  c("^annotation tracks and dendrograms",               "heatmap annotation tracks and dendrograms",          "contract"),
  c("belongs to no plot gloss found",                   "a patchwork panel no composed plot owns",            "contract"),
  c("^rectangles are drawn as polygons munched",        "rectangles munched along a coord",                   "contract"),
  c("^plotXY of type",                                  "base plot types 'h' and 'o'",                        "contract"),
  c("carry neither x and y nor",                        "rows with neither x and y nor bounds",               "contract"),
  c("^no comparison for <line>",                        "no comparison for a <line> paired this way",         "contract"),
  c("have no y$",                                       "rows paired with polygons have no y",                "contract")
)

residue <- function(file) {
  d <- utils::read.csv(file, stringsAsFactors = FALSE)
  failed <- d$status %in% c("failed", "partly_failed")
  r <- d[d$status %in% c("unbound", "count_mismatch") | failed, , drop = FALSE]
  if (!nrow(r)) return(data.frame(run = character(), id = character(), engine = character(),
                                  reason_class = character(), lacks = character(), elements = integer()))
  f <- r$status %in% c("failed", "partly_failed")
  r$elements <- ifelse(f, r$failed, r$n_elements)
  r$reason_class <- NA_character_
  r$lacks <- NA_character_
  for (i in seq_len(nrow(classes))) {
    k <- is.na(r$reason_class) & !f & r$status == "unbound" & grepl(classes[i, 1], r$reason)
    r$reason_class[k] <- classes[i, 2]
    r$lacks[k] <- classes[i, 3]
  }
  cm <- r$status == "count_mismatch"
  out <- cm & grepl("glyph outlines", r$reason)
  r$reason_class[out] <- "text drawn as glyph outlines (showtext)"
  r$lacks[out] <- "package"
  sf <- cm & !out & r$geom %in% "GeomSf"
  r$reason_class[sf] <- "count mismatch: sf paths, several for a row"
  r$lacks[sf] <- "contract"
  rest <- cm & !out & !sf
  r$reason_class[rest] <- paste0("count mismatch: ", r$geom[rest])
  r$lacks[rest] <- "package"
  r$reason_class[f] <- paste0("failed: ", r$geom[f])
  r$lacks[f] <- "package"
  other <- is.na(r$reason_class)
  r$reason_class[other] <- paste0("other: ", substr(gsub("[0-9]+([.][0-9]+)?", "N", r$reason[other]), 1, 110))
  r$lacks[other] <- "unread"
  r$run <- sub("-leaves[.]csv$", "", basename(file))
  r[r$elements > 0, c("run", "id", "engine", "reason_class", "lacks", "elements")]
}

tab <- function(r, by) {
  if (!nrow(r)) return(data.frame())
  a <- stats::aggregate(r$elements, r[by], sum)
  names(a)[ncol(a)] <- "elements"
  a$leaves <- stats::aggregate(r$elements, r[by], length)$x
  a$figures <- stats::aggregate(r$id, r[by], function(x) length(unique(x)))$x
  a[order(-a$elements), , drop = FALSE]
}

args <- commandArgs(trailingOnly = TRUE)
cut <- match("--against", args)
runs <- if (is.na(cut)) args else args[seq_len(cut - 1L)]
base <- if (is.na(cut)) character() else args[-seq_len(cut)]
if (!length(runs)) stop("usage: Rscript bench/R/score-residue.R <run>-leaves.csv [...] [--against <baseline>-leaves.csv ...]")

r <- do.call(rbind, lapply(runs, residue))
cat("== residue by run\n")
print(tab(r, "run"), row.names = FALSE)
cat("\n== by class of reason\n")
print(tab(r, c("reason_class", "lacks")), row.names = FALSE, right = FALSE)
cat("\n== by what is lacking\n")
print(tab(r, "lacks"), row.names = FALSE)
cat(sprintf("\ntotal: %d elements in %d leaves of %d figures, %d classes\n",
            sum(r$elements), nrow(r), length(unique(r$id)), length(unique(r$reason_class))))

if (length(base)) {
  b <- do.call(rbind, lapply(base, residue))
  for (scope in c("every baseline", basename(base))) {
    known <- if (scope == "every baseline") unique(b$reason_class)
             else unique(b$reason_class[b$run == sub("-leaves[.]csv$", "", scope)])
    new <- r[!r$reason_class %in% known, , drop = FALSE]
    cat(sprintf("\n== classes not given by %s: %d elements in %d leaves of %d figures, %d classes\n",
                scope, sum(new$elements), nrow(new), length(unique(new$id)), length(unique(new$reason_class))))
    if (nrow(new)) {
      t <- tab(new, c("reason_class", "lacks"))
      t$ids <- vapply(t$reason_class, function(k) paste(sort(unique(new$id[new$reason_class == k])), collapse = " "), "")
      print(t, row.names = FALSE, right = FALSE)
    }
  }
}
