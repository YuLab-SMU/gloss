# gloss bench figure tree-026
# source: ggtreeExtra::geom_fruit_list (topic)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(ggtreeExtra)
# ---- chunk 1 ----
### Name: geom_fruit_list
### Title: geom_fruit_list
### Aliases: geom_fruit_list

### ** Examples

library(ggplot2)
library(ggtree)
library(ggstar)
library(ggnewscale)
set.seed(1024)
tr <- rtree(100)
dt <- data.frame(id=tr$tip.label, value=abs(rnorm(100)), group=c(rep("A",50),rep("B",50)))
df <- dt
dtf <- dt
colnames(df)[[3]] <- "group2"
colnames(dtf)[[3]] <- "group3"

p <- ggtree(tr, layout="fan", open.angle=0)
# first circle
p1 <- p + 
      geom_fruit(
          data=dt,
          geom=geom_bar,
          mapping=aes(y=id, x=value, fill=group),
          orientation="y",
          stat="identity"
      ) + 
      new_scale_fill()
# second circle
fruitlist <- geom_fruit_list(
                 geom_fruit(
                     data = df,
                     geom = geom_bar,
                     mapping = aes(y=id, x=value, fill=group2),
                     orientation = "y",
                     stat = "identity"
                 ),
                 scale_fill_manual(values=c("blue", "red")),
                 new_scale_fill(),
                 geom_fruit(
                     data = dt,
                     geom = geom_star,
                     mapping = aes(y=id, x=value, fill=group),
                     size = 2.5,
                     color = NA,
                     starstroke = 0
                 )
             )

p2 <- p1 + fruitlist + new_scale_fill() 
# third circle
p3 <- p2 + 
      geom_fruit(
          data=dtf,
          geom=geom_bar,
          mapping = aes(y=id, x=value, fill=group3),
          orientation = "y",
          stat = "identity"
      ) +
      scale_fill_manual(values=c("#00AED7", "#009E73"))
p3 
