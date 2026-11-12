# gloss bench figure bioc-021
# source: MicrobiotaProcess (vignette)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- chunk 1 ----
## ----echo=FALSE, results="asis", message=FALSE, KnitrSetUp--------------------
library(knitr)
knit_hooks$set(crop = hook_pdfcrop)
knitr::opts_chunk$set(crop = TRUE, tidy=FALSE, warning=FALSE,message=FALSE, fig.align="center")
Biocpkg <- function (pkg){
    sprintf("[%s](http://bioconductor.org/packages/%s)", pkg, pkg)
}

CRANpkg <- function(pkg){
    cran <- "https://CRAN.R-project.org/package" 
    fmt <- "[%s](%s=%s)"
    sprintf(fmt, pkg, cran, pkg) 
}

# ---- chunk 2 ----
## ----echo=FALSE, results="hide", message=FALSE, Loadpackages------------------
library(ggplot2)
library(phyloseq)
library(shadowtext)
library(ggtree)
library(ggtreeExtra)
library(treeio)
library(tidytree)
library(MicrobiotaProcess)

# ---- chunk 3 ----
## ----echo=FALSE, fig.width = 12, dpi=400, fig.align="center", fig.cap= "The structure of the MPSE class."----
knitr::include_graphics("./mpse.png")

# ---- chunk 4 ----
## ----echo=FALSE, fig.width = 12, dpi=400, fig.align="center", fig.cap="The Overview of the design of MicrobiotaProcess package"----
knitr::include_graphics("./mp-design.png")

# ---- chunk 5 ----
## ----warning=FALSE, message=FALSE---------------------------------------------
library(MicrobiotaProcess)
#parsing the output of dada2
seqtabfile <- system.file("extdata", "seqtab.nochim.rds", package="MicrobiotaProcess")
seqtab <- readRDS(seqtabfile)
taxafile <- system.file("extdata", "taxa_tab.rds", package="MicrobiotaProcess")
taxa <- readRDS(taxafile)
# the seqtab and taxa are output of dada2
sampleda <- system.file("extdata", "mouse.time.dada2.txt", package="MicrobiotaProcess")
mpse1 <- mp_import_dada2(seqtab=seqtab, taxatab=taxa, sampleda=sampleda)
mpse1

# parsing the output of qiime2
otuqzafile <- system.file("extdata", "table.qza", package="MicrobiotaProcess")
taxaqzafile <- system.file("extdata", "taxa.qza", package="MicrobiotaProcess")
mapfile <- system.file("extdata", "metadata_qza.txt", package="MicrobiotaProcess")
mpse2 <- mp_import_qiime2(otuqza=otuqzafile, taxaqza=taxaqzafile, mapfilename=mapfile)
mpse2

# parsing the output of MetaPhlAn
file1 <- system.file("extdata/MetaPhlAn", "metaphlan_test.txt", package="MicrobiotaProcess")
sample.file <- system.file("extdata/MetaPhlAn", "sample_test.txt", package="MicrobiotaProcess")
mpse3 <- mp_import_metaphlan(profile=file1, mapfilename=sample.file)
mpse3
# convert phyloseq object to mpse
#library(phyloseq)
#data(esophagus)
#esophagus
#mpse4 <- esophagus %>% as.MPSE() 
#mpse4
# convert TreeSummarizedExperiment object to mpse
# library(curatedMetagenomicData)
# tse <- curatedMetagenomicData::curatedMetagenomicData("ZhuF_2020.relative_abundance", dryrun=F)
# tse[[1]] %>% as.MPSE() -> mpse5
# mpse5

# ---- chunk 6 ----
## ----fig.align="center", fig.width=12, fig.height=4, fig.cap="The rarefaction of samples or groups"----
library(ggplot2)
library(MicrobiotaProcess)
data(mouse.time.mpse)
mouse.time.mpse
# Rarefied species richness
mouse.time.mpse %<>% mp_rrarefy()
# 'chunks' represent the split number of each sample to calculate alpha
# diversity, default is 400. e.g. If a sample has total 40000
# reads, if chunks is 400, it will be split to 100 sub-samples
# (100, 200, 300,..., 40000), then alpha diversity index was
# calculated based on the sub-samples. 
# '.abundance' the column name of abundance, if the '.abundance' is not be 
# rarefied calculate rarecurve, user can specific 'force=TRUE'.
mouse.time.mpse %<>% 
    mp_cal_rarecurve(
        .abundance = RareAbundance,
        chunks = 400
    )
# The RareAbundanceRarecurve column will be added the colData slot 
# automatically (default action="add")
mouse.time.mpse %>% print(width=180)
# default will display the confidence interval around smooth.
# se=TRUE
p1 <- mouse.time.mpse %>% 
      mp_plot_rarecurve(
         .rare = RareAbundanceRarecurve, 
         .alpha = Observe,
      )

p2 <- mouse.time.mpse %>% 
      mp_plot_rarecurve(
         .rare = RareAbundanceRarecurve, 
         .alpha = Observe, 
         .group = time
      ) +
      scale_color_manual(values=c("#00A087FF", "#3C5488FF")) +
      scale_fill_manual(values=c("#00A087FF", "#3C5488FF"), guide="none")

# combine the samples belong to the same groups if 
# plot.group=TRUE
p3 <- mouse.time.mpse %>% 
      mp_plot_rarecurve(
         .rare = RareAbundanceRarecurve, 
         .alpha = "Observe", 
         .group = time, 
         plot.group = TRUE
      ) +
       scale_color_manual(values=c("#00A087FF", "#3C5488FF")) +
       scale_fill_manual(values=c("#00A087FF", "#3C5488FF"),guide="none")  

p1 + p2 + p3
