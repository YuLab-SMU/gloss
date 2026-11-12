# gloss bench figure gallery-036
# source: 257-input-formats-for-network-charts.Rmd (gallery)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# 9 no-break space(s) (U+00A0) in the source replaced by spaces.
# ---- chunk 1 ----
knitr::opts_chunk$set( warning=FALSE, message=FALSE)
# ---- chunk 2 ----
#library
library(igraph)

# Create data
set.seed(10)
data <- matrix(sample(0:2, 25, replace=TRUE), nrow=5)
colnames(data) = rownames(data) = LETTERS[1:5]
 
# build the graph object
network <- graph_from_adjacency_matrix(data)
 
# plot it
plot(network)
# ---- chunk 3 ----
# ---- chunk 4 ----
# lib
library(igraph)

# data
set.seed(1)
data <- matrix(sample(0:2, 15, replace=TRUE), nrow=3)
colnames(data) <- letters[1:5]
rownames(data) <- LETTERS[1:3]
 
# create the network object
network <- graph_from_incidence_matrix(data)
 
# plot it
plot(network)
# ---- chunk 5 ----
# ---- chunk 6 ----
# create data:
links <- data.frame(
    source=c("A","A", "A", "A", "A","F", "B"),
    target=c("B","B", "C", "D", "F","A","E")
    )

# create the network object
network <- graph_from_data_frame(d=links, directed=F) 

# plot it
plot(network)
