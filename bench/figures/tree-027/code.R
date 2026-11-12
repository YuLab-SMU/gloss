# gloss bench figure tree-027
# source: philr (vignette)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- chunk 1 ----
## ----echo=TRUE, message=FALSE-------------------------------------------------
library(philr); packageVersion("philr")
library(ape); packageVersion("ape")
library(ggplot2); packageVersion("ggplot2")

# ---- chunk 2 ----
## ----echo=TRUE, message=FALSE-------------------------------------------------
library(mia); packageVersion("mia")
library(dplyr); packageVersion("dplyr")
data(GlobalPatterns, package = "mia")

# ---- chunk 3 ----
## ----message=FALSE, warning=FALSE---------------------------------------------
## Select prevalent taxa 
tse <-  GlobalPatterns %>% subsetByPrevalentTaxa(
                               detection = 3,
                               prevalence = 20/100,
                               as_relative = FALSE)

## Pick taxa that have notable abundance variation across sammples
variable.taxa <- apply(assays(tse)$counts, 1, function(x) sd(x)/mean(x) > 3.0)
tse <- tse[variable.taxa,]
# Collapse the tree!
# Otherwise the original tree with all nodes is kept
# (including those that were filtered out from rowData)
tree <- ape::keep.tip(phy = rowTree(tse), tip = rowLinks(tse)$nodeNum)
rowTree(tse) <- tree

## Add a new assay with a pseudocount 
assays(tse)$counts.shifted <- assays(tse)$counts + 1 

# ---- chunk 4 ----
## ----echo=FALSE---------------------------------------------------------------
tse

# ---- chunk 5 ----
## ----message=FALSE, warning=FALSE---------------------------------------------
library(ape); packageVersion("ape")
is.rooted(tree) # Is the tree Rooted?
is.binary(tree) # All multichotomies resolved?

# ---- chunk 6 ----
## ----message=FALSE, warning=FALSE---------------------------------------------
tree <- makeNodeLabel(tree, method="number", prefix='n')

# Add the modified tree back to the (`TreeSE`) data object 
rowTree(tse) <- tree

# ---- chunk 7 ----
## -----------------------------------------------------------------------------
# Extract taxonomy table from the TreeSE object
tax <- rowData(tse)[,taxonomyRanks(tse)]

# Get name balances
name.balance(tree, tax, 'n1')

# ---- chunk 8 ----
## -----------------------------------------------------------------------------
otu.table <- t(as(assays(tse)$counts.shifted, "matrix"))
tree <- rowTree(tse)
metadata <- colData(tse)
tax <- rowData(tse)[,taxonomyRanks(tse)]

otu.table[1:2,1:2] # OTU Table
tree # Phylogenetic Tree
head(metadata,2) # Metadata
head(tax,2) # taxonomy table

# ---- chunk 9 ----
## -----------------------------------------------------------------------------
human.samples <- factor(colData(tse)$SampleType %in% c("Feces", "Mock", "Skin", "Tongue"))

# ---- chunk 10 ----
## ----message=FALSE------------------------------------------------------------
gp.philr <- philr(otu.table, tree, 
                  part.weights='enorm.x.gm.counts', 
                  ilr.weights='blw.sqrt')
gp.philr[1:5,1:5]

# ---- chunk 11 ----
## ----message=FALSE------------------------------------------------------------
gp.philr <- philr(tse, abund_values = "counts.shifted",
                  part.weights='enorm.x.gm.counts', 
                  ilr.weights='blw.sqrt')

# ---- chunk 12 ----
## ----message=FALSE------------------------------------------------------------
pseq <- convertToPhyloseq(tse, assay.type="counts.shifted")
gp.philr <- philr(pseq, 
                  part.weights='enorm.x.gm.counts', 
                  ilr.weights='blw.sqrt')


# ---- chunk 13 ----
## -----------------------------------------------------------------------------
# Distances between samples based on philr transformed data
gp.dist <- dist(gp.philr, method="euclidean") 

# Calculate MDS for the distance matrix
d <- as.data.frame(cmdscale(gp.dist))
colnames(d) <- paste0("PC", 1:2)

# ---- chunk 14 ----
## -----------------------------------------------------------------------------
# Add some metadata for the visualization 
d$SampleType <- factor(metadata$SampleType)

# Create a plot
ggplot(data = d,
  aes(x=PC1, y=PC2, color=SampleType)) +
  geom_point() +
  labs(title = "Euclidean distances with phILR")

# ---- chunk 15 ----
## ----message=FALSE, warning=FALSE---------------------------------------------
library(glmnet); packageVersion('glmnet')
glmmod <- glmnet(gp.philr, human.samples, alpha=1, family="binomial")

# ---- chunk 16 ----
## -----------------------------------------------------------------------------
top.coords <- as.matrix(coefficients(glmmod, s=0.2526))
top.coords <- rownames(top.coords)[which(top.coords != 0)]
(top.coords <- top.coords[2:length(top.coords)]) # remove the intercept as a coordinate

# ---- chunk 17 ----
## -----------------------------------------------------------------------------
tc.names <- sapply(top.coords, function(x) name.balance(tree, tax, x))
tc.names

# ---- chunk 18 ----
## -----------------------------------------------------------------------------
votes <- name.balance(tree, tax, 'n730', return.votes = c('up', 'down'))
votes[[c('up.votes', 'Family')]]   # Numerator at Family Level
votes[[c('down.votes', 'Family')]] # Denominator at Family Level

# ---- chunk 19 ----
## ----message=FALSE, warning=FALSE---------------------------------------------
library(ggtree); packageVersion("ggtree")
library(dplyr); packageVersion('dplyr')

# ---- chunk 20 ----
## ----message=FALSE, warning=FALSE---------------------------------------------
tc.nn <- name.to.nn(tree, top.coords)
tc.colors <- c('#a6cee3', '#1f78b4', '#b2df8a', '#33a02c', '#fb9a99')
p <- ggtree(tree, layout='fan') +
  geom_balance(node=tc.nn[1], fill=tc.colors[1], alpha=0.6) +
  geom_balance(node=tc.nn[2], fill=tc.colors[2], alpha=0.6) +
  geom_balance(node=tc.nn[3], fill=tc.colors[3], alpha=0.6) +
  geom_balance(node=tc.nn[4], fill=tc.colors[4], alpha=0.6) +
  geom_balance(node=tc.nn[5], fill=tc.colors[5], alpha=0.6)
p <- annotate_balance(tree, 'n16', p=p, labels = c('n16+', 'n16-'),
                 offset.text=0.15, bar=FALSE)
annotate_balance(tree, 'n730', p=p, labels = c('n730+', 'n730-'),
                 offset.text=0.15, bar=FALSE)
