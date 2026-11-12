# gloss bench figure tree-006
# source: ggtreeSpace (vignette)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- chunk 1 ----
## ----setup, include=FALSE-----------------------------------------------------
knitr::opts_chunk$set(echo = TRUE)

# ---- chunk 2 ----
## ----installation, eval = FALSE-----------------------------------------------
# if (!require("BiocManager"))
# #     install.packages("BiocManager") # [bench: install call removed]
# # BiocManager::install("ggtreeSpace") # [bench: install call removed]

# ---- chunk 3 ----
## ----library, message=FALSE, warning=FALSE------------------------------------
library(ggtree)
library(ggtreeSpace)
library(phytools)
library(ggplot2)
library(dplyr)

# ---- chunk 4 ----
## ----example0-----------------------------------------------------------------
tr <- rtree(15)
td <- fastBM(tr, nsim = 2)

tda1 <- fastAnc(tr, td[, 1])
tda2 <- fastAnc(tr, td[, 2])
tda <- cbind(tda1, tda2)
tdn <- rbind(td, tda)


trd <- fortify(tr)
trd <- trd |>
        select(-c("x", "y")) |>
        mutate(
            x = tdn[, 1],
            y = tdn[, 2])

p <- ggtree(tr = trd,
            layout = "unrooted") +
        theme_bw()

p
