# What is left unchecked after binding, by reason, and what each reason
# lacks (ADR-0009; idea/2026-11-12-binding-proposals.md). Reads two archived
# runs' leaf tables; runs no figure code, so the host will do:
#   Rscript dev_docs/research/bind-dev/d3-residue.R
# An element counts as residue when its leaf is unbound or a count mismatch,
# or when it failed. `lacks` is a reading of the reason's text, one class per
# reason, not a check made leaf by leaf:
#   contract  a count or a comparison the drawing system itself defines
#             (grid, R's engine, base, or an engine gloss supports)
#   table     nothing to bind to: the engine holds no table for the leaf
#   package   what a package outside those engines does when it draws
#   unread    not looked at

runs <- c(tree = "bench/runs/2026-11-12-1107-bind-dev-tree-leaves.csv",
          v0 = "bench/runs/2026-11-12-1116-bind-dev-leaves.csv")

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

one <- function(set, file) {
  d <- utils::read.csv(file, stringsAsFactors = FALSE)
  failed <- d$status %in% c("failed", "partly_failed")
  r <- d[d$status %in% c("unbound", "count_mismatch") | failed, , drop = FALSE]
  f <- r$status %in% c("failed", "partly_failed")
  r$elements <- ifelse(f, r$failed, r$n_elements)
  r$reason_class <- NA_character_
  r$lacks <- NA_character_
  for (i in seq_len(nrow(classes))) {
    k <- is.na(r$reason_class) & !f & r$status == "unbound" & grepl(classes[i, 1], r$reason)
    r$reason_class[k] <- classes[i, 2]
    r$lacks[k] <- classes[i, 3]
  }
  # a count mismatch: outlines are named in the reason; the rest by the geom
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
  stopifnot(!anyNA(r$reason_class))
  r$set <- set
  r[r$elements > 0, c("set", "id", "engine", "reason_class", "lacks", "elements")]
}

r <- do.call(rbind, Map(one, names(runs), runs))
tab <- function(by) {
  a <- stats::aggregate(r$elements, r[by], sum)
  names(a)[ncol(a)] <- "elements"
  a$leaves <- stats::aggregate(r$elements, r[by], length)$x
  a$figures <- stats::aggregate(r$id, r[by], function(x) length(unique(x)))$x
  a[order(-a$elements), ]
}
cat("== residue by set\n")
print(tab("set"), row.names = FALSE)
cat("\n== by reason\n")
print(tab(c("reason_class", "lacks", "set")), row.names = FALSE, right = FALSE)
cat("\n== by what is lacking\n")
print(tab("lacks"), row.names = FALSE)
cat("\n== by what is lacking, by set\n")
print(tab(c("lacks", "set")), row.names = FALSE)
cat(sprintf("\ntotal %d elements in %d figures; package without outlines: %d elements in %d figures\n",
            sum(r$elements), length(unique(r$id)),
            sum(r$elements[r$lacks == "package" & !grepl("outlines", r$reason_class)]),
            length(unique(r$id[r$lacks == "package" & !grepl("outlines", r$reason_class)]))))
