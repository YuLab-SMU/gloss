# Source context inventory (explicit, runtime_observed, sniffed_hint)
# and runtime session metadata.

infer_source_kind <- function(path, default = "file") {
  if (!is.character(path) || length(path) != 1L || is.na(path) || !nzchar(path)) {
    return(default)
  }
  ext <- tolower(tools::file_ext(path))
  if (ext %in% c("r", "rmd", "qmd", "rnw", "py", "js", "ts", "sh", "sql")) {
    return("code")
  }
  if (ext %in% c("md", "txt", "rst", "org", "tex", "pdf", "docx", "html", "htm")) {
    return("doc")
  }
  if (ext %in% c("csv", "tsv", "parquet", "rds", "rda", "rdata", "xlsx", "xls", "json", "feather")) {
    return("data")
  }
  default
}

normalize_source_kind <- function(kind, path = NULL) {
  if (is.null(kind) || !nzchar(kind)) {
    return(infer_source_kind(path))
  }
  k <- tolower(as.character(kind)[[1L]])
  switch(
    k,
    code = , script = , scripts = "code",
    doc = , docs = , documentation = , notes = "doc",
    data = , dataset = , datasets = , table = , tables = "data",
    runtime = "runtime",
    k
  )
}

source_bundle_subdir <- function(kind) {
  switch(
    kind,
    code = "sources/code",
    doc = "sources/docs",
    data = "sources/data",
    "sources/files"
  )
}

make_unique_bundle_path <- function(rel_path, used_paths) {
  if (!(rel_path %in% used_paths)) {
    return(rel_path)
  }
  dir_part <- dirname(rel_path)
  base_part <- basename(rel_path)
  stem <- tools::file_path_sans_ext(base_part)
  ext <- tools::file_ext(base_part)
  suffix <- if (nzchar(ext)) paste0(".", ext) else ""

  k <- 2L
  repeat {
    cand <- file.path(dir_part, paste0(stem, "_", k, suffix))
    if (!(cand %in% used_paths)) return(cand)
    k <- k + 1L
  }
}

build_file_source_entry <- function(
    path,
    source_id,
    kind = NULL,
    provenance_mode = "explicit",
    used_paths = character()) {

  path <- as.character(path)[[1L]]
  resolved_kind <- normalize_source_kind(kind, path = path)
  exists_p <- !is.na(path) && nzchar(path) && file.exists(path) && !dir.exists(path)
  readable_p <- isTRUE(exists_p) && file.access(path, 4L) == 0L

  bname <- if (!is.na(path) && nzchar(path)) basename(path) else paste0(source_id, ".txt")
  bundle_rel <- make_unique_bundle_path(
    paste0(source_bundle_subdir(resolved_kind), "/", bname),
    used_paths
  )

  bytes <- if (readable_p) as.integer(file.info(path)$size) else NA_integer_
  hash <- if (readable_p) sha256_file(path) else NA_character_

  list(
    source_id = source_id,
    kind = resolved_kind,
    provenance_mode = provenance_mode,
    found = isTRUE(exists_p),
    readable = isTRUE(readable_p),
    path = bundle_rel,
    origin_path = if (!is.na(path)) normalizePath(path, winslash = "/", mustWork = FALSE) else NA_character_,
    bytes = bytes,
    sha256 = hash,
    inline_text = NULL
  )
}

build_inline_source_entry <- function(
    text,
    source_id,
    kind = "code",
    filename = NULL,
    provenance_mode = "explicit",
    used_paths = character()) {

  txt <- enc2utf8(paste(as.character(text), collapse = "\n"))
  resolved_kind <- normalize_source_kind(kind)
  ext <- if (identical(resolved_kind, "code")) ".R" else ".txt"
  bname <- filename %||% paste0(source_id, ext)
  bundle_rel <- make_unique_bundle_path(
    paste0(source_bundle_subdir(resolved_kind), "/", bname),
    used_paths
  )

  list(
    source_id = source_id,
    kind = resolved_kind,
    provenance_mode = provenance_mode,
    found = TRUE,
    readable = TRUE,
    path = bundle_rel,
    origin_path = NA_character_,
    bytes = utf8_nbytes(txt),
    sha256 = sha256_text(txt),
    inline_text = txt
  )
}

collect_explicit_sources <- function(sources, used_paths = character()) {
  if (is.null(sources) || length(sources) == 0L) {
    return(list(entries = list(), used_paths = used_paths))
  }

  entries <- list()
  st <- new.env(parent = emptyenv())
  st$counter <- 0L
  st$used_ids <- character()
  st$used_paths <- used_paths

  alloc_id <- function(hint) {
    st$counter <- st$counter + 1L
    base_id <- if (!is.null(hint) && !is.na(hint) && nzchar(hint)) hint else paste0("source_", st$counter)
    if (!(base_id %in% st$used_ids)) {
      st$used_ids <- c(st$used_ids, base_id)
      return(base_id)
    }
    k <- 2L
    repeat {
      cand <- paste0(base_id, "_", k)
      if (!(cand %in% st$used_ids)) {
        st$used_ids <- c(st$used_ids, cand)
        return(cand)
      }
      k <- k + 1L
    }
  }

  category_names <- c("code", "script", "scripts", "doc", "docs", "documentation", "data", "dataset", "datasets")

  if (is.character(sources)) {
    nms <- names(sources)
    for (i in seq_along(sources)) {
      nm <- if (!is.null(nms) && nzchar(nms[[i]])) nms[[i]] else tools::file_path_sans_ext(basename(sources[[i]]))
      ent <- build_file_source_entry(
        path = sources[[i]],
        source_id = alloc_id(nm),
        kind = NULL,
        provenance_mode = "explicit",
        used_paths = st$used_paths
      )
      st$used_paths <- c(st$used_paths, ent$path)
      entries[[length(entries) + 1L]] <- ent
    }
    return(list(entries = entries, used_paths = st$used_paths))
  }

  if (is.list(sources)) {
    nms <- names(sources)
    for (i in seq_along(sources)) {
      key_name <- if (!is.null(nms) && nzchar(nms[[i]])) nms[[i]] else NULL
      item <- sources[[i]]

      if (is.character(item)) {
        is_cat <- !is.null(key_name) && tolower(key_name) %in% category_names
        for (j in seq_along(item)) {
          sub_nms <- names(item)
          sub_nm <- if (!is.null(sub_nms) && nzchar(sub_nms[[j]])) {
            sub_nms[[j]]
          } else if (!is_cat && length(item) == 1L && !is.null(key_name)) {
            key_name
          } else {
            tools::file_path_sans_ext(basename(item[[j]]))
          }
          ent <- build_file_source_entry(
            path = item[[j]],
            source_id = alloc_id(sub_nm),
            kind = if (is_cat) key_name else NULL,
            provenance_mode = "explicit",
            used_paths = st$used_paths
          )
          st$used_paths <- c(st$used_paths, ent$path)
          entries[[length(entries) + 1L]] <- ent
        }
      } else if (is.list(item) && (!is.null(item$path) || !is.null(item$text))) {
        sid <- alloc_id(item$source_id %||% key_name)
        ent <- if (!is.null(item$text)) {
          build_inline_source_entry(
            text = item$text,
            source_id = sid,
            kind = item$kind %||% "code",
            filename = item$filename %||% NULL,
            provenance_mode = item$provenance_mode %||% "explicit",
            used_paths = st$used_paths
          )
        } else {
          build_file_source_entry(
            path = item$path,
            source_id = sid,
            kind = item$kind %||% NULL,
            provenance_mode = item$provenance_mode %||% "explicit",
            used_paths = st$used_paths
          )
        }
        st$used_paths <- c(st$used_paths, ent$path)
        entries[[length(entries) + 1L]] <- ent
      }
    }
    return(list(entries = entries, used_paths = st$used_paths))
  }

  cli::cli_warn("Ignoring unsupported {.arg sources} specification of class {.cls {class(sources)}}.")
  list(entries = list(), used_paths = st$used_paths)
}

collect_sniffed_sources <- function(used_paths = character()) {
  entries <- list()

  # 1. knitr / Quarto active chunk hint
  if (isTRUE(getOption("knitr.in.progress")) && has_pkg("knitr")) {
    doc_in <- tryCatch(knitr::current_input(dir = TRUE), error = function(e) NULL)
    if (is.character(doc_in) && length(doc_in) == 1L && nzchar(doc_in)) {
      ent <- build_file_source_entry(
        path = doc_in,
        source_id = "knitr_document",
        kind = "code",
        provenance_mode = "sniffed_hint",
        used_paths = used_paths
      )
      used_paths <- c(used_paths, ent$path)
      entries[[length(entries) + 1L]] <- ent
    }

    chunk_label <- tryCatch(knitr::opts_current$get("label"), error = function(e) NULL)
    if (is.character(chunk_label) && length(chunk_label) == 1L && nzchar(chunk_label)) {
      chunk_code <- tryCatch(knitr::knit_code$get(chunk_label), error = function(e) NULL)
      if (is.character(chunk_code) && length(chunk_code) > 0L) {
        safe_lbl <- gsub("[^A-Za-z0-9._-]+", "_", chunk_label)
        ent <- build_inline_source_entry(
          text = chunk_code,
          source_id = paste0("knitr_chunk_", safe_lbl),
          kind = "code",
          filename = paste0(safe_lbl, ".R"),
          provenance_mode = "sniffed_hint",
          used_paths = used_paths
        )
        used_paths <- c(used_paths, ent$path)
        entries[[length(entries) + 1L]] <- ent
      }
    }
  }

  # 2. Rscript --file=<script> CLI hint
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg) > 0L) {
    script_path <- sub("^--file=", "", file_arg[[1L]])
    if (nzchar(script_path)) {
      ent <- build_file_source_entry(
        path = script_path,
        source_id = "rscript_file",
        kind = "code",
        provenance_mode = "sniffed_hint",
        used_paths = used_paths
      )
      used_paths <- c(used_paths, ent$path)
      entries[[length(entries) + 1L]] <- ent
    }
  }

  list(entries = entries, used_paths = used_paths)
}

find_git_root <- function(start_dir = getwd()) {
  cur <- normalizePath(start_dir, winslash = "/", mustWork = FALSE)
  repeat {
    if (file.exists(file.path(cur, ".git"))) {
      return(cur)
    }
    parent <- dirname(cur)
    if (identical(parent, cur)) {
      return(NULL)
    }
    cur <- parent
  }
}

collect_git_metadata <- function(start_dir = getwd()) {
  root <- find_git_root(start_dir)
  if (is.null(root)) return(NULL)
  git_bin <- Sys.which("git")
  if (!nzchar(git_bin)) return(NULL)

  run_git <- function(args) {
    out <- tryCatch(
      suppressWarnings(system2(git_bin, c("-C", root, args), stdout = TRUE, stderr = FALSE)),
      error = function(e) character()
    )
    status <- attr(out, "status")
    if (!is.null(status) && status != 0L) return(character())
    out
  }

  head_sha <- run_git(c("rev-parse", "HEAD"))
  branch <- run_git(c("rev-parse", "--abbrev-ref", "HEAD"))
  porcelain <- run_git(c("status", "--porcelain"))

  if (length(head_sha) == 0L) return(NULL)
  list(
    root = root,
    head = head_sha[[1L]],
    branch = if (length(branch) > 0L) branch[[1L]] else NA_character_,
    dirty = length(porcelain) > 0L
  )
}

collect_session_info <- function(input_obj = NULL, extra_packages = character()) {
  loaded_ns <- sort(loadedNamespaces())
  pkg_versions <- stats::setNames(
    lapply(loaded_ns, function(pkg) {
      tryCatch(as.character(utils::packageVersion(pkg)), error = function(e) NA_character_)
    }),
    loaded_ns
  )

  list(
    r_version = R.version.string,
    platform = R.version$platform,
    gloss_version = as.character(utils::packageVersion("gloss")),
    working_directory = normalizePath(getwd(), winslash = "/", mustWork = FALSE),
    captured_at = utc_timestamp(),
    input_class = if (is.null(input_obj)) list() else json_array(class(input_obj)),
    git = collect_git_metadata(),
    loaded_packages = pkg_versions
  )
}

collect_sources_inventory <- function(sources = NULL, session = NULL) {
  used_paths <- character()

  exp_res <- collect_explicit_sources(sources, used_paths = used_paths)
  used_paths <- exp_res$used_paths

  sniff_res <- collect_sniffed_sources(used_paths = used_paths)
  used_paths <- sniff_res$used_paths

  # Runtime session metadata is always recorded as runtime_observed
  sess_json <- enc2utf8(paste0(as.character(to_gloss_json(session %||% list(), pretty = TRUE)), "\n"))
  sess_entry <- list(
    source_id = "session",
    kind = "runtime",
    provenance_mode = "runtime_observed",
    found = TRUE,
    readable = TRUE,
    path = "sources/session.json",
    origin_path = NA_character_,
    bytes = utf8_nbytes(sess_json),
    sha256 = sha256_text(sess_json),
    inline_text = sess_json
  )

  c(exp_res$entries, sniff_res$entries, list(sess_entry))
}
