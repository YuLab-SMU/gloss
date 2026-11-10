# Install what the harness and gloss need into the container's bench library.
#   bench/docker/run.sh Rscript bench/R/setup-container.R
source("bench/R/runner.R")
desc <- read.dcf("DESCRIPTION", fields = c("Imports", "Suggests"))
deps <- trimws(sub("\\(.*$", "", unlist(strsplit(paste(desc[1, ], collapse = ","), ","))))
deps <- setdiff(deps[nzchar(deps)], c("R", "grid", "grDevices", "utils", "stats", "tools", "methods"))
need <- unique(c("callr", "jsonlite", "digest", "pkgload", "knitr", "rmarkdown", deps))
res <- ensure_packages(need)
print(table(res$status))
if (any(res$status == "failed")) { print(res[res$status == "failed", ]); quit(status = 1) }
cat(R.version.string, "| Bioconductor", as.character(BiocManager::version()), "| lib", lib_root, "\n")
for (p in c("ggplot2", "ComplexHeatmap", "patchwork", "svglite", "gridGraphics"))
  cat(p, as.character(utils::packageVersion(p, lib.loc = bench_libpaths())), "\n")
