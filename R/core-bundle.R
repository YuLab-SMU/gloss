# Bundles (design: 一个文件就能带走整份图包).
#
# A bundle is a set of files:
#   manifest.json            format, versions, substrate id, plugins, file hashes
#   context.json             sniffed context
#   substrate/scene.svg      the captured scene, groups inlined
#   substrate/elements.json  leaves, elements, panels, dense-leaf descriptors
#   substrate/index.bin      geometry of dense leaves (zlib, little-endian int32)
#   substrate/raster/*.png   rasters of dense leaves
#   substrate/tables/*.json  tables with their row keys
#   layers/, projections/    empty until records (M2) and projections (M3)
# The directory form writes them as files. The single-file form (HTML or
# SVG) is a projection that also carries every file, packed and compressed,
# in <script type="application/json" id="gloss-bundle">. Both forms hold the
# same bytes, so converting between them is lossless.

embed_modes <- c("default", "all", "summary", "none")

#' Write a figure
#'
#' Writes a `gloss_figure` as a bundle directory, or as a single HTML or SVG
#' file that shows the figure and embeds the whole bundle. `gl_read()` reads
#' either form back.
#'
#' `embed` controls which data travel with the bundle, separately from what
#' an agent may see:
#' * `"default"`: built and engine tables, and the columns of raw tables
#'   that aesthetics, facets or the row key refer to;
#' * `"all"`: every table in full;
#' * `"summary"`: a per-column summary of each table, no rows;
#' * `"none"`: table names and keys only, and no column summaries in the
#'   context either.
#'
#' @param fig A `gloss_figure`.
#' @param path A directory (no extension, or `.gloss`), or a file ending in
#'   `.html` or `.svg`.
#' @param embed Which data to embed; see Details.
#' @param overwrite Replace an existing file or directory.
#' @return `path`, invisibly.
#' @examples
#' fig <- gloss(grid::rectGrob(), width = 2, height = 2, context = FALSE)
#' f <- tempfile(fileext = ".html")
#' gl_write(fig, f)
#' identical(gl_read(f)$substrate$elements, fig$substrate$elements)
#' @export
gl_write <- function(fig, path, embed = c("default", "all", "summary", "none"), overwrite = TRUE) {
  check_figure(fig)
  embed <- match.arg(embed)
  ext <- tolower(tools::file_ext(path))
  if (ext %in% c("", "gloss")) {
    write_bundle_dir(bundle_files(fig, embed), path, overwrite)
    return(invisible(path))
  }
  proj <- projection_for(ext)
  if (file.exists(path) && !overwrite) cli::cli_abort("{.path {path}} exists; use {.code overwrite = TRUE}.")
  proj$write(fig, path, embed = embed)
  invisible(path)
}

check_figure <- function(fig) {
  if (!inherits(fig, "gloss_figure")) cli::cli_abort("{.arg fig} must be a {.cls gloss_figure}.")
}

projection_for <- function(ext) {
  for (p in rev(plugins_of("projection"))) if (ext %in% p$formats) return(p)
  cli::cli_abort("No projection plugin writes {.val .{ext}} files.")
}

write_bundle_dir <- function(files, path, overwrite = TRUE) {
  if (file.exists(path) && !dir.exists(path)) {
    cli::cli_abort("{.path {path}} is a file; a bundle directory cannot replace it.")
  }
  if (dir.exists(path)) {
    if (!overwrite) cli::cli_abort("{.path {path}} exists; use {.code overwrite = TRUE}.")
    if (!file.exists(file.path(path, "manifest.json")) && length(list.files(path, all.files = TRUE, no.. = TRUE))) {
      cli::cli_abort("{.path {path}} is a non-empty directory that is not a gloss bundle; refusing to overwrite it.")
    }
    unlink(path, recursive = TRUE)
  }
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  for (d in c("layers", "projections", "substrate/tables")) {
    dir.create(file.path(path, d), recursive = TRUE, showWarnings = FALSE)
  }
  for (nm in names(files)) {
    f <- file.path(path, nm)
    dir.create(dirname(f), recursive = TRUE, showWarnings = FALSE)
    writeBin(files[[nm]], f)
  }
  invisible(path)
}

# ---- encoding a figure as files --------------------------------------------

as_bytes <- function(s) charToRaw(enc2utf8(s))

bundle_files <- function(fig, embed = "default") {
  files <- list()
  sub <- fig$substrate

  scene <- gsub("gloss-raster:(L[0-9]+)", "raster/\\1.png", sub$scene)
  files[["substrate/scene.svg"]] <- as_bytes(scene)
  for (id in names(sub$rasters)) {
    files[[sprintf("substrate/raster/%s.png", id)]] <- sub$rasters[[id]]
  }

  dense_ids <- sub$leaves$id[sub$leaves$dense %in% TRUE]
  el <- sub$elements
  in_dense <- !is.na(el$leaf) & el$leaf %in% dense_ids
  dense_desc <- list()
  if (any(in_dense)) {
    idx <- encode_dense_index(el, dense_ids)
    files[["substrate/index.bin"]] <- idx$bytes
    dense_desc <- idx$descriptors
  }
  elements_doc <- list(
    leaves = sub$leaves,
    elements = el[!in_dense, , drop = FALSE],
    element_rows = which(!in_dense),
    n_elements = nrow(el),
    panels = sub$panels,
    dense = dense_desc
  )
  files[["substrate/elements.json"]] <- as_bytes(json_write(elements_doc, pretty = FALSE))

  tab_files <- encode_tables(fig$tables, embed)
  files <- c(files, tab_files)

  ctx <- fig$context
  if (identical(embed, "none") && !is.null(ctx$data$value$tables)) {
    ctx$data$value$tables <- lapply(ctx$data$value$tables, function(t) {
      t$columns <- NULL
      t
    })
  }
  files[["context.json"]] <- as_bytes(json_write(ctx))

  manifest <- list(
    format = "gloss-bundle",
    format_version = bundle_format_version,
    gloss_version = fig$meta$gloss %||% gloss_version(),
    api_version = gloss_api_version,
    substrate_id = fig$meta$id %||% NA_character_,
    engine = fig$meta$engine %||% NA_character_,
    embed = embed,
    meta = lapply(fig$meta, encode_vector),
    plugins = fig$plugins %||% data.frame(),
    status = fig$status,
    tables = as.list(names(fig$tables)),
    layers = list(),
    files = lapply(sort(names(files)), function(nm) {
      list(path = nm, bytes = length(files[[nm]]),
           sha256 = digest::digest(files[[nm]], algo = "sha256", serialize = FALSE))
    })
  )
  files[["manifest.json"]] <- as_bytes(json_write(manifest))
  files[sort(names(files))]
}

encode_dense_index <- function(el, dense_ids) {
  tags <- prim_tags
  chunks <- list()
  descriptors <- list()
  for (id in dense_ids) {
    rows <- which(el$leaf %in% id)
    e <- el[rows, , drop = FALSE]
    styles <- unique(data.frame(fill = e$fill, stroke = e$stroke, stringsAsFactors = FALSE))
    rownames(styles) <- NULL
    style_code <- match(paste(e$fill, e$stroke, sep = "\u001f"), paste(styles$fill, styles$stroke, sep = "\u001f"))
    to_int <- function(v) as.integer(round(v * 100))
    cols <- list(to_int(e$x0), to_int(e$y0), to_int(e$x1 - e$x0), to_int(e$y1 - e$y0),
                 match(e$tag, tags), style_code)
    chunks[[id]] <- unlist(lapply(cols, function(v) byte_shuffle(writeBin(v, raw(), size = 4L, endian = "little"), 4L)))
    descriptors[[length(descriptors) + 1L]] <- list(
      leaf = id, n = length(rows), first = rows[1], first_id = e$id[1],
      columns = c("x0", "y0", "width", "height", "tag", "style"),
      encoding = "int32 little-endian, byte-shuffled per column, zlib over the whole file",
      unit = "1/100 pt", tags = tags, styles = styles
    )
  }
  list(bytes = memCompress(unlist(chunks, use.names = FALSE), type = "gzip"), descriptors = descriptors)
}

decode_dense_index <- function(bytes, descriptors) {
  raw <- memDecompress(bytes, type = "gzip")
  pos <- 0L
  out <- list()
  for (d in descriptors) {
    n <- as.integer(d$n)
    # six int32 columns of n values each, one after the other
    read_col <- function(k) {
      readBin(byte_unshuffle(raw[pos + 4L * n * (k - 1L) + seq_len(4L * n)], 4L),
              "integer", n = n, size = 4L, endian = "little")
    }
    x0 <- read_col(1L); y0 <- read_col(2L); w <- read_col(3L); h <- read_col(4L)
    tag <- read_col(5L); style <- read_col(6L)
    pos <- pos + 24L * n
    first <- as.integer(sub("^e", "", d$first_id))
    styles <- d$styles
    out[[d$leaf]] <- data.frame(
      id = paste0("e", first + seq_len(n) - 1L),
      leaf = d$leaf,
      tag = d$tags[tag],
      ordinal = seq_len(n),
      x0 = x0 / 100, y0 = y0 / 100, x1 = (x0 + w) / 100, y1 = (y0 + h) / 100,
      fill = styles$fill[style], stroke = styles$stroke[style],
      text = NA_character_,
      stringsAsFactors = FALSE
    )
  }
  out
}

table_file <- function(name) sprintf("substrate/tables/%s.json", name)

table_meta_fields <- c("name", "role", "layer", "description", "referenced", "key", "key_rule",
                       "key_basis", "key_fragile", "key_history", "status")

encode_tables <- function(tables, embed) {
  files <- list()
  # Raw-table columns, for storing identical columns of other tables once.
  raw_cols <- list()
  for (t in tables) {
    if (!identical(t$role, "raw") || is.null(t$data)) next
    keep <- embedded_columns(t, embed)
    for (cn in keep) {
      v <- t$data[[cn]]
      if (length(v) >= 100L) {
        h <- digest::digest(v, algo = "xxhash64")
        if (is.null(raw_cols[[h]])) raw_cols[[h]] <- list(table = t$name, column = cn)
      }
    }
  }
  for (t in tables) {
    meta <- t[table_meta_fields]
    meta$layer <- as.integer(meta$layer)
    meta$key_rule <- as.integer(meta$key_rule)
    meta$referenced <- as.list(meta$referenced)
    meta$key <- as.list(meta$key)
    data <- t$data
    if (is.null(data) || embed %in% c("summary", "none")) {
      meta$embedded <- if (is.null(data)) "none" else embed
      if (!is.null(data) && identical(embed, "summary")) meta$summary <- table_summary(data)
      if (!is.null(data)) {
        meta$nrow <- nrow(data)
        meta$columns <- as.list(names(data))
      }
      files[[table_file(t$name)]] <- as_bytes(json_write(list(table = meta), pretty = FALSE))
      next
    }
    keep <- embedded_columns(t, embed)
    dropped <- setdiff(names(data), keep)
    meta$embedded <- if (length(dropped)) "columns" else "all"
    if (length(dropped)) meta$dropped <- as.list(dropped)
    data <- data[keep]
    refs <- list()
    if (!identical(t$role, "raw")) {
      for (cn in names(data)) {
        v <- data[[cn]]
        if (length(v) < 100L) next
        h <- digest::digest(v, algo = "xxhash64")
        r <- raw_cols[[h]]
        if (!is.null(r) && identical(v, tables[[r$table]]$data[[r$column]])) refs[[cn]] <- r
      }
    }
    files[[table_file(t$name)]] <- as_bytes(df_to_json(data, meta = list(table = meta), refs = refs))
  }
  files
}

embedded_columns <- function(t, embed) {
  data <- t$data
  if (!identical(embed, "default") || !identical(t$role, "raw")) return(names(data))
  keys <- setdiff(t$key, c(key_rownames, key_hash))
  keep <- intersect(names(data), unique(c(t$referenced, keys)))
  if (identical(t$key, key_hash)) keep <- names(data)
  keep
}

# ---- reading ---------------------------------------------------------------

#' Read a figure
#'
#' Restores a `gloss_figure` from a bundle directory or a single HTML or SVG
#' file written by [gl_write()]. Whatever is present is restored:
#' * a complete bundle gives the complete figure;
#' * tables written without data come back with status `missing_data`;
#' * plugins named in the manifest but not installed are listed in
#'   `fig$status$missing_plugins`, and everything else is restored;
#' * an SVG without an embedded bundle gives geometry only: its elements,
#'   with no leaves, panels or tables.
#'
#' @param path A bundle directory, or an `.html` or `.svg` file.
#' @return A `gloss_figure`.
#' @export
gl_read <- function(path) {
  if (dir.exists(path)) return(figure_from_files(read_bundle_dir(path)))
  if (!file.exists(path)) cli::cli_abort("{.path {path}} does not exist.")
  txt <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  payload <- extract_embedded(txt)
  if (!is.null(payload)) return(figure_from_files(unpack_files(payload)))
  svg_at <- regexpr("<svg[ >]", txt)
  if (svg_at > 0) {
    end <- max(gregexpr("</svg>", txt, fixed = TRUE)[[1]])
    if (end > 0) return(figure_from_plain_svg(substring(txt, svg_at, end + 5L)))
  }
  cli::cli_abort("{.path {path}} has no embedded gloss bundle and no SVG to read geometry from.")
}

read_bundle_dir <- function(path) {
  rel <- list.files(path, recursive = TRUE, all.files = FALSE)
  files <- lapply(rel, function(r) {
    f <- file.path(path, r)
    readBin(f, "raw", file.size(f))
  })
  names(files) <- rel
  files[sort(names(files))]
}

bytes_text <- function(b) {
  s <- rawToChar(b)
  Encoding(s) <- "UTF-8"
  s
}

figure_from_files <- function(files) {
  need <- c("manifest.json", "substrate/scene.svg", "substrate/elements.json")
  miss <- setdiff(need, names(files))
  if (length(miss)) cli::cli_abort("Not a gloss bundle: missing {.file {miss}}.")
  man <- json_read(bytes_text(files[["manifest.json"]]))
  if (!identical(man$format, "gloss-bundle")) cli::cli_abort("Not a gloss bundle (format {.val {man$format}}).")
  fv <- package_version(man$format_version)
  if (fv$major != package_version(bundle_format_version)$major) {
    cli::cli_abort("Bundle format {man$format_version} cannot be read by this gloss (format {bundle_format_version}).")
  }
  status <- man$status %||% list()
  if (!is.list(status)) status <- list()

  bad <- character()
  for (f in man$files) {
    b <- files[[f$path]]
    if (is.null(b) || !identical(digest::digest(b, algo = "sha256", serialize = FALSE), f$sha256)) {
      bad <- c(bad, f$path)
    }
  }
  if (length(bad)) status$integrity <- bad

  meta <- lapply(man$meta, decode_vector)

  el_doc <- json_read(bytes_text(files[["substrate/elements.json"]]))
  elements <- el_doc$elements
  if (length(el_doc$dense)) {
    dense <- decode_dense_index(files[["substrate/index.bin"]], el_doc$dense)
    n <- as.integer(el_doc$n_elements)
    full <- elements[rep(NA_integer_, n), , drop = FALSE]
    rownames(full) <- NULL
    full[as.integer(el_doc$element_rows), ] <- elements
    for (d in el_doc$dense) {
      rows <- as.integer(d$first) + seq_len(as.integer(d$n)) - 1L
      full[rows, ] <- dense[[d$leaf]]
    }
    elements <- full
  }

  rasters <- list()
  for (nm in grep("^substrate/raster/.*\\.png$", names(files), value = TRUE)) {
    rasters[[sub("^substrate/raster/(.*)\\.png$", "\\1", nm)]] <- files[[nm]]
  }
  scene <- gsub("raster/(L[0-9]+)\\.png", "gloss-raster:\\1", bytes_text(files[["substrate/scene.svg"]]))

  tables <- decode_tables(files)
  order <- as.character(unlist(man$tables) %||% character())
  if (length(order) && setequal(order, names(tables))) tables <- tables[order]
  missing_data <- names(tables)[vapply(tables, function(t) identical(t$status, "missing_data"), logical(1))]
  if (length(missing_data)) status$missing_data <- missing_data
  partial <- names(tables)[vapply(tables, function(t) identical(t$status, "partial_data"), logical(1))]
  if (length(partial)) status$partial_data <- partial

  plugins <- man$plugins
  if (is.data.frame(plugins) && nrow(plugins)) {
    have <- vapply(seq_len(nrow(plugins)), function(i) {
      !is.null(gl_plugin(plugins$kind[i], plugins$name[i], must_exist = FALSE))
    }, logical(1))
    if (any(!have)) status$missing_plugins <- plugins[!have, , drop = FALSE]
  }

  context <- if (!is.null(files[["context.json"]])) json_read(bytes_text(files[["context.json"]])) else list()
  if (is.null(context) || !length(context)) context <- list()

  fig <- new_figure(
    meta = meta,
    substrate = list(scene = scene, leaves = el_doc$leaves, elements = elements,
                     panels = el_doc$panels, rasters = rasters),
    tables = tables,
    context = context,
    plugins = plugins
  )
  fig$status <- status
  fig
}

decode_tables <- function(files) {
  paths <- grep("^substrate/tables/.*\\.json$", names(files), value = TRUE)
  parsed <- lapply(paths, function(p) {
    jsonlite::parse_json(bytes_text(files[[p]]), simplifyVector = TRUE,
                         simplifyDataFrame = FALSE, simplifyMatrix = FALSE)
  })
  metas <- lapply(parsed, function(o) json_unprep(o$table))
  names(parsed) <- vapply(metas, `[[`, "", "name")
  names(metas) <- names(parsed)
  out <- list()
  # Raw tables first: other tables may refer to their columns.
  order_idx <- order(vapply(metas, function(m) !identical(m$role, "raw"), logical(1)))
  for (nm in names(parsed)[order_idx]) {
    o <- parsed[[nm]]
    m <- metas[[nm]]
    data <- NULL
    if (!is.null(o$columns)) {
      resolve <- function(ref) {
        src <- out[[ref$table]]$data
        if (is.null(src) || is.null(src[[ref$column]])) {
          cli::cli_abort("Table {.val {nm}} refers to {.val {ref$table}}${ref$column}, which is not in the bundle.")
        }
        src[[ref$column]]
      }
      data <- decode_df(o, resolve = resolve)
    }
    status <- m$status %||% "ok"
    if (is.null(data)) status <- "missing_data"
    else if (identical(m$embedded, "columns")) status <- "partial_data"
    hist <- m$key_history
    if (!is.data.frame(hist)) hist <- empty_key_history()
    out[[nm]] <- list(
      name = m$name, role = m$role, layer = as.integer(m$layer %||% NA_integer_),
      description = m$description %||% NA_character_,
      referenced = as.character(unlist(m$referenced) %||% character()),
      data = data,
      key = as.character(unlist(m$key) %||% character()),
      key_rule = as.integer(m$key_rule %||% NA_integer_),
      key_basis = m$key_basis %||% NA_character_,
      key_fragile = isTRUE(m$key_fragile),
      key_history = hist,
      status = status
    )
    if (!is.null(m$summary)) out[[nm]]$summary <- m$summary
    if (!is.null(m$dropped)) out[[nm]]$dropped <- as.character(unlist(m$dropped))
  }
  out[names(parsed)]
}

# ---- single-file packing ----------------------------------------------------

u32 <- function(n) {
  as.raw(c((n %/% 16777216) %% 256, (n %/% 65536) %% 256, (n %/% 256) %% 256, n %% 256))
}

read_u32 <- function(b) sum(as.integer(b) * c(16777216, 65536, 256, 1))

# base64 on one line (jsonlite wraps at 76 characters).
base64_line <- function(b) gsub("[\r\n]", "", jsonlite::base64_enc(b))

# Files packed as [u32 path length][path][u32 content length][content],
# sorted by path, compressed with zlib and encoded in base64.
pack_files <- function(files) {
  parts <- lapply(sort(names(files)), function(nm) {
    p <- charToRaw(enc2utf8(nm))
    b <- files[[nm]]
    c(u32(length(p)), p, u32(length(b)), b)
  })
  base64_line(memCompress(unlist(parts, use.names = FALSE), type = "gzip"))
}

unpack_files <- function(payload) {
  raw <- memDecompress(jsonlite::base64_dec(payload), type = "gzip")
  out <- list()
  pos <- 0L
  n <- length(raw)
  while (pos < n) {
    lp <- read_u32(raw[pos + 1:4]); pos <- pos + 4L
    nm <- bytes_text(raw[pos + seq_len(lp)]); pos <- pos + lp
    lb <- read_u32(raw[pos + 1:4]); pos <- pos + 4L
    out[[nm]] <- raw[pos + seq_len(lb)]; pos <- pos + lb
  }
  out
}

embed_script <- function(fig, embed) {
  payload <- pack_files(bundle_files(fig, embed))
  header <- list(format = "gloss-bundle-embed", format_version = bundle_format_version,
                 encoding = "zlib+base64", packing = "u32-length-prefixed files",
                 embed = embed)
  body <- sub("}\\s*$", "", json_write(header, pretty = FALSE))
  sprintf("<script type=\"application/json\" id=\"gloss-bundle\">%s,\"payload\":\"%s\"}</script>",
          body, payload)
}

extract_embedded <- function(txt) {
  m <- regexpr("<script[^>]*id=\"gloss-bundle\"[^>]*>", txt)
  if (m < 0) return(NULL)
  start <- m + attr(m, "match.length")
  rest <- substring(txt, start, nchar(txt))
  end <- regexpr("</script>", rest, fixed = TRUE)
  if (end < 0) return(NULL)
  obj <- jsonlite::parse_json(substring(rest, 1, end - 1))
  if (!identical(obj$format, "gloss-bundle-embed")) return(NULL)
  obj$payload
}

# Scene with rasters as data URIs, without the XML declaration.
scene_for_projection <- function(fig) {
  s <- fig$substrate$scene
  s <- sub("^<\\?xml[^>]*>\\s*", "", s)
  for (id in names(fig$substrate$rasters)) {
    uri <- paste0("data:image/png;base64,", base64_line(fig$substrate$rasters[[id]]))
    s <- sub(paste0("gloss-raster:", id, "\""), paste0(uri, "\""), s, fixed = TRUE)
  }
  s
}

# ---- plain SVG --------------------------------------------------------------

figure_from_plain_svg <- function(txt) {
  doc <- xml2::read_xml(txt)
  ns <- svg_ns(doc)
  if (!length(xml2::xml_ns(doc))) {
    doc <- xml2::read_xml(sub("<svg", "<svg xmlns=\"http://www.w3.org/2000/svg\"", txt, fixed = TRUE))
  }
  elements <- elements_table(doc, ns)
  root <- xml2::xml_root(doc)
  dim_in <- function(a) {
    v <- xml2::xml_attr(root, a)
    num <- suppressWarnings(as.numeric(sub("(pt|px)$", "", v)))
    if (is.na(num)) return(NA_real_)
    if (grepl("px$", v)) num * 0.75 / pt_per_in else num / pt_per_in
  }
  leaves <- data.frame(id = character(), name = character(), path = character(), class = character(),
                       vp = character(), x0 = double(), y0 = double(), x1 = double(), y1 = double(),
                       xscale0 = double(), xscale1 = double(), yscale0 = double(), yscale1 = double(),
                       n_expected = integer(), n_drawn = integer(), status = character(),
                       bindable = logical(), dense = logical(), panel = character(),
                       stringsAsFactors = FALSE)
  fig <- new_figure(
    meta = list(engine = NA_character_, width = dim_in("width"), height = dim_in("height"),
                created = NA_character_),
    substrate = list(scene = as.character(doc), leaves = leaves, elements = elements,
                     panels = empty_panels(), rasters = list()),
    tables = list(), context = list(), plugins = NULL
  )
  fig$status <- list(restored = "geometry only: the SVG has no embedded gloss bundle")
  fig
}
