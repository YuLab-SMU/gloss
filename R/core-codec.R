# Lossless JSON for the bundle.
#
# Doubles are written with the shortest of 15 or 17 significant digits that
# parses back to the same value, and always with a decimal point or exponent
# so they read back as doubles. Vectors keep their type and attributes
# (factor levels, Date and POSIXct classes, time zones); NaN, Inf and -Inf,
# which JSON cannot express, are listed by position. Data frames are stored
# column by column.

json_verbatim <- function(s) structure(s, class = "json")

# JSON tokens for a double vector; non-finite values become null (the
# caller records NaN and +/-Inf separately).
num_tokens <- function(x) {
  out <- rep("null", length(x))
  ok <- is.finite(x)
  if (!any(ok)) return(out)
  v <- x[ok]
  s <- sprintf("%.15g", v)
  back <- jsonlite::parse_json(paste0("[", paste(s, collapse = ","), "]"), simplifyVector = TRUE)
  redo <- which(as.double(back) != v)
  if (length(redo)) s[redo] <- sprintf("%.17g", v[redo])
  plain <- !grepl("[.eE]", s)
  s[plain] <- paste0(s[plain], ".0")
  out[ok] <- s
  out
}

json_array <- function(tokens) json_verbatim(paste0("[", paste(tokens, collapse = ","), "]"))

# Numeric vectors at least this long are stored as little-endian binary in
# base64 instead of decimal text: exact, and smaller once compressed.
binary_min_length <- 10000L

# Byte-plane shuffle: all first bytes, then all second bytes, and so on.
# Sign and exponent bytes vary little, so zlib compresses the planes far
# better than interleaved values (the filter used by Blosc and HDF5).
byte_shuffle <- function(bytes, size) as.vector(t(matrix(bytes, nrow = size)))
byte_unshuffle <- function(bytes, size) as.vector(t(matrix(bytes, ncol = size)))

encode_binary <- function(y, what) {
  size <- if (identical(what, "double")) 8L else 4L
  bytes <- byte_shuffle(writeBin(y, raw(), size = size, endian = "little"), size)
  gsub("[\r\n]", "", jsonlite::base64_enc(bytes))
}

# Encode an atomic vector (or a list of atomic vectors) with its type.
encode_vector <- function(x) {
  attrs <- attributes(x)
  attrs$names <- NULL
  enc <- list(type = typeof(x))
  if (is.list(x)) {
    enc$type <- "list"
    enc$values <- lapply(unclass(x), function(el) {
      if (is.null(el)) return(NULL)
      if (!is.atomic(el)) cli::cli_abort("Only lists of atomic vectors can be stored, not {.cls {class(el)}}.")
      encode_vector(el)
    })
    attrs$class <- setdiff(attrs$class, "list")
    if (!length(attrs$class)) attrs$class <- NULL
  } else {
    y <- unclass(x)
    attributes(y) <- NULL
    binary <- typeof(x) %in% c("double", "integer") && length(y) >= binary_min_length
    if (binary) {
      enc$encoding <- if (is.double(y)) "f64le-shuffle-base64" else "i32le-shuffle-base64"
      enc$length <- length(y)
      enc$values <- encode_binary(y, typeof(x))
    } else enc$values <- switch(typeof(x),
      double = {
        sp <- list(`NaN` = which(is.nan(y)), `Inf` = which(y == Inf), `-Inf` = which(y == -Inf))
        sp <- sp[lengths(sp) > 0L]
        if (length(sp)) enc$specials <- lapply(sp, function(i) json_array(as.character(i)))
        json_array(num_tokens(y))
      },
      integer = json_array(ifelse(is.na(y), "null", as.character(y))),
      logical = json_array(ifelse(is.na(y), "null", ifelse(y, "true", "false"))),
      character = json_verbatim(as.character(jsonlite::toJSON(enc2utf8(y), na = "null"))),
      cli::cli_abort("Cannot store a vector of type {.val {typeof(x)}}.")
    )
  }
  if (length(attrs)) enc$attrs <- lapply(attrs, encode_vector)
  if (!is.null(names(x))) enc$names <- encode_vector(names(x))
  enc
}

decode_vector <- function(enc) {
  type <- enc$type
  n_vals <- function(v) if (is.list(v) && !length(v)) NULL else v
  enc_bin <- enc[["encoding"]]
  if (!is.null(enc_bin)) {
    n <- as.integer(enc[["length"]])
    size <- if (identical(enc_bin, "f64le-shuffle-base64")) 8L else 4L
    bytes <- byte_unshuffle(jsonlite::base64_dec(enc$values), size)
    x <- readBin(bytes, if (size == 8L) "double" else "integer", n = n, size = size, endian = "little")
  } else x <- switch(type,
    double = {
      v <- as.double(n_vals(enc$values) %||% double())
      for (nm in names(enc$specials)) {
        idx <- as.integer(enc$specials[[nm]])
        v[idx] <- switch(nm, `NaN` = NaN, `Inf` = Inf, `-Inf` = -Inf)
      }
      v
    },
    integer = as.integer(n_vals(enc$values) %||% integer()),
    logical = as.logical(n_vals(enc$values) %||% logical()),
    character = as.character(n_vals(enc$values) %||% character()),
    list = {
      vals <- enc$values
      if (!is.list(vals)) vals <- vector("list", length(vals))
      lapply(vals, function(el) if (is.null(el)) NULL else decode_vector(el))
    },
    cli::cli_abort("Unknown stored vector type {.val {type}}.")
  )
  if (length(enc$attrs)) {
    attrs <- lapply(enc$attrs, decode_vector)
    if (identical(type, "list") && !is.null(attrs$class)) attrs$class <- c(attrs$class, "list")
    attributes(x) <- c(attributes(x), attrs)
  }
  if (!is.null(enc$names)) names(x) <- decode_vector(enc$names)
  x
}

# Data frames: column-oriented, with row names when they are not automatic.
# `refs` maps column names to list(table =, column =): such columns are
# stored as a reference to an identical column of another table.
encode_df <- function(df, refs = list()) {
  out <- list(
    nrow = nrow(df),
    class = class(df),
    names = encode_vector(names(df))
  )
  if (.row_names_info(df, type = 1L) > 0L) out$rownames <- encode_vector(.row_names_info(df, type = 0L))
  out$columns <- lapply(names(df), function(cn) {
    if (!is.null(refs[[cn]])) return(list(ref = refs[[cn]]))
    encode_vector(df[[cn]])
  })
  extra <- attributes(df)
  extra[c("names", "row.names", "class")] <- NULL
  if (length(extra)) out$attrs <- lapply(extra, encode_vector)
  out
}

decode_df <- function(enc, resolve = NULL) {
  cols <- lapply(enc$columns, function(col) {
    if (!is.null(col$ref)) {
      if (is.null(resolve)) cli::cli_abort("A stored column refers to another table that is not available.")
      return(resolve(col$ref))
    }
    decode_vector(col)
  })
  nms <- decode_vector(enc$names)
  names(cols) <- nms
  n <- as.integer(enc$nrow)
  rn <- if (!is.null(enc$rownames)) decode_vector(enc$rownames) else .set_row_names(n)
  df <- structure(cols, names = nms, row.names = rn, class = as.character(enc$class))
  if (length(enc$attrs)) {
    for (nm in names(enc$attrs)) attr(df, nm) <- decode_vector(enc$attrs[[nm]])
  }
  df
}

# Convert an R value into something jsonlite writes losslessly.
json_prep <- function(x) {
  if (is.null(x)) return(NULL)
  if (inherits(x, "json")) return(x)
  if (is.data.frame(x)) return(list(`__df__` = encode_df(x)))
  if (is.factor(x)) x <- as.character(x)
  if (is.atomic(x) && !is.null(names(x))) x <- as.list(x)
  if (is.list(x)) {
    out <- lapply(x, json_prep)
    if (!is.null(names(x))) names(out) <- names(x)
    return(out)
  }
  if (is.double(x)) {
    tok <- num_tokens(x)
    tok[is.nan(x)] <- "\"NaN\""
    tok[x %in% Inf] <- "\"Inf\""
    tok[x %in% -Inf] <- "\"-Inf\""
    if (length(x) == 1L) return(json_verbatim(tok))
    return(json_array(tok))
  }
  x
}

json_write <- function(x, pretty = TRUE) {
  s <- jsonlite::toJSON(json_prep(x), auto_unbox = TRUE, null = "null", na = "null",
                        json_verbatim = TRUE, pretty = pretty, digits = NA)
  paste0(as.character(s), "\n")
}

json_unprep <- function(x) {
  if (is.list(x)) {
    if (length(x) == 1L && identical(names(x), "__df__")) return(decode_df(x[[1]]))
    nms <- names(x)
    out <- lapply(x, json_unprep)
    names(out) <- nms
    return(out)
  }
  x
}

json_read <- function(txt) {
  if (!length(txt) || !nzchar(paste(txt, collapse = ""))) return(NULL)
  json_unprep(jsonlite::parse_json(paste(txt, collapse = "\n"), simplifyVector = TRUE,
                                   simplifyDataFrame = FALSE, simplifyMatrix = FALSE))
}

# A data frame as a JSON document, one column per line so that diffs of the
# directory form stay readable.
df_to_json <- function(df, meta = list(), refs = list()) {
  enc <- encode_df(df, refs)
  cols <- vapply(enc$columns, function(col) {
    as.character(jsonlite::toJSON(col, auto_unbox = TRUE, null = "null", na = "null",
                                  json_verbatim = TRUE, digits = NA))
  }, character(1))
  enc$columns <- NULL
  head <- jsonlite::toJSON(c(json_prep(meta), enc), auto_unbox = TRUE, null = "null",
                           na = "null", json_verbatim = TRUE, digits = NA)
  head <- sub("}$", "", as.character(head))
  sep <- if (identical(head, "{")) "" else ","
  paste0(head, sep, "\"columns\":[\n", paste(cols, collapse = ",\n"), "\n]}\n")
}

df_from_json <- function(txt, resolve = NULL) {
  obj <- jsonlite::parse_json(paste(txt, collapse = "\n"), simplifyVector = TRUE,
                              simplifyDataFrame = FALSE, simplifyMatrix = FALSE)
  meta <- obj[setdiff(names(obj), c("nrow", "class", "names", "rownames", "columns", "attrs"))]
  list(data = decode_df(obj, resolve), meta = json_unprep(meta))
}
