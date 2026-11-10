# gloss bench figure bioc-016
# source: ChIPseeker (vignette)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- chunk 1 ----
## ----style, echo=FALSE, results='asis', message=FALSE-------------------------
knitr::opts_chunk$set(tidy         = FALSE,
                      warning      = FALSE,
                      message      = FALSE)

library(yulab.utils)
Biocannopkg <- yulab.utils::Biocpkg

# ---- chunk 2 ----
## ----echo=FALSE, results='hide', message=FALSE--------------------------------
library(GenomicFeatures)
library(GenomicRanges)
library(TxDb.Hsapiens.UCSC.hg19.knownGene)
library(org.Hs.eg.db)
library(ggplot2)
library(clusterProfiler)
library(ReactomePA)
library(ChIPseeker)

# ---- chunk 3 ----
## -----------------------------------------------------------------------------
## loading packages
library(ChIPseeker)
library(TxDb.Hsapiens.UCSC.hg19.knownGene)
txdb <- TxDb.Hsapiens.UCSC.hg19.knownGene
library(clusterProfiler)

# ---- chunk 4 ----
## -----------------------------------------------------------------------------
files <- getSampleFiles()
print(files)
peak <- readPeakFile(files[[4]])
peak

# ---- chunk 5 ----
## ----fig.height=8, fig.width=10-----------------------------------------------
covplot(peak, weightCol="V5")

# ---- chunk 6 ----
## ----fig.height=4, fig.width=10-----------------------------------------------
covplot(peak, weightCol="V5", chrs=c("chr17", "chr18"), xlim=c(4.5e7, 5e7))

# ---- chunk 7 ----
## ----fig.height=8, fig.width=10-----------------------------------------------
peaks = lapply(files[4:5], readPeakFile)
covplot(peaks, weightCol = "V5", fill_color = c("red","blue")) +
  theme(legend.position = "inside",
        legend.position.inside = c(0.8,0.2))

# ---- chunk 8 ----
## -----------------------------------------------------------------------------
## promoter <- getPromoters(TxDb=txdb, upstream=3000, downstream=3000)
## tagMatrix <- getTagMatrix(peak, windows=promoter)
##
## to speed up the compilation of this vignettes, we use a precalculated tagMatrix
data("tagMatrixList")
tagMatrix <- tagMatrixList[[4]]

# ---- chunk 9 ----
## ----fig.cap="Heatmap of ChIP peaks binding to TSS regions", fig.align="center", fig.height=9, fig.width=6----
tagHeatmap(tagMatrix)

# ---- chunk 10 ----
## ----eval=FALSE---------------------------------------------------------------
# peakHeatmap(files[[4]], TxDb=txdb, upstream=3000, downstream=3000)

# ---- chunk 11 ----
## ----eval=FALSE---------------------------------------------------------------
# peakHeatmap(files[[4]],TxDb = txdb,nbin = 800,upstream=3000, downstream=3000)
# 

# ---- chunk 12 ----
## ----eval=FALSE---------------------------------------------------------------
# peakHeatmap(files[[4]],TxDb = txdb,nbin = 800,upstream=3000, downstream=3000) +
#   scale_fill_distiller(palette = "RdYlGn")

# ---- chunk 13 ----
## ----fig.cap="Heatmap of genebody regions", fig.align="center", fig.height=9, fig.width=6,results='hide'----
peakHeatmap(peak = files[[4]],
            TxDb = txdb,
            upstream = rel(0.2),
            downstream = rel(0.2),
            by = "gene",
            type = "body",
            nbin = 800)

# ---- chunk 14 ----
## ----fig.cap="Heatmap of over two regions", fig.align="center", fig.height=9, fig.width=6,results='hide'----
txdb1 <- transcripts(TxDb.Hsapiens.UCSC.hg19.knownGene)
txdb2 <- unlist(fiveUTRsByTranscript(TxDb.Hsapiens.UCSC.hg19.knownGene))[1:10000,]

region_list <- list(geneX = txdb1, geneY = txdb2)
peakHeatmap_multiple_Sets(peak = files[[4]],
                          upstream = 1000,downstream = 1000,
                          by = c("geneX","geneY"),
                          type = "start_site",
                          TxDb = region_list,nbin = 800)

# ---- chunk 15 ----
## ----fig.cap="Combination of heatmap and peak profiling", fig.align="center", fig.height=9, fig.width=6,results='hide'----
peak_Profile_Heatmap(peak = files[[4]],
                     upstream = 1000,
                     downstream = 1000,
                     by = "gene",
                     type = "start_site",
                     TxDb = txdb,
                     nbin = 800)

# ---- chunk 16 ----
## ----fig.cap="Combination of heatmap and peak profiling over several regions", fig.align="center", fig.height=12, fig.width=6,results='hide'----
txdb1 <- transcripts(TxDb.Hsapiens.UCSC.hg19.knownGene)
txdb2 <- unlist(fiveUTRsByTranscript(TxDb.Hsapiens.UCSC.hg19.knownGene))[1:10000,]

region_list <- list(geneX = txdb1, geneY = txdb2)
peak_Profile_Heatmap(peak = files[[4]],
                     upstream = 1000,
                     downstream = 1000,
                     by = c("geneX","geneY"),
                     type = "start_site",
                     TxDb = region_list,nbin = 800)

# ---- chunk 17 ----
## ----eval=TRUE, fig.cap="Average Profile of ChIP peaks binding to TSS region", fig.align="center", fig.height=4, fig.width=7----
plotAvgProf(tagMatrix, xlim=c(-3000, 3000),
            xlab="Genomic Region (5'->3')", ylab = "Read Count Frequency")

# ---- chunk 18 ----
## ----eval=FALSE---------------------------------------------------------------
# plotAvgProf2(files[[4]], TxDb=txdb, upstream=3000, downstream=3000,
#              xlab="Genomic Region (5'->3')", ylab = "Read Count Frequency")

# ---- chunk 19 ----
## ----fig.cap="Average Profile of ChIP peaks binding to TSS region", fig.align="center", fig.height=4, fig.width=7, eval=F----
# plotAvgProf(tagMatrix, xlim=c(-3000, 3000), conf = 0.95, resample = 1000)

# ---- chunk 20 ----
## ----eval=F-------------------------------------------------------------------
# ## The results of binning method and normal method are nearly the same.
# tagMatrix_binning <- getTagMatrix(peak = peak, TxDb = txdb,
#                                   upstream = 3000, downstream = 3000,
#                                   type = "start_site", by = "gene",
#                                   weightCol = "V5", nbin = 800)

# ---- chunk 21 ----
## ----eval=F-------------------------------------------------------------------
# ## Here uses `plotPeakProf2` to do all things in one step.
# ## Gene body regions having lengths smaller than nbin will be filtered
# ## A message will be given to warning users about that.
# ## >> 9 peaks(0.872093%), having lengths smaller than 800bp, are filtered...
# 
# ## the ignore_strand is FALSE in default. We put here to emphasize that.
# ## We will not show it again in the below example
# plotPeakProf2(peak = peak, upstream = rel(0.2), downstream = rel(0.2),
#               conf = 0.95, by = "gene", type = "body", nbin = 800,
#               TxDb = txdb, weightCol = "V5",ignore_strand = F)

# ---- chunk 22 ----
## ----eval=F-------------------------------------------------------------------
# ## The first method using getBioRegion(), getTagMatrix() and plotPeakProf() to plot in three steps.
# genebody <- getBioRegion(TxDb = txdb,
#                          by = "gene",
#                          type = "body")
# 
# matrix_no_flankextension <- getTagMatrix(peak,windows = genebody, nbin = 800)
# 
# plotPeakProf(matrix_no_flankextension,conf = 0.95)
# 
# ## The second method of using getTagMatrix() and plotPeakProf() to plot in two steps
# matrix_actual_extension <- getTagMatrix(peak,windows = genebody, nbin = 800,
#                                         upstream = 1000,downstream = 1000)
# plotPeakProf(matrix_actual_extension,conf = 0.95)
# 

# ---- chunk 23 ----
## ----eval=F-------------------------------------------------------------------
# five_UTR_body <- getTagMatrix(peak = peak,
#                               TxDb = txdb,
#                               upstream = rel(0.2),
#                               downstream = rel(0.2),
#                               type = "body",
#                               by = "5UTR",
#                               weightCol = "V5",
#                               nbin = 50)
# 
# plotPeakProf(tagMatrix = five_UTR_body, conf = 0.95)

# ---- chunk 24 ----
## ----eval=F-------------------------------------------------------------------
# TTS_matrix <- getTagMatrix(peak = peak,
#                            TxDb = txdb,
#                            upstream = 3000,
#                            downstream = 3000,
#                            type = "end_site",
#                            by = "gene",
#                            weightCol = "V5")
# 
# plotPeakProf(tagMatrix = TTS_matrix, conf = 0.95)

# ---- chunk 25 ----
## -----------------------------------------------------------------------------
peakAnno <- annotatePeak(files[[4]], tssRegion=c(-3000, 3000),
                         TxDb=txdb, annoDb="org.Hs.eg.db")

# ---- chunk 26 ----
## ----eval = FALSE-------------------------------------------------------------
# library(EnsDb.Hsapiens.v75)
# edb <- EnsDb.Hsapiens.v75
# seqlevelsStyle(edb) <- "UCSC"
# 
# peakAnno.edb <- annotatePeak(files[[4]], tssRegion=c(-3000, 3000),
#                              TxDb=edb, annoDb="org.Hs.eg.db")

# ---- chunk 27 ----
## ----fig.cap="Genomic Annotation by pieplot", fig.align="center", fig.height=6, fig.width=8----
plotAnnoPie(peakAnno)

# ---- chunk 28 ----
## ----fig.cap="Genomic Annotation by barplot", fig.align="center", fig.height=4, fig.width=10----
plotAnnoBar(peakAnno)
