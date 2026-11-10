# gloss bench figure gallery-040
# source: 249-igraph-network-map-a-color.Rmd (gallery)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# 1 no-break space(s) (U+00A0) in the source replaced by spaces.
# ---- chunk 1 ----
knitr::opts_chunk$set( warning=FALSE, message=FALSE)
# ---- chunk 2 ----
# library
library(igraph)
 
# create data:
links <- data.frame(
    source=c("A","A", "A", "A", "A","J", "B", "B", "C", "C", "D","I"),
    target=c("B","B", "C", "D", "J","A","E", "F", "G", "H", "I","I"),
    importance=(sample(1:4, 12, replace=T))
    )
nodes <- data.frame(
    name=LETTERS[1:10],
    carac=c( rep("young",3),rep("adult",2), rep("old",5))
    )
 
# Turn it into igraph object
network <- graph_from_data_frame(d=links, vertices=nodes, directed=F) 
 
# Make a palette of 3 colors
library(RColorBrewer)
coul  <- brewer.pal(3, "Set1") 
 
# Create a vector of color
my_color <- coul[as.numeric(as.factor(V(network)$carac))]
 
# Make the plot
plot(network, vertex.color=my_color)
 
# Add a legend
legend("bottomleft", legend=levels(as.factor(V(network)$carac))  , col = coul , bty = "n", pch=20 , pt.cex = 3, cex = 1.5, text.col=coul , horiz = FALSE, inset = c(0.1, 0.1))
