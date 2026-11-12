# Context sniffer: plotting code. Sources, in order: the knitr chunk being
# run, a script file being sourced or run with Rscript, srcrefs on the call
# stack. The gloss() call itself is always recorded.

register_context_code <- function() {
  gl_register("context", name = "code", version = "0.1.0", package = "gloss",
              description = "plotting code: call, knitr chunk, script file, srcref",
              item = "code", sniff = sniff_code)
}

sniff_code <- function(input) {
  v <- list()
  if (!is.null(input$call)) v$call <- deparse_one(input$call)
  if (!is.null(input$expr)) v$expr <- deparse_one(input$expr)
  if (in_knitr()) {
    code <- knitr::opts_current$get("code")
    if (length(code)) {
      v$chunk <- list(label = knitr::opts_current$get("label") %||% NA_character_,
                      code = paste(code, collapse = "\n"))
    }
  }
  path <- script_path()
  if (!is.null(path)) {
    v$script <- list(path = path, md5 = unname(tools::md5sum(path)),
                     code = paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n"))
  }
  text <- v$chunk$code %||% v$script$code
  if (!is.null(text) && is.symbol(input$expr)) {
    defs <- find_definitions(text, as.character(input$expr))
    if (length(defs)) v$definition <- defs
  }
  if (is.null(text)) {
    return(list(found = FALSE, value = v,
                reason = "no knitr chunk, sourced script or srcref found; only the gloss() call is known"))
  }
  list(found = TRUE, value = v)
}

# The script being run: a source()d file, a srcref on the call stack, or
# Rscript's --file argument.
script_path <- function() {
  frames <- sys.frames()
  for (f in rev(frames)) {
    of <- tryCatch(get("ofile", envir = f, inherits = FALSE), error = function(e) NULL)
    if (is_string(of) && file.exists(of)) return(normalizePath(of))
  }
  for (cl in rev(sys.calls())) {
    sr <- attr(cl, "srcref")
    if (!is.null(sr)) {
      fn <- tryCatch(utils::getSrcFilename(sr, full.names = TRUE), error = function(e) character())
      if (length(fn) && nzchar(fn) && file.exists(fn)) return(normalizePath(fn))
    }
  }
  args <- commandArgs(trailingOnly = FALSE)
  f <- sub("^--file=", "", grep("^--file=", args, value = TRUE))
  if (length(f) && file.exists(f[1])) return(normalizePath(f[1]))
  NULL
}

# Top-level assignments to `name` in `text`.
find_definitions <- function(text, name) {
  exprs <- tryCatch(parse(text = text, keep.source = FALSE), error = function(e) NULL)
  if (is.null(exprs)) return(character())
  out <- character()
  for (e in as.list(exprs)) {
    if (is.call(e) && as.character(e[[1]]) %in% c("<-", "=", "<<-") &&
        identical(e[[2]], as.symbol(name))) {
      out <- c(out, deparse_one(e))
    }
  }
  out
}
