# Context sniffer: environment. R and package versions, the capture device,
# the font svglite resolves for "sans", platform and locale.

register_context_env <- function() {
  gl_register("context", name = "env", version = "0.1.0", package = "gloss",
              description = "environment: R and package versions, device, fonts, platform",
              item = "env", sniff = sniff_env)
}

sniff_env <- function(input) {
  eng <- gl_plugin("engine", input$engine %||% "", must_exist = FALSE)
  pkgs <- unique(c("gloss", "svglite", "xml2", "jsonlite", "systemfonts", eng$packages))
  versions <- lapply(pkgs, pkg_version_or_na)
  names(versions) <- pkgs
  versions <- versions[!vapply(versions, is.na, logical(1))]
  v <- list(
    r = R.version.string,
    platform = R.version$platform,
    os = paste(Sys.info()[["sysname"]], Sys.info()[["release"]]),
    locale = Sys.getlocale("LC_CTYPE"),
    packages = versions,
    device = list(name = "svglite", version = pkg_version_or_na("svglite"),
                  width = input$width, height = input$height)
  )
  if (has_pkg("systemfonts")) {
    f <- tryCatch(systemfonts::match_fonts("sans"), error = function(e) NULL)
    if (!is.null(f) && length(f$path)) {
      v$fonts <- list(sans = basename(f$path[1]))
    }
  }
  list(found = TRUE, value = v)
}
