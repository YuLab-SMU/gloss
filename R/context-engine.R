# Context sniffer: engine and extensions. The figure's class, the engine
# plugin, what the engine says about the figure, and loaded packages that
# extend the engine's packages.

register_context_engine <- function() {
  gl_register("context", name = "engine", version = "0.1.0", package = "gloss",
              description = "engine: figure class, engine plugin, loaded extension packages",
              item = "engine", sniff = sniff_engine)
}

sniff_engine <- function(input) {
  eng <- gl_plugin("engine", input$engine %||% "", must_exist = FALSE)
  v <- list(class = class(input$x), engine = input$engine %||% NA_character_,
            engine_version = eng$version %||% NA_character_)
  if (!is.null(eng$describe) && !is.null(input$state)) {
    d <- tryCatch(eng$describe(input$state), error = function(e) NULL)
    if (!is.null(d)) v$describe <- d
  }
  base_pkgs <- eng$packages %||% character()
  if (length(base_pkgs)) {
    ext <- extension_packages(base_pkgs)
    if (length(ext)) v$extensions <- ext
  }
  list(found = TRUE, value = v)
}

extension_packages <- function(base_pkgs) {
  out <- list()
  for (ns in sort(loadedNamespaces())) {
    if (ns %in% c(base_pkgs, "gloss")) next
    imp <- tryCatch(names(getNamespaceImports(ns)), error = function(e) character())
    deps <- tryCatch({
      d <- utils::packageDescription(ns, fields = "Depends")
      if (is.na(d)) character() else trimws(sub("\\(.*", "", strsplit(d, ",")[[1]]))
    }, error = function(e) character())
    if (any(base_pkgs %in% c(imp, deps))) {
      out[[length(out) + 1L]] <- list(package = ns, version = pkg_version_or_na(ns))
    }
  }
  out
}
