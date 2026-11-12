# Derived tables: what code works out from the substrate and the engine's
# state at capture, kept in the figure beside the substrate (ADR-0007).
#
# A derived table is recomputed whenever the substrate is rebuilt and is
# never edited: a correction, an agent's proposal or a person's note is a
# record laid over it. It names the plugin that made it and the gloss that
# checked it, so a reader can tell which rules produced a value. Bindings
# (core-bind.R) are the first one; `fig$derived` is a list named by table.
#
#   name    "bindings"
#   by      the plugin whose statements it rests on: kind, name, version
#   gloss   the gloss version that computed it
#   params  scalars the computation depends on (the binding tolerance)
#   tables  named data frames

new_derived <- function(name, by, gloss = gloss_version(), params = list(), tables = list()) {
  list(name = name,
       by = list(kind = by$kind, name = by$name, version = by$version),
       gloss = gloss, params = params, tables = tables)
}

derived_file <- function(name, table) sprintf("substrate/derived/%s/%s.json", name, table)

# ---- in the bundle ----------------------------------------------------------
#
# One file per table, under substrate/derived/<name>/. A table of at least
# `binary_min_length` rows is stored compactly, column by column:
#
#   index   a column named `element` or `leaf` whose values are all ids of
#           the substrate: their positions in its elements or leaves
#   dict    any other character column: codes into its distinct values
#   scaled  a double column whose values are whole thousandths: the
#           thousandths, as integers
#
# Each becomes one integer vector, which the codec writes as shuffled binary.
# A compaction is used only if expanding it gives back the column exactly;
# otherwise the column is stored as it is. Smaller tables stay plain JSON, so
# the directory form reads and diffs as text.

compact_column <- function(v, name, sub) {
  if (is.character(v)) {
    ref <- switch(name, element = "elements", leaf = "leaves", NULL)
    if (!is.null(ref) && !anyNA(v)) {
      at <- match(v, sub[[ref]]$id)
      if (!anyNA(at)) return(list(values = at, how = list(as = "index", of = ref)))
    }
    levels <- unique(v[!is.na(v)])
    return(list(values = match(v, levels), how = list(as = "dict", levels = as.list(levels))))
  }
  if (is.double(v) && is.null(attributes(v))) {
    k <- round(v * 1000)
    if (!any(is.nan(v)) && all(is.na(k) | abs(k) < .Machine$integer.max)) {
      return(list(values = as.integer(k), how = list(as = "scaled", scale = 1000)))
    }
  }
  NULL
}

expand_column <- function(values, how, sub) {
  switch(how$as,
    index = sub[[how$of]]$id[values],
    dict = as.character(unlist(how$levels))[values],
    scaled = values / how$scale,
    cli::cli_abort("Unknown compaction {.val {how$as}} in a derived table.")
  )
}

compact_derived <- function(df, sub) {
  how <- list()
  if (nrow(df) < binary_min_length) return(list(data = df, how = how))
  for (cn in names(df)) {
    c1 <- compact_column(df[[cn]], cn, sub)
    if (is.null(c1) || !identical(expand_column(c1$values, c1$how, sub), df[[cn]])) next
    df[[cn]] <- c1$values
    how[[cn]] <- c1$how
  }
  list(data = df, how = how)
}

encode_derived <- function(derived, sub) {
  files <- list()
  for (d in derived) {
    for (tn in names(d$tables)) {
      c1 <- compact_derived(d$tables[[tn]], sub)
      meta <- list(derived = list(name = d$name, table = tn, compact = c1$how))
      files[[derived_file(d$name, tn)]] <- as_bytes(df_to_json(c1$data, meta = meta))
    }
  }
  files
}

# What the manifest says of the derived tables: everything but their rows.
derived_manifest <- function(derived) {
  lapply(derived, function(d) {
    list(by = d$by, gloss = d$gloss, params = d$params, tables = as.list(names(d$tables)))
  })
}

# The derived tables a bundle holds. One whose files are not all there is
# left out: the manifest's file check has already named what is missing.
decode_derived <- function(files, manifest, sub) {
  out <- list()
  for (name in names(manifest)) {
    m <- manifest[[name]]
    tabs <- as.character(unlist(m$tables))
    paths <- vapply(tabs, function(tn) derived_file(name, tn), "")
    if (!all(paths %in% names(files))) next
    tables <- lapply(paths, function(p) {
      got <- df_from_json(bytes_text(files[[p]]))
      df <- got$data
      how <- got$meta$derived$compact
      for (cn in names(how)) df[[cn]] <- expand_column(df[[cn]], how[[cn]], sub)
      df
    })
    names(tables) <- tabs
    out[[name]] <- new_derived(name, by = m$by, gloss = m$gloss, params = m$params %||% list(), tables = tables)
  }
  out
}
