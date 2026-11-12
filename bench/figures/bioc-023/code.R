# gloss bench figure bioc-023
# source: ribosomeProfilingQC (vignette)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- chunk 1 ----
## ----echo=FALSE, results="hide", warning=FALSE, message=FALSE-----------------
suppressPackageStartupMessages({
  library(ribosomeProfilingQC)
  library(BSgenome.Drerio.UCSC.danRer10)
  library(GenomicFeatures)
  library(Rsamtools)
  library(AnnotationDbi)
  library(motifStack)
})
knitr::opts_chunk$set(warning=FALSE, message=FALSE, fig.width=5, fig.height=3.5)

# ---- chunk 2 ----
## ----eval=FALSE---------------------------------------------------------------
# library(BiocManager)
# # BiocManager::install(c("ribosomeProfilingQC", # [bench: install call removed]
#                        "AnnotationDbi", "Rsamtools",
#                        "BSgenome.Drerio.UCSC.danRer10",
#                        "TxDb.Drerio.UCSC.danRer10.refGene",
#                        "motifStack"))

# ---- chunk 3 ----
## -----------------------------------------------------------------------------
R.version

# ---- chunk 4 ----
## ----loadLibrary, class.source='vig'------------------------------------------
## load library
library(ribosomeProfilingQC)
library(AnnotationDbi)
library(Rsamtools)
library(ggplot2)

# ---- chunk 5 ----
## ----loadGenome, class.source='vig'-------------------------------------------
library(BSgenome.Drerio.UCSC.danRer10)
## set genome, Drerio is a shortname for BSgenome.Drerio.UCSC.danRer10
genome <- Drerio

# ---- chunk 6 ----
## ----eval=FALSE---------------------------------------------------------------
# library(BSgenome.Hsapiens.UCSC.hg38)
# genome <- Hsapiens

# ---- chunk 7 ----
## ----eval=FALSE---------------------------------------------------------------
# library(BSgenome.Mmusculus.UCSC.mm10)
# genome <- Mmusculus

# ---- chunk 8 ----
## ----eval=FALSE---------------------------------------------------------------
# genome <- Biostrings::readDNAStringSet('filepath/to/the/genome/fasta/file')

# ---- chunk 9 ----
## ----eval=FALSE---------------------------------------------------------------
# ## which is corresponding to BSgenome.Drerio.UCSC.danRer10
# library(TxDb.Drerio.UCSC.danRer10.refGene)
# txdb <- TxDb.Drerio.UCSC.danRer10.refGene ## give it a short name
# CDS <- prepareCDS(txdb)

# ---- chunk 10 ----
## ----eval=FALSE---------------------------------------------------------------
# library(TxDb.Hsapiens.UCSC.hg38.knownGene)
# txdb <- TxDb.Hsapiens.UCSC.hg38.knownGene ## give it a short name
# CDS <- prepareCDS(txdb)

# ---- chunk 11 ----
## ----eval=FALSE---------------------------------------------------------------
# library(TxDb.Mmusculus.UCSC.mm10.knownGene)
# txdb <- TxDb.Mmusculus.UCSC.mm10.knownGene ## give it a short name
# CDS <- prepareCDS(txdb)

# ---- chunk 12 ----
## ----loadTxDb, class.source='vig'---------------------------------------------
## Create a small TxDb object which only contain chr1 information.
library(GenomicFeatures)
txdb <- makeTxDbFromGFF(system.file("extdata",
                                    "Danio_rerio.GRCz10.91.chr1.gtf.gz",
                                    package="ribosomeProfilingQC"),
                        organism = "Danio rerio",
                        chrominfo = seqinfo(Drerio)["chr1"],
                        taxonomyId = 7955)
CDS <- prepareCDS(txdb)

# ---- chunk 13 ----
## ----filter, eval=FALSE-------------------------------------------------------
# bamfilename <- system.file("extdata", "RPF.WT.1.bam",
#                            package="ribosomeProfilingQC")
# bamHeader <- Rsamtools::scanBamHeader(bamfilename)
# (chromsomeNameStyle <- GenomeInfoDb::seqlevelsStyle(names(bamHeader[[1]]$targets)))
# library(rtracklayer)
# ## the gtf could be downloaded from https://www.ensembl.org/info/data/ftp/index.html
# ## Please make sure the version number are correct.
# ## check the version number at https://www.ensembl.org/info/website/archives/index.html
# gtf <- import(system.file("extdata",
#                           "Danio_rerio.GRCz10.91.chr1.gtf.gz",
#                           package="ribosomeProfilingQC"))
# gtf <- gtf[gtf$transcript_biotype %in%
#              c('rRNA', 'tRNA', 'snRNA', 'snoRNA', 'misc_RNA')]
# mcols(gtf) <- NULL
# annotation <- 'danRer10' ## must be UCSC style, eg, GRCm38 should be mm10, GRCh38 should be hg38
# rmsk <- data.table::fread(paste0('https://hgdownload.soe.ucsc.edu/goldenPath/',
#                                 annotation, '/database/rmsk.txt.gz'),
#                           header=FALSE)
# colnames(rmsk) <- c('bin', 'swScore', 'milliDiv', 'milliDel', 'milliIns',
#                     'genoName', 'genoStart', 'genoEnd', 'genoLeft', 'strand',
#                     'repName', 'repClass', 'repFamily', 'repStart', 'repEnd',
#                     'repLeft', 'id')
# rmsk_gr <- with(rmsk, GRanges(genoName, IRanges(genoStart+1, genoEnd),
#                               strand = strand))
# # 'UCSC' or 'ensembl', keep same as it in the bam file
# GenomeInfoDb::seqlevelsStyle(gtf) <- seqlevelsStyle(rmsk_gr) <-
#   chromsomeNameStyle[1]
# gr <- reduce(sort(c(gtf, rmsk_gr)))
# seqlevels(gr, pruning.mode="coarse") <-
#   intersect(seqlevels(gr), names(bamHeader[[1]]$targets))
# outputBed <- 'unused_regions.bed'
# export(gr, outputBed)
# filteredBamfileName <- sub('.bam$', '.fil.bam', bamfilename)
# unusedBamfileName <- sub('.bam$', '.no_use.bam', bamfilename)
# ## run the cmd in terminal or by system/system2
# ## please make sure the samtools is available in PATH
# ## see more about samtools at https://www.htslib.org/
# (cmd <- paste('samtools view -b -L', outputBed,
#               '-U', filteredBamfileName,
#               '-o', unusedBamfileName,
#               bamfilename))
# system2('samtools',
#   args = c('view', '-b',
#            '-L', outputBed,
#            '-U', filteredBamfileName,
#            '-o', unusedBamfileName,
#            bamfilename))
# (cmd2 <- paste('samtools bam2fq', filteredBamfileName,
#                '| gzip >', sub('.bam$', '.fq.gz', filteredBamfileName)))
# system2('samtools',
#         args = c('bam2fq', filteredBamfileName,
#                '|', 'gzip', '>', sub('.bam$', '.fq.gz', filteredBamfileName)))

# ---- chunk 14 ----
## ----inputBamFile, class.source='vig'-----------------------------------------
library(Rsamtools)
## input the bamFile from the ribosomeProfilingQC package 
bamfilename <- system.file("extdata", "RPF.WT.1.bam",
                           package="ribosomeProfilingQC")
## For your own data, please set bamfilename as your file path.
## For example, your bam file is located at C:\mydata\a.bam
## you want to set bamfilename = "C:\\mydata\\a.bam"
## or you can change your working directory by
## setwd("C:\\mydata")
## and then set bamfilename = "a.bam"
yieldSize <- 10000000
bamfile <- BamFile(bamfilename, yieldSize = yieldSize)

# ---- chunk 15 ----
## ----estimatePsite, class.source='vig'----------------------------------------
estimatePsite(bamfile, CDS, genome)

# ---- chunk 16 ----
## ----estimatePsite3end, class.source='vig'------------------------------------
estimatePsite(bamfile, CDS, genome, anchor = "3end")

# ---- chunk 17 ----
## ----readsEndPlot, fig.height=4, fig.width=6, class.source='vig'--------------
re <- readsEndPlot(bamfile, CDS, toStartCodon=TRUE)
readsEndPlot(re$reads, CDS, toStartCodon=TRUE, fiveEnd=FALSE)

# ---- chunk 18 ----
## ----getPsiteCoordinates, class.source='vig'----------------------------------
pc <- getPsiteCoordinates(bamfile, bestpsite = 13)

# ---- chunk 19 ----
## ----readsLen, class.source='vig'---------------------------------------------
readsLen <- summaryReadsLength(pc)

# ---- chunk 20 ----
## ----filterSize, class.source='vig'-------------------------------------------
## for this QC demo, we will only use reads length of 28-29 nt.
pc.sub <- pc[pc$qwidth %in% c(28, 29)]

# ---- chunk 21 ----
## ----strandPlot, fig.width=2,fig.height=3, class.source='vig'-----------------
strandPlot(pc.sub, CDS)

# ---- chunk 22 ----
## ----readsDistribution, fig.width=7, fig.height=4, class.source='vig'---------
pc.sub <- readsDistribution(pc.sub, txdb, las=2)

# ---- chunk 23 ----
## ----metaPlotUTR5cdsUTR3, fig.width=5, fig.height=4, class.source='vig'-------
cvgs.utr5 <- coverageDepth(RPFs = bamfilename, gtf = txdb, region="utr5")
cvgs.CDS <- coverageDepth(RPFs = bamfilename, gtf = txdb, region="cds")
cvgs.utr3 <- coverageDepth(RPFs = bamfilename, gtf = txdb, region="utr3")
metaPlot(cvgs.utr5, cvgs.CDS, cvgs.utr3, sample=1)

# ---- chunk 24 ----
## ----assignReadingFrame, fig.width=5, fig.height=3, class.source='vig'--------
pc.sub <- assignReadingFrame(pc.sub, CDS)
plotDistance2Codon(pc.sub)

# ---- chunk 25 ----
## ----plotFrameDensity, fig.width=2.5,fig.height=3, class.source='vig'---------
plotFrameDensity(pc.sub)

# ---- chunk 26 ----
## ----allReadFrame, fig.width=2.5,fig.height=3, class.source='vig'-------------
pc <- assignReadingFrame(pc, CDS)
plotFrameDensity(pc)

# ---- chunk 27 ----
## ----plotTranscript, fig.width=8, fig.height=6, class.source='vig'------------
plotTranscript(pc.sub, c("ENSDART00000161781", "ENSDART00000166968",
                         "ENSDART00000040204", "ENSDART00000124837"))
