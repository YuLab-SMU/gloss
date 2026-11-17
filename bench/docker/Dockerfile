# M6 bench image: keep the M4/M5 Bioconductor base and add the device package
# required by gloss material generation. The CRAN snapshot is passed at build
# time and is recorded in the image manifest by the M6 environment preflight.
FROM bioconductor/bioconductor_docker@sha256:359702d482e70e343d2a436731b7c6deffd1ec184a1f1700de5d64b0c97cacba

ARG CRAN=https://p3m.dev/cran/__linux__/noble/2026-10-22

RUN Rscript -e "install.packages('svglite', repos = '${CRAN}', dependencies = FALSE, type = 'source')" \
 && Rscript -e "stopifnot(as.character(packageVersion('svglite')) == '2.2.2')"
