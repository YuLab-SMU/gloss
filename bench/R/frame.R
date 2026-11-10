# Build the sampling frames (bench v0, Task 1). Run from the repository root:
#   Rscript bench/R/frame.R
# Downloads pinned sources into ~/.cache/gloss-bench/src and writes
# bench/frame/*.csv and bench/frame/sources.json.

source("bench/R/common.R")
out_dir <- file.path(bench_root, "frame")

# --- R Graph Gallery: sparse checkout of the .Rmd posts at a pinned commit
gallery_dir <- file.path(src_root, "gallery")
git <- function(...) {
  status <- system2("git", c("-C", shQuote(gallery_dir), ...))
  if (status != 0) stop("git failed: ", paste(...))
}
if (!dir.exists(gallery_dir)) {
  dir.create(gallery_dir, recursive = TRUE)
  git("init", "-q")
  git("remote", "add", "origin", sources$gallery$repo)
  git("config", "core.sparseCheckout", "true")
  git("sparse-checkout", "set", "--no-cone", "'/*.Rmd'", "'/package/*.Rmd'")
  git("fetch", "-q", "--depth", "1", "--filter=blob:none", "origin", sources$gallery$sha)
  git("checkout", "-q", sources$gallery$sha)
}
head_sha <- system2("git", c("-C", shQuote(gallery_dir), "rev-parse", "HEAD"), stdout = TRUE)
stopifnot(identical(head_sha, sources$gallery$sha))

posts <- c(Sys.glob(file.path(gallery_dir, "*.Rmd")), Sys.glob(file.path(gallery_dir, "package", "*.Rmd")))
gallery <- do.call(rbind, lapply(posts, function(f) {
  ch <- rmd_chunks(f)
  # All R chunks: many posts show their figure code in eval = FALSE chunks
  # and display a pre-rendered image; that code is still the figure code.
  code <- unlist(lapply(ch, `[[`, "code"))
  yaml <- readLines(f, n = 40, warn = FALSE)
  sec <- grep("^sectionLink:", yaml, value = TRUE)
  sec <- if (length(sec)) gsub("^sectionLink:\\s*\"?|\"\\s*$", "", sec[1]) else ""
  data.frame(
    psu = sub(paste0("^", gallery_dir, "/"), "", f),
    section = sub("\\.html.*$", "", sec),
    n_chunks = length(ch),
    n_eval_chunks = sum(vapply(ch, `[[`, TRUE, "eval")),
    engine_guess = guess_engine(code),
    loads_patchwork = grepl("library\\(\\s*patchwork|patchwork::", paste(code, collapse = "\n")),
    packages = paste(sort(code_packages(code)), collapse = " "),
    stringsAsFactors = FALSE
  )
}))
gallery <- gallery[order(gallery$psu), ]

# --- ggplot2 extensions gallery: packages marked as on CRAN
exts_file <- fetch(sources$exts$url, file.path(src_root, "exts", paste0(sources$exts$sha, "_config.yml")))
y <- readLines(exts_file, warn = FALSE, encoding = "UTF-8")
starts <- grep("^\\s*- name:", y)
ends <- c(starts[-1] - 1, length(y))
exts_all <- do.call(rbind, lapply(seq_along(starts), function(i) {
  block <- y[starts[i]:ends[i]]
  data.frame(
    psu = trimws(sub("^\\s*- name:\\s*", "", block[1])),
    cran = any(grepl("^\\s*cran:\\s*true", block)),
    stringsAsFactors = FALSE
  )
}))
exts <- exts_all[exts_all$cran, "psu", drop = FALSE]
exts <- exts[!duplicated(exts$psu), , drop = FALSE]
exts <- exts[order(exts$psu), , drop = FALSE]

# --- Bioconductor 3.21 software packages in the Visualization view, with vignettes
views_file <- fetch(sources$bioc$url, file.path(src_root, "bioc", paste0("VIEWS-", bioc_version)))
views <- read_dcf_text(views_file, c("Package", "Version", "biocViews", "Depends", "Imports", "vignettes"))
views$visualization <- grepl("(^|, ?)Visualization(,|$)", views$biocViews)
views$has_vignette <- nzchar(views$vignettes)
views$imports_complexheatmap <- grepl("\\bComplexHeatmap\\b", paste(views$Depends, views$Imports))
bioc <- views[views$visualization & views$has_vignette, c("Package", "Version", "imports_complexheatmap")]
names(bioc)[1:2] <- c("psu", "version")
bioc <- bioc[order(bioc$psu), ]

# --- help topics with examples, from the locally installed packages
rd_topics <- function(pkg) {
  db <- tools::Rd_db(pkg)
  has_ex <- vapply(db, function(rd) any(vapply(rd, function(s) identical(attr(s, "Rd_tag"), "\\examples"), TRUE)), TRUE)
  sort(sub("\\.Rd$", "", names(db)[has_ex]))
}

# A topic whose examples have no executable line is kept in the frame (so the
# sample's permutations do not move) but marked out of scope; sample.R skips it.
topic_rows <- function(pkg) {
  db <- tools::Rd_db(pkg)
  t <- rd_topics(pkg)
  in_scope <- vapply(t, function(x) has_example_code(rd_example_code(db[[paste0(x, ".Rd")]])), TRUE, USE.NAMES = FALSE)
  data.frame(psu = paste0(pkg, "::", t), kind = "topic", in_scope = in_scope, stringsAsFactors = FALSE)
}

# --- engine strata
patchwork <- rbind(
  data.frame(psu = gallery$psu[gallery$loads_patchwork], kind = "gallery", in_scope = TRUE, stringsAsFactors = FALSE),
  topic_rows("patchwork")
)
ch_users <- views$Package[views$imports_complexheatmap & views$has_vignette]
heatmap <- rbind(
  topic_rows("ComplexHeatmap"),
  data.frame(psu = sort(ch_users), kind = "bioc", in_scope = TRUE, stringsAsFactors = FALSE)
)
heatmap <- heatmap[heatmap$psu != "ComplexHeatmap", ]

write_csv(gallery, file.path(out_dir, "gallery.csv"))
write_csv(exts, file.path(out_dir, "exts.csv"))
write_csv(bioc, file.path(out_dir, "bioc.csv"))
write_csv(patchwork, file.path(out_dir, "patchwork.csv"))
write_csv(heatmap, file.path(out_dir, "heatmap.csv"))

info <- list(
  built = format(Sys.Date()),
  gallery = list(repo = sources$gallery$repo, sha = sources$gallery$sha, posts = nrow(gallery),
                 chunks = sum(gallery$n_chunks)),
  exts = list(url = sources$exts$url, entries = nrow(exts_all), cran = nrow(exts)),
  bioc = list(url = sources$bioc$url, md5 = md5(views_file), packages = nrow(views),
              visualization = sum(views$visualization), frame = nrow(bioc)),
  topics = list(ComplexHeatmap = as.character(utils::packageVersion("ComplexHeatmap")),
                patchwork = as.character(utils::packageVersion("patchwork"))),
  strata = list(gallery = nrow(gallery), exts = nrow(exts), bioc = nrow(bioc),
                patchwork = nrow(patchwork), heatmap = nrow(heatmap)),
  out_of_scope = list(rule = "help topic whose examples have no executable line (blank, comment or bare NULL only)",
                      patchwork = sum(!patchwork$in_scope), heatmap = sum(!heatmap$in_scope)),
  tidytuesday = "not in the v0 frame: the official repository holds data, readmes and images but no figure code"
)
jsonlite::write_json(info, file.path(out_dir, "sources.json"), auto_unbox = TRUE, pretty = TRUE)

cat("frame sizes:\n"); str(info$strata)
cat("gallery engine guess:\n"); print(table(gallery$engine_guess))
