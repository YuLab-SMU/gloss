# gloss bench figure exts-005
# source: ggnetwork (examples)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(ggnetwork)
# ---- chunk 1 ----
### Name: geom_edgetext
### Title: Label the edges of a network.
### Aliases: geom_edgetext geom_edgelabel

### ** Examples

if (require(network) && require(sna)) {
  data(flo, package = "network")
  n <- network(flo, directed = FALSE)

  # arbitrary categorical edge attribute
  e <- sample(letters[ 1:4 ], network.edgecount(n), replace = TRUE)
  set.edge.attribute(n, "type", e)

  # with labelled edges
  ggplot(n, aes(x, y, xend = xend, yend = yend)) +
    geom_edges(aes(colour = type)) +
    geom_edgetext(aes(label = type, colour = type)) +
    geom_nodes(size = 4, colour = "grey50") +
    theme_blank()

  # label only a subset of all edges with arbitrary symbol
  edge_type <- function(x) {
    x[ x$type == "a", ]
  }
  ggplot(n, aes(x, y, xend = xend, yend = yend)) +
    geom_edges() +
    geom_edgetext(label = "=", data = edge_type) +
    geom_nodes(size = 4, colour = "grey50") +
    theme_blank()
}
