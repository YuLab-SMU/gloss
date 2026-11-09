# Context sniffer: data. Object names used as plot data in the code, source
# files the code reads (path and md5), and a summary of every table with
# its row key and the basis for it.

register_context_data <- function() {
  gl_register("context", name = "data", version = "0.1.0", package = "gloss",
              description = "data: object names, source files, column summaries, row keys",
              item = "data", sniff = sniff_data)
}

read_functions <- c("read.csv", "read.csv2", "read.table", "read.delim", "readRDS", "load",
                    "read_csv", "read_tsv", "read_delim", "read_excel", "read_xlsx", "fread",
                    "read_parquet", "read_feather", "read.xlsx", "read_sav", "read_dta")

sniff_data <- function(input) {
  v <- list()
  code <- input$context$code$value
  text <- code$chunk$code %||% code$script$code
  if (!is.null(text)) {
    found <- scan_code_for_data(text, input$env, base_dir = dirname(code$script$path %||% "."))
    if (length(found$objects)) v$objects <- found$objects
    if (length(found$files)) v$files <- found$files
  }
  if (length(input$tables)) {
    v$tables <- lapply(input$tables, function(t) {
      list(name = t$name, role = t$role, nrow = if (is.null(t$data)) NA_integer_ else nrow(t$data),
           key = t$key, key_rule = t$key_rule, key_basis = t$key_basis,
           key_fragile = t$key_fragile,
           columns = if (is.null(t$data)) NULL else table_summary(t$data))
    })
    names(v$tables) <- NULL
  }
  if (!length(v)) {
    return(list(found = FALSE, reason = "the engine provides no data tables and no data was found in the code"))
  }
  list(found = TRUE, value = v)
}

scan_code_for_data <- function(text, env, base_dir = ".") {
  exprs <- tryCatch(parse(text = text, keep.source = FALSE), error = function(e) NULL)
  objects <- character()
  files <- list()
  walk <- function(e) {
    if (!is.call(e)) return(invisible())
    fn <- e[[1]]
    fname <- if (is.symbol(fn)) as.character(fn)
             else if (is.call(fn) && identical(fn[[1]], as.symbol("::"))) as.character(fn[[3]])
             else ""
    args <- as.list(e)[-1]
    first_sym <- length(args) && is.symbol(args[[1]]) && nzchar(as.character(args[[1]]))
    if (fname %in% c("ggplot", "Heatmap", "plot", "with") && first_sym) {
      objects <<- c(objects, as.character(args[[1]]))
    }
    if ("data" %in% names(args) && is.symbol(args[["data"]])) {
      objects <<- c(objects, as.character(args[["data"]]))
    }
    if (fname %in% read_functions && length(args) && is.character(args[[1]])) {
      p <- args[[1]]
      cand <- if (file.exists(p)) p else file.path(base_dir, p)
      if (file.exists(cand)) {
        files[[length(files) + 1L]] <<- list(path = normalizePath(cand), reader = fname,
                                             md5 = unname(tools::md5sum(cand)),
                                             bytes = file.size(cand))
      } else {
        files[[length(files) + 1L]] <<- list(path = p, reader = fname, md5 = NA_character_,
                                             bytes = NA_real_)
      }
    }
    for (i in seq_along(args)) if (is.call(args[[i]])) walk(args[[i]])
  }
  for (e in as.list(exprs)) walk(e)
  objects <- unique(objects)
  if (!is.null(env)) {
    objects <- objects[vapply(objects, function(o) {
      x <- tryCatch(get(o, envir = env), error = function(e) NULL)
      is.data.frame(x) || is.matrix(x)
    }, logical(1))]
  }
  list(objects = objects, files = files)
}
