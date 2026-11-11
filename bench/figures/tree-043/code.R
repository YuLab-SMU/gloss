# gloss bench figure tree-043
# source: LymphoSeq (vignette)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- chunk 1 ----
## ----results = "hide"---------------------------------------------------------
library(LymphoSeq)

TCRB.path <- system.file("extdata", "TCRB_sequencing", package = "LymphoSeq")

TCRB.list <- readImmunoSeq(path = TCRB.path)

# ---- chunk 2 ----
## ----comment = ""-------------------------------------------------------------
names(TCRB.list)

# ---- chunk 3 ----
## ----comment = ""-------------------------------------------------------------
lapply(TCRB.list, dim)

# ---- chunk 4 ----
## ----comment = ""-------------------------------------------------------------
CMV <- TCRB.list[grep("CMV", names(TCRB.list))]
names(CMV)
TRB_Unsorted_0 <- TCRB.list[["TRB_Unsorted_0"]]
head(TRB_Unsorted_0)

# ---- chunk 5 ----
## ----comment = ""-------------------------------------------------------------
TCRB.metadata <- read.csv(system.file("extdata", "TCRB_metadata.csv", package = "LymphoSeq"))
TCRB.metadata
selected <- as.character(TCRB.metadata[TCRB.metadata$phenotype == "Unsorted" & 
                                 TCRB.metadata$day > 300, "samples"])
TCRB.list.selected <- TCRB.list[selected]
names(TCRB.list.selected)

# ---- chunk 6 ----
## ----results = "hide"---------------------------------------------------------
productive.TRB.aa <- productiveSeq(file.list = TCRB.list, aggregate = "aminoAcid", 
                               prevalence = FALSE)

# ---- chunk 7 ----
## ----results = "hide"---------------------------------------------------------
productive.TRB.nt <- productiveSeq(file.list = TCRB.list, aggregate = "nucleotide", 
                               prevalence = FALSE)

# ---- chunk 8 ----
## ----comment = ""-------------------------------------------------------------
head(TCRB.list[["TRB_Unsorted_0"]])

# ---- chunk 9 ----
## ----comment = ""-------------------------------------------------------------
head(productive.TRB.aa[["TRB_Unsorted_0"]])

# ---- chunk 10 ----
## ----comment = ""-------------------------------------------------------------
head(productive.TRB.nt[["TRB_Unsorted_0"]])

# ---- chunk 11 ----
## ----comment = ""-------------------------------------------------------------
clonality(file.list = TCRB.list)

# ---- chunk 12 ----
## ----results = "hide"---------------------------------------------------------
IGH.path <- system.file("extdata", "IGH_sequencing", package = "LymphoSeq")

IGH.list <- readImmunoSeq(path = IGH.path)

# ---- chunk 13 ----
## ----comment = ""-------------------------------------------------------------
clonalRelatedness(list = IGH.list, editDistance = 10)

# ---- chunk 14 ----
## ----results = "hide"---------------------------------------------------------
productive.IGH.nt <- productiveSeq(file.list = IGH.list, aggregate = "nucleotide")

# ---- chunk 15 ----
## ----fig.width = 7, fig.height = 8, comment = ""------------------------------
phyloTree(list = productive.IGH.nt, sample = "IGH_MVQ92552A_BL", type = "nucleotide", 
         layout = "rectangular")
