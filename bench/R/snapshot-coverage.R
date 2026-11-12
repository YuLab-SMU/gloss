# Which packages the sampled code needs are missing from a CRAN snapshot?
# Static: reads package lists and the code, runs no figure code.
#   Rscript bench/R/snapshot-coverage.R 2025-12-09 2026-10-22
source("bench/R/runner.R")
dates <- commandArgs(trailingOnly = TRUE)
pkgs_of <- function(url) rownames(utils::available.packages(contriburl = paste0(url, "/src/contrib"), filters = list()))
bioc <- unique(unlist(lapply(c("bioc", "data/annotation", "data/experiment", "workflows"), function(r)
  pkgs_of(sprintf("https://bioconductor.org/packages/%s/%s", bioc_version, r)))))
base <- rownames(utils::installed.packages(priority = c("base", "recommended")))
smp <- read_csv(file.path(bench_root, "sample.csv"))
gal_frame <- read_csv(file.path(bench_root, "frame", "gallery.csv"))$psu
post_pkgs <- lapply(setNames(gal_frame, gal_frame), function(p) code_packages(unlist(gallery_script(p)$chunks)))
needs <- list(
  gallery_frame = post_pkgs,
  gallery_sample = post_pkgs[smp$psu[smp$kind == "gallery"]],
  exts_frame = as.list(setNames(read_csv(file.path(bench_root, "frame", "exts.csv"))$psu, NULL)),
  exts_sample = as.list(smp$psu[smp$kind == "examples"])
)
for (d in dates) {
  cran <- pkgs_of(sprintf("https://p3m.dev/cran/__linux__/noble/%s", d))
  ok <- c(cran, bioc, base)
  cat("\n== CRAN snapshot", d, ":", length(cran), "packages\n")
  for (n in names(needs)) {
    units <- needs[[n]]
    miss <- lapply(units, function(p) setdiff(p, ok))
    hit <- lengths(miss) > 0
    cat(sprintf("  %-15s %3d units, %3d need a package absent here (%s)\n", n, length(units), sum(hit),
                paste(names(sort(table(unlist(miss)), decreasing = TRUE)), collapse = " ")))
  }
}
