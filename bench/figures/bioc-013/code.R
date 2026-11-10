# gloss bench figure bioc-013
# source: biocGraph (vignette)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- chunk 1 ----
### R code from vignette source 'biocGraph.Rnw'

###################################################
# ---- chunk 2 ----
### code chunk number 1: createGraph1
###################################################
library("biocGraph")
set.seed(123)
V <- letters[1:10]
M <- 1:4


###################################################
# ---- chunk 3 ----
### code chunk number 2: createGraph2
###################################################
g1 <- randomGraph(V, M, 0.2)


###################################################
# ---- chunk 4 ----
### code chunk number 3: plotDot
###################################################
plot(g1)


###################################################
# ---- chunk 5 ----
### code chunk number 4: plotNeato
###################################################
plot(g1, "neato")


###################################################
# ---- chunk 6 ----
### code chunk number 5: plotTwopi
###################################################
plot(g1, "twopi")


###################################################
# ---- chunk 7 ----
### code chunk number 6: rEG
###################################################
rEG <- new("graphNEL", nodes=c("A", "B"), edgemode="directed")
rEG <- addEdge("A", "B", rEG, 1)
rEG <- addEdge("B", "A", rEG, 1)


###################################################
# ---- chunk 8 ----
### code chunk number 7: recipEdgesComb
###################################################
plot(rEG)


###################################################
# ---- chunk 9 ----
### code chunk number 8: recipEdgesDistinct
###################################################
plot(rEG, recipEdges="distinct")


###################################################
# ---- chunk 10 ----
### code chunk number 9: removedEdges
###################################################
removedEdges(g1)


###################################################
# ---- chunk 11 ----
### code chunk number 10: getSubgraphs
###################################################
sg1 <- subGraph(c("a","d","j","i"), g1)
sg1
sg2 <- subGraph(c("b","e","h"), g1)
sg3 <- subGraph(c("c","f","g"), g1)


###################################################
# ---- chunk 12 ----
### code chunk number 11: subGplot
###################################################
subGList <- vector(mode="list", length=3)
subGList[[1]] <- list(graph=sg1)
subGList[[2]] <- list(graph=sg2, cluster=FALSE)
subGList[[3]] <- list(graph=sg3)
plot(g1, subGList=subGList)


###################################################
# ---- chunk 13 ----
### code chunk number 12: subGPlot2
###################################################
sg1 <- subGraph(c("a","c","d","e","j"), g1)
sg2 <- subGraph(c("f","h","i"), g1)
plot(g1, subGList=list(list(graph=sg1), list(graph=sg2)))


###################################################
# ---- chunk 14 ----
### code chunk number 13: edgeNames
###################################################
edgeNames(g1)
edgeNames(g1, recipEdges="distinct")


###################################################
# ---- chunk 15 ----
### code chunk number 14: defAttrs
###################################################
defAttrs <- getDefaultAttrs()


###################################################
# ---- chunk 16 ----
### code chunk number 15: defAttrs2
###################################################
plot(g1, attrs=list(node=list(label="foo", fillcolor="lightgreen"),
           edge=list(color="cyan"),
           graph=list(rankdir="LR")))


###################################################
# ---- chunk 17 ----
### code chunk number 16: baseLists
###################################################
nAttrs <- list()
eAttrs <- list()


###################################################
# ---- chunk 18 ----
### code chunk number 17: makeLabels1
###################################################
z <- strsplit(packageDescription("Rgraphviz")$Description, " ")[[1]]
z <- z[1:numNodes(g1)]
names(z) = nodes(g1)
nAttrs$label <- z


###################################################
# ---- chunk 19 ----
### code chunk number 18: makeLabels2
###################################################
eAttrs$label <- c("a~h"="Label 1", "c~h"="Label 2")


###################################################
# ---- chunk 20 ----
### code chunk number 19: makeLabels3
###################################################
attrs <- list(node=list(shape="ellipse", fixedsize=FALSE))


###################################################
# ---- chunk 21 ----
### code chunk number 20: figLabels
###################################################
plot(g1, nodeAttrs=nAttrs, edgeAttrs=eAttrs, attrs=attrs)


###################################################
# ---- chunk 22 ----
### code chunk number 21: edgeWeights
###################################################
ew <- as.character(unlist(edgeWeights(g1)))
ew <- ew[setdiff(seq(along=ew), removedEdges(g1))]
names(ew) <- edgeNames(g1)
eAttrs$label <- ew
## FIXME (wh 17.6.06): This does not work - see bug report:
## attrs$edge$labelfontsize="27"


###################################################
# ---- chunk 23 ----
### code chunk number 22: edgeWeightLabels
###################################################
plot(g1, nodeAttrs=nAttrs, edgeAttrs=eAttrs, attrs=attrs)


###################################################
# ---- chunk 24 ----
### code chunk number 23: colors
###################################################
## Specify node drawing color
nAttrs$color <- c(a="red", b="red", g="green", d="blue")

## Specify edge drawing color
eAttrs$color <- c("a~d"="blue", "c~h"="purple")

## Specify node fill color
nAttrs$fillcolor <- c(j="yellow")

## label color
nAttrs$fontcolor <- c(e="green", f="red")
eAttrs$fontcolor <- c("a~h"="green", "c~h"="brown")

nAttrs
eAttrs


###################################################
# ---- chunk 25 ----
### code chunk number 24: figColors
###################################################
plot(g1, nodeAttrs=nAttrs, attrs=attrs)


###################################################
# ---- chunk 26 ----
### code chunk number 25: nodeShapes
###################################################
attrs$node$shape <- "ellipse"
nAttrs$shape <- c(g="box", f="circle", j="box", a="plaintext")


###################################################
# ---- chunk 27 ----
### code chunk number 26: figNodeShapes
###################################################
plot(g1, attrs=attrs, nodeAttrs=nAttrs)


###################################################
# ---- chunk 28 ----
### code chunk number 27: getLists1
###################################################
nodes <- buildNodeList(g1)
edges <- buildEdgeList(g1)


###################################################
# ---- chunk 29 ----
### code chunk number 28: getLists2
###################################################
nodes[[1]]
edges[[1]]


###################################################
# ---- chunk 30 ----
### code chunk number 29: buildwithAttrs
###################################################
nodes <- buildNodeList(g1, nodeAttrs=nAttrs, defAttrs=defAttrs$node)
edges <- buildEdgeList(g1, edgeAttrs=eAttrs, defAttrs=defAttrs$edge)
nodes[[1]]
edges[[1]]


###################################################
# ---- chunk 31 ----
### code chunk number 30: arrowheads
###################################################
for(j in c("a~e", "a~h"))
  edges[[j]]@attrs$arrowhead <- "open"


###################################################
# ---- chunk 32 ----
### code chunk number 31: plotbuild
###################################################
vv <- agopen(name="foo", nodes=nodes, edges=edges, attrs=attrs, 
  edgeMode="undirected")
plot(vv)
