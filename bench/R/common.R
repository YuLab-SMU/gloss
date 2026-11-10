# Shared paths, pinned sources and small helpers for the bench scripts.
# Sourced by every script in bench/R/. Run scripts from the repository root.

bench_root <- normalizePath("bench", mustWork = TRUE)
cache_root <- path.expand(Sys.getenv("GLOSS_BENCH_CACHE", "~/.cache/gloss-bench"))
src_root <- file.path(cache_root, "src")
# one package library per platform and R version, so host and container never share one
lib_root <- file.path(cache_root, "lib", R.version$platform, paste(R.version$major, sub("\\..*$", "", R.version$minor), sep = "."))
for (d in c(src_root, lib_root)) dir.create(d, recursive = TRUE, showWarnings = FALSE)

seed <- 20261109L
bioc_version <- "3.21"
# the container sets a dated snapshot (bench/docker/run.sh); the host default is unpinned
cran_repo <- Sys.getenv("GLOSS_BENCH_CRAN", "https://cloud.r-project.org")

# Package environments (plan Scope changes, 2026-11-10). Code runs against the
# CRAN of its own era, each environment in its own library, never falling back
# to the other's:
#   cran: the Gallery commit's date (gallery, exts, patchwork strata);
#   bioc: the last day Bioconductor 3.21 was the release, 2025-10-29 (3.22 came
#         out 2025-10-30, bioconductor.org/config.yaml), for bioc and heatmap.
# The image's own site library is shared by both, as before.
bench_envs <- list(
  cran = list(name = "cran", cran = cran_repo, lib = lib_root),
  bioc = list(name = "bioc", cran = Sys.getenv("GLOSS_BENCH_CRAN_BIOC", "https://cloud.r-project.org"),
              lib = file.path(cache_root, "lib-bioc", R.version$platform,
                              paste(R.version$major, sub("\\..*$", "", R.version$minor), sep = ".")))
)
dir.create(bench_envs$bioc$lib, recursive = TRUE, showWarnings = FALSE)
env_for_stratum <- function(stratum) if (stratum %in% c("bioc", "heatmap")) bench_envs$bioc else bench_envs$cran

# The active environment: set per PSU (harvest) or per frozen figure (reruns).
.bench_state <- new.env()
.bench_state$env <- bench_envs$cran
use_env <- function(env) {
  stopifnot(is.list(env), env$name %in% names(bench_envs))
  .bench_state$env <- env
  invisible(env)
}
active_env <- function() .bench_state$env

sources <- list(
  gallery = list(
    repo = "https://github.com/holtzy/R-graph-gallery.git",
    sha = "8be6801aa6643931cedb22283dfa69e305c8bf79",
    raw = "https://raw.githubusercontent.com/holtzy/R-graph-gallery/8be6801aa6643931cedb22283dfa69e305c8bf79"
  ),
  exts = list(
    url = "https://raw.githubusercontent.com/ggplot2-exts/gallery/10a7d4033993d91744cc95c60a2f696851adca8a/_config.yml",
    sha = "10a7d4033993d91744cc95c60a2f696851adca8a"
  ),
  bioc = list(
    url = sprintf("https://bioconductor.org/packages/%s/bioc/VIEWS", "3.21"),
    version = "3.21"
  )
)

# Example code of a help topic as the runner runs it: \dontrun commented out,
# \donttest kept.
rd_example_code <- function(rd) {
  tmp <- tempfile(fileext = ".R")
  on.exit(unlink(tmp))
  tools::Rd2ex(rd, out = tmp, commentDontrun = TRUE, commentDonttest = FALSE)
  if (!file.exists(tmp)) return(character())
  readLines(tmp, warn = FALSE)
}

# A help topic is a figure source only if its examples have an executable
# line: not blank, not a comment, not a bare NULL. ComplexHeatmap 2.24-2.26
# documents 153 of its 253 topics with "# There is no example" and NULL.
has_example_code <- function(code) {
  x <- trimws(code)
  any(nzchar(x) & !startsWith(x, "#") & x != "NULL")
}

fetch <- function(url, dest) {
  if (!file.exists(dest)) {
    dir.create(dirname(dest), recursive = TRUE, showWarnings = FALSE)
    status <- system2("curl", c("-sS", "-L", "--fail", "--max-time", "600", "-o", shQuote(dest), shQuote(url)))
    if (status != 0) stop("download failed: ", url)
  }
  dest
}

md5 <- function(path) unname(tools::md5sum(path))

write_csv <- function(x, path) {
  x <- as.data.frame(x, stringsAsFactors = FALSE)
  utils::write.csv(x, path, row.names = FALSE, fileEncoding = "UTF-8")
  invisible(path)
}

read_csv <- function(path) utils::read.csv(path, stringsAsFactors = FALSE, fileEncoding = "UTF-8")

# Debian-control style records (Bioconductor VIEWS) into a data frame.
read_dcf_text <- function(path, fields) {
  x <- read.dcf(path, fields = fields)
  x <- as.data.frame(x, stringsAsFactors = FALSE)
  x[] <- lapply(x, function(v) gsub("\\s+", " ", trimws(ifelse(is.na(v), "", v))))
  x
}

# Packages a piece of R code asks for: library(), require(), requireNamespace(), pkg::
code_packages <- function(code) {
  code <- paste(code, collapse = "\n")
  pat <- c(
    "(?:library|require|requireNamespace)\\(\\s*[\"']?([A-Za-z][A-Za-z0-9.]*)",
    "([A-Za-z][A-Za-z0-9.]*):::?[A-Za-z._]"
  )
  out <- unlist(lapply(pat, function(p) {
    m <- regmatches(code, gregexpr(p, code, perl = TRUE))[[1]]
    sub(p, "\\1", m, perl = TRUE)
  }))
  setdiff(unique(out), c("base", "utils", "stats", "graphics", "grDevices", "methods", "datasets", "grid", "tools", "parallel", "splines", "stats4", "tcltk", "compiler"))
}

# R chunks of an R Markdown file: header options as text, code, and whether
# knitr would evaluate it (eval = FALSE / F skipped; other options ignored).
rmd_chunks <- function(path) {
  x <- readLines(path, warn = FALSE, encoding = "UTF-8")
  open <- grep("^\\s*```+\\s*\\{r([ ,}].*)?$", x)
  fence <- grep("^\\s*```+\\s*$", x)
  out <- list()
  for (i in seq_along(open)) {
    close <- fence[fence > open[i]][1]
    if (is.na(close)) break
    header <- x[open[i]]
    code <- if (close > open[i] + 1) x[(open[i] + 1):(close - 1)] else character()
    eval <- !grepl("eval\\s*=\\s*(FALSE|F)\\b", header)
    out[[length(out) + 1]] <- list(header = header, code = code, eval = eval, line = open[i])
  }
  out
}

# Static guess of the drawing engine from code text. Used for the frame and
# for reporting; the engine of a sampled figure is what the runner observes.
guess_engine <- function(code) {
  code <- paste(code, collapse = "\n")
  has <- function(p) grepl(p, code, perl = TRUE)
  widget <- has("\\b(ggplotly|plot_ly|leaflet|networkD3|dygraph|streamgraph|highchart|hchart|echarts4r|e_charts|d3tree|collapsibleTree|circlepackeR|chorddiag|reactable|datatable|gt\\(|kable|girafe|visNetwork|sankeyNetwork|forceNetwork|wordcloud2|rbokeh|tmap_mode\\(\"view)\\b")
  if (has("library\\(\\s*patchwork") || has("patchwork::")) return("patchwork")
  if (has("\\bHeatmap\\(") || has("ComplexHeatmap")) return("heatmap")
  if (has("\\b(ggplot|qplot|ggarrange|ggpairs|ggsurvplot|ggraph|ggtree|waffle|ggmap|ggbetweenstats|ggscatterstats)\\(")) return("ggplot")
  if (has("\\b(xyplot|bwplot|levelplot|histogram|densityplot|splom|wireframe|cloud|dotplot|barchart|stripplot)\\(") && has("lattice")) return("grid")
  if (has("\\bgrid\\.(newpage|draw|rect|lines|points|text|polygon)\\(")) return("grid")
  if (has("(^|[^._A-Za-z])(plot|barplot|hist|boxplot|pie|image|heatmap|pairs|matplot|stripchart|dotchart|mosaicplot|contour|persp|symbols|sunflowerplot|smoothScatter|coplot|stars|plot\\.new|chordDiagram|circos\\.[a-z]+|treemap|radarchart|venn\\.diagram|vioplot|wordcloud|beeswarm|map|plotCI|display\\.brewer\\.all)\\("))
    return("base")
  if (widget) return("widget")
  if (has("\\b(gt|gt_[a-z_]+|kbl|kable_[a-z_]+|tbl_[a-z_]+|flextable|formattable)\\(")) return("table")
  if (has("\\b(rgl|plot3d|persp3d|plot_gg|plot_3d)\\b")) return("rgl")
  "none"
}
