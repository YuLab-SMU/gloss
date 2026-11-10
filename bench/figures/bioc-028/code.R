# gloss bench figure bioc-028
# source: atSNP (vignette)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- chunk 1 ----
## ----eval=TRUE, echo=TRUE, results = "markup"---------------------------------
library(atSNP)

# ---- chunk 2 ----
## ----eval=TRUE, echo=TRUE, results = "markup"---------------------------------
data(encode_library)
length(encode_motif)
encode_motif[1]

# ---- chunk 3 ----
## ----eval=TRUE, echo=TRUE, results="markup",tidy=TRUE-------------------------
encode_motif[[1]]
GetIUPACSequence(encode_motif[[1]])

# ---- chunk 4 ----
## ----eval=TRUE, echo=TRUE, results = "markup",tidy=TRUE-----------------------
length(encode_motifinfo)
head(encode_motifinfo)

# ---- chunk 5 ----
## ----eval=TRUE, echo=TRUE, results="markup",tidy=TRUE-------------------------
encode_motifinfo[names(encode_motif[1])]

# ---- chunk 6 ----
## ----eval=TRUE, echo = TRUE, results = "markup", tidy = TRUE------------------
data(jaspar_library)
jaspar_motif[[1]]
jaspar_motifinfo[names(jaspar_motif[1])]

# ---- chunk 7 ----
## ----eval=FALSE, echo=TRUE, results="hide"------------------------------------
# ## Source: http://meme.nbcr.net/meme/doc/examples/sample-dna-motif.meme-io
# pwms <- LoadMotifLibrary(
#  urlname="data/sample-dna-motif.meme-io.txt")
# 
# ## Source: http://compbio.mit.edu/encode-motifs/motifs.txt
# pwms <- LoadMotifLibrary(
#  urlname="http://pages.stat.wisc.edu/~keles/atSNP-Data/motifs.txt",
#  tag = ">", transpose = FALSE, field = 1,
#  sep = c("\t", " ", ">"), skipcols = 1,
#  skiprows = 1, pseudocount = 0)
# 
# ## Source: http://johnsonlab.ucsf.edu/mochi_files/JASPAR_motifs_H_sapiens.txt
# pwms <- LoadMotifLibrary(
#  urlname="data/JASPAR_motifs_H_sapiens.txt",
#  tag = "/NAME",skiprows = 1, skipcols = 0, transpose = FALSE,
#  field = 2)
# 
# ## Source: http://jaspar.genereg.net/html/DOWNLOAD/ARCHIVE/JASPAR2010/all_data/matrix_only/matrix.txt
# pwms <- LoadMotifLibrary(
#  urlname="data/matrix.txt",
#  tag = ">", skiprows = 1, skipcols = 1, transpose = TRUE,
#  field = 1, sep = c("\t", " ", "\\[", "\\]", ">"),
#  pseudocount = 1)
# 
# ## Source: http://jaspar.genereg.net/html/DOWNLOAD/JASPAR_CORE/pfm/nonredundant/pfm_vertebrates.txt
# pwms <- LoadMotifLibrary(
#  urlname="data/pfm_vertebrates.txt",
#  tag = ">", skiprows = 1, skipcols = 0, transpose = TRUE, field = 1,
#  sep = c(">", "\t", " "), pseudocount = 1)

# ---- chunk 8 ----
## ----eval=FALSE, echo=TRUE, results="markup",tidy=FALSE-----------------------
# data(example)
# write.table(snp_tbl, file = "test_snp_file.txt",
#             row.names = FALSE, quote = FALSE)
# snp_info <- LoadSNPData("test_snp_file.txt", genome.lib = "BSgenome.Hsapiens.UCSC.hg38", half.window.size = 30, default.par = TRUE, mutation = FALSE)
# ncol(snp_info$sequence) == nrow(snp_tbl)
# snp_info$rsid.rm
# 

# ---- chunk 9 ----
## ----eval=FALSE, echo=TRUE, results="markup",tidy=FALSE-----------------------
# mutation_info <- LoadSNPData("test_snp_file.txt", genome.lib = "BSgenome.Hsapiens.UCSC.hg38", half.window.size = 30, default.par = TRUE, mutation = TRUE)
# ncol(mutation_info$sequence) == nrow(snp_tbl)
# file.remove("test_snp_file.txt")

# ---- chunk 10 ----
## ----eval=FALSE, echo=TRUE, results="markup", tidy=FALSE----------------------
# snp_info1 <- LoadSNPData(snpids = c("rs5050", "rs616488", "rs11249433", "rs182799", "rs12565013", "rs11208590"), genome.lib ="BSgenome.Hsapiens.UCSC.hg38", snp.lib = "SNPlocs.Hsapiens.dbSNP144.GRCh38", half.window.size = 30, default.par = TRUE, mutation = FALSE)

# ---- chunk 11 ----
## ----eval=TRUE, echo = TRUE, results="markup",tidy=FALSE----------------------
snp_info2 <- LoadFastaData(ref.urlname="http://pages.stat.wisc.edu/~keles/atSNP-Data/sample_1.fasta", snp.urlname="http://pages.stat.wisc.edu/~keles/atSNP-Data/sample_2.fasta", default.par = TRUE)

# ---- chunk 12 ----
## ----eval=TRUE, echo=TRUE, results="markup",tidy=TRUE-------------------------
data(example)
names(motif_library)
str(snpInfo)
## to look at the motif information
data(encode_library)
encode_motifinfo[names(motif_library)]

# ---- chunk 13 ----
## ----eval=TRUE, echo=TRUE, results="markup"-----------------------------------
atsnp.scores <- ComputeMotifScore(motif_library, snpInfo, ncores = 1)
atsnp.scores$snp.tbl
atsnp.scores$motif.scores

# ---- chunk 14 ----
## ----eval=TRUE,echo=TRUE,results="markup"-------------------------------------
atsnp.result <- ComputePValues(motif.lib = motif_library, snp.info = snpInfo,
                               motif.scores = atsnp.scores$motif.scores, ncores = 1, testing.mc=TRUE)
atsnp.result

# ---- chunk 15 ----
## ----eval=TRUE, echo = TRUE, results="markup"---------------------------------
head(atsnp.result[order(atsnp.result$pval_rank), c("snpid", "motif", "pval_ref", "pval_snp", "pval_rank")])

# ---- chunk 16 ----
## ----eval=TRUE, echo = FALSE, results="hide"----------------------------------
pval_rank_bh = p.adjust(atsnp.result$pval_rank, method = "BH")
atsnp.result = cbind(atsnp.result, pval_rank_bh)

# ---- chunk 17 ----
## ----eval=TRUE, echo = FALSE, results="markup"--------------------------------
atsnp.result[c("snpid", "motif", "pval_rank", "pval_rank_bh")]

# ---- chunk 18 ----
## ----eval=FALSE, echo =TRUE,results="markup"----------------------------------
# library(qvalue)
# qval_rank = qvalue(atsnp.result$pval_rank, pi0=0.1)$qvalues
# atsnp.result = cbind(atsnp.result, qval_rank)

# ---- chunk 19 ----
## ----eval=TRUE,echo=TRUE,results="markup"-------------------------------------
match.subseq_result <- MatchSubsequence(snp.tbl = atsnp.scores$snp.tbl, motif.scores = atsnp.result, motif.lib = motif_library, snpids = c("rs53576", "rs7412"), motifs = names(motif_library)[1], ncores = 1)
match.subseq_result[c("snpid", "motif", "IUPAC", "ref_match_seq", "snp_match_seq")]

# ---- chunk 20 ----
## ----eval=TRUE, echo=TRUE, fig.align="center", fig.height=5, fig.width=5, warning=TRUE, dpi=300, include=TRUE, results="markup"----
match.seq<-dtMotifMatch(atsnp.scores$snp.tbl, atsnp.scores$motif.scores, snpids="rs53576", motifs="SIX5_disc1", motif.lib = motif_library)
plotMotifMatch(match.seq,  motif.lib = motif_library)
