# gloss bench figure tree-066
# source: LinTInd (vignette)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- chunk 1 ----
## ----load package, message=FALSE----------------------------------------------
library(LinTInd)

# ---- chunk 2 ----
## ----message=FALSE------------------------------------------------------------
data<-paste0(system.file("extdata",package = 'LinTInd'),"/CB_UMI")
fafile<-paste0(system.file("extdata",package = 'LinTInd'),"/V3.fasta")
cutsite<-paste0(system.file("extdata",package = 'LinTInd'),"/V3.cutSites")
celltype<-paste0(system.file("extdata",package = 'LinTInd'),"/celltype.tsv")
data<-read.table(data,sep="\t",header=TRUE)
ref<-ReadFasta(fafile)
cutsite<-read.table(cutsite,col.names = c("indx","start","end"))
celltype<-read.table(celltype,header=TRUE,stringsAsFactors=FALSE)

# ---- chunk 3 ----
## -----------------------------------------------------------------------------
head(data,3)
ref
cutsite
head(celltype,3)

# ---- chunk 4 ----
## ----find indels and generate array-form strings, message=FALSE---------------
scarinfo<-FindIndel(data=data,scarfull=ref,scar=cutsite,indel.coverage="All",type="test",cln=1)
scarinfo<-IndelForm(scarinfo,cln=1)

# ---- chunk 5 ----
## ----IndelIdents, message=FALSE-----------------------------------------------
cellsinfo<-IndelIdents(scarinfo,method.use="umi.num",cln=1)

# ---- chunk 6 ----
## ----IndelPlot----------------------------------------------------------------
IndelPlot(cellsinfo = cellsinfo)

# ---- chunk 7 ----
## ----TagProcess---------------------------------------------------------------
tag<-TagProcess(cellsinfo$info,Cells=celltype)

# ---- chunk 8 ----
## ----TagDist------------------------------------------------------------------
tag_dist=TagDist(tag,method = "Jaccard")
tag_dist

# ---- chunk 9 ----
## ----BuildTree----------------------------------------------------------------
treeinfo<-BuildTree(tag)

# ---- chunk 10 ----
## ----PlotTree-----------------------------------------------------------------
plotinfo<-PlotTree(treeinfo = treeinfo,data.extract = "TRUE",annotation = "TRUE")
plotinfo$p
