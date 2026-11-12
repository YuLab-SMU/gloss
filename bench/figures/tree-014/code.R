# gloss bench figure tree-014
# source: 13_ggtree_gallery.Rmd (book)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----


require(ape)
require(Biostrings)
## p_load(OutbreakTools)
require(igraph)
require(phylobase)

require(emojifont)
require(ggplot2)
require(dplyr)
require(kableExtra)
require(tidytree)
require(treeio)
require(ggtree)

require(cowplot)
require(patchwork)
require(aplot)

require(phytools)
require(hexbin)
require(TDbook)
require(ggimage)
require(phyloseq)
require(treemap)
require(ggtreeExtra)
require(ggstar)
require(MicrobiotaProcess)
require(tanggle)
require(gggenes)
require(ggtext)
require(ggbreak)
require(rotl)
require(gridSVG)
require(data.tree)
require(rsvg)

# ---- conflicted.R ----
require(conflicted)

conflict_prefer("expand", "ggtree")
conflict_prefer("rotate", "ggtree")
conflict_prefer("mask", "treeio")
conflict_prefer("parent", "treeio")
conflict_prefer("ancestor", "treeio")
conflict_prefer("get.data", "treeio")
conflict_prefer("drop.tip", "treeio")
conflict_prefer("read.newick", "treeio")
conflict_prefer("MRCA", "tidytree")

conflict_prefer("filter", "dplyr")
conflict_prefer("rename", "dplyr")
conflict_prefer("collapse", "dplyr")
conflict_prefer("intersect", "dplyr")
conflict_prefer("union", "dplyr")
conflict_prefer("slice", "dplyr")
conflict_prefer("strsplit", "base")
conflict_prefer("paste", "base")
conflict_prefer("geom_errorbarh", "ggplot2")
conflict_prefer("tax_table", "MicrobiotaProcess")

conflict_prefer("as.data.frame", "BiocGenerics")
# ---- software-link.R ----

require(yulab.utils)

# pkg name in bold
options("yulab.utils_pkgfmt" = '**%s**') 

pkg_archaeopteryx <- mypkg("Archaeopteryx", "https://sites.google.com/site/cmzmasek/home/software/archaeopteryx")
pkg_astral <- mypkg("ASTRAL", "https://github.com/smirarab/ASTRAL")
pkg_atv <- mypkg("ATV", "http://phylogeny.lirmm.fr/phylo_cgi/one_task.cgi?task_type=atv")
pkg_baseml <- mypkg("BASEML", "http://abacus.gene.ucl.ac.uk/software/paml.html")
pkg_beast <- mypkg("BEAST", "http://beast2.org/")
pkg_codeml <- mypkg("CODEML", "http://abacus.gene.ucl.ac.uk/software/paml.html")
pkg_devout <- mypkg("devout", "https://github.com/coolbutuseless/devout")
pkg_epa <- mypkg("EPA", "http://sco.h-its.org/exelixis/web/software/epa/index.html")
pkg_evolview <- mypkg("EvolView", "https://www.evolgenius.info/evolview/")
pkg_figtree <- mypkg("FigTree", "http://beast.community/figtree")
pkg_hyphy <- mypkg("HyPhy", "https://veg.github.io/hyphy-site/")
pkg_itol <- mypkg("iTOL", "https://itol.embl.de/")
pkg_mega <- mypkg("MEGA", "https://www.megasoftware.net/")
pkg_mothur <- mypkg("mothur", "http://mothur.org/")
pkg_mrbayes <- mypkg("MrBayes", "http://nbisweden.github.io/MrBayes/")
pkg_paml <- mypkg("PAML", "http://abacus.gene.ucl.ac.uk/software/paml.html")
pkg_paup <- mypkg("PAUP\\*", "https://paup.phylosolutions.com/")
pkg_phyldog <- mypkg("PHYLDOG", "http://pbil.univ-lyon1.fr/software/phyldog/") 
pkg_phylip <- mypkg("PHYLIP", "https://evolution.genetics.washington.edu/phylip.html")
pkg_phyloch <- mypkg("PHYLOCH", "http://www.christophheibl.de/Rpackages.html")
pkg_phyml <- mypkg("PhyML", "http://www.atgc-montpellier.fr/phyml/")
pkg_pplacer <- mypkg("PPLACER", "http://matsen.fhcrc.org/pplacer/")
pkg_pyrotagger <- mypkg("PyroTagger", "http://pyrotagger.jgi-psf.org/")
pkg_qiime <- mypkg("QIIME", "http://qiime.org/")
pkg_r8s <- mypkg("r8s", "http://loco.biosci.arizona.edu/r8s/")
pkg_raxml <- mypkg("RAxML", "http://evomics.org/learning/phylogenetics/raxml/")
pkg_revbayes <- mypkg("RevBayes", "http://revbayes.github.io/intro.html")
pkg_treedataverse <- mypkg("treedataverse", "https://github.com/YuLab-SMU/treedataverse")
pkg_treedyn <- mypkg("TreeDyn", "http://www.treedyn.org/")
pkg_treeview <- mypkg("TreeView", "http://en.bio-soft.net/tree/TreeView.html")

theme_set(theme_grey())


badge_version <- function(pkg, color="green") {
    v <- packageVersion(pkg)
    url <- paste0("https://github.com/YuLab-SMU/", pkg)
    badger::badge_custom(pkg, v, color, url)
}


## based on https://bookdown.org/yihui/rmarkdown-cookbook/fig-process.html

svg2png <- function(path, options) {
    if (!grepl('[.]svg$', path)) return(path)
    
    if (file.size(path)/1000000 < 1.2) {
        ## less than 1.2M
        return(path)
    }

    output <- sub(".svg$", ".png", path)
    system2("convert", paste("-density 150", path, output))
    file.remove(path)
    return(output)
}


trim_fig <- function(path, options) {
    output <- sub(".png$", "-crop.png", path)
    system2("convert", paste("-trim", path, output))
    file.remove(path)
    return(output)
}

squote <- function(string) {
    if (knitr::is_latex_output()) {
        left_quote_mark <- "`"
    } else {
        left_quote_mark <- "'"
    }

    right_quote_mark <- "'"

    fmt <- "%s%s%s"
    sprintf(fmt, left_quote_mark, string, right_quote_mark)
}
# ---- chunk 1 ----
library(TDbook)
library(tibble)
library(tidyr)
library(Biostrings)
library(treeio)
library(ggplot2)
library(ggtree)

# loaded from TDbook package
tree <- tree_HPV58

clade <- c(A3 = 92, A1 = 94, A2 = 108, B1 = 156, 
            B2 = 159, C = 163, D1 = 173, D2 = 176)
tree <- groupClade(tree, clade)
cols <- c(A1 = "#EC762F", A2 = "#CA6629", A3 = "#894418", B1 = "#0923FA", 
         B2 = "#020D87", C = "#000000", D1 = "#9ACD32",D2 = "#08630A")

## visualize the tree with tip labels and tree scale
p <- ggtree(tree, aes(color = group), ladderize = FALSE) %>% 
    rotate(rootnode(tree)) + 
    geom_tiplab(aes(label = paste0("italic('", label, "')")), 
                parse = TRUE, size = 2.5) +
    geom_treescale(x = 0, y = 1, width = 0.002) + 
    scale_color_manual(values = c(cols, "black"), 
                na.value = "black", name = "Lineage",
                breaks = c("A1", "A2", "A3", "B1", "B2", "C", "D1", "D2")) +
    guides(color = guide_legend(override.aes = list(size = 5, shape = 15))) +
    theme_tree2(legend.position = c(.1, .88))
## Optional
## add labels for monophyletic (A, C and D) and paraphyletic (B) groups 
dat <- tibble(node = c(94, 108, 131, 92, 156, 159, 163, 173, 176,172),
              name = c("A1", "A2", "A3", "A", "B1", 
                        "B2", "C", "D1", "D2", "D"),
              offset = c(0.003, 0.003, 0.003, 0.00315, 0.003, 
                        0.003, 0.0031, 0.003, 0.003, 0.00315),
              offset.text = c(-.001, -.001, -.001, 0.0002, -.001, 
                        -.001, 0.0002, -.001, -.001, 0.0002),
              barsize = c(1.2, 1.2, 1.2, 2, 1.2, 1.2, 3.2, 1.2, 1.2, 2),
              extend = list(c(0, 0.5), 0.5, c(0.5, 0), 0, c(0, 0.5), 
                        c(0.5, 0), 0, c(0, 0.5), c(0.5, 0), 0)
            ) %>% 
       dplyr::group_split(barsize)

p <- p +
     geom_cladelab(
         data = dat[[1]],
         mapping = aes(
             node = node,
             label = name,
             color = group,
             offset = offset,
             offset.text = offset.text,
             extend = extend
         ),
         barsize = 1.2,
         fontface = 3,
         align = TRUE
     ) +
     geom_cladelab(
         data = dat[[2]],
         mapping = aes(
             node = node,
             label = name,
             offset = offset,
             offset.text =offset.text,
             extend = extend
         ),
         barcolor = "darkgrey",
         textcolor = "darkgrey",
         barsize = 2,
         fontsize = 5,
         fontface = 3,
         align = TRUE
     ) +
     geom_cladelab(
         data = dat[[3]],
         mapping = aes(
             node = node,
             label = name,
             offset = offset,
             offset.text = offset.text,
             extend = extend
         ),
         barcolor = "darkgrey",
         textcolor = "darkgrey",
         barsize = 3.2,
         fontsize = 5,
         fontface = 3,
         align = TRUE
     ) +
     geom_strip(65, 71, "italic(B)", color = "darkgrey", 
                offset = 0.00315, align = TRUE, offset.text = 0.0002, 
                barsize = 2, fontsize = 5, parse = TRUE)

## Optional
## display support values
p <- p + geom_nodelab(aes(subset = (node == 92), label = "*"), 
                    color = "black", nudge_x = -.001, nudge_y = 1) +
    geom_nodelab(aes(subset = (node == 155), label = "*"), 
                    color = "black", nudge_x = -.0003, nudge_y = -1) +
    geom_nodelab(aes(subset = (node == 158), label = "95/92/1.00"), 
                    color = "black", nudge_x = -0.0001, 
                    nudge_y = -1, hjust = 1) +
    geom_nodelab(aes(subset = (node == 162), label = "98/97/1.00"), 
                    color = "black", nudge_x = -0.0001, 
                    nudge_y = -1, hjust = 1) +
    geom_nodelab(aes(subset = (node == 172), label = "*"), 
                    color = "black", nudge_x = -.0003, nudge_y = -1) 
# ---- chunk 2 ----
## extract accession numbers from tip labels
tl <- tree$tip.label
acc <- sub("\\w+\\|", "", tl)
names(tl) <- acc

## writeXStringSet(tipseq_aln, file = "data/HPV58_aln.fas")
#tipseq_aln <- readDNAStringSet("data/HPV58_aln.fas")
tipseq_aln <- TDbook::dna_HPV58_aln %>% 
              as.character %>%
              lapply(., paste0, collapse = "") %>%
              unlist() %>%
              Biostrings::DNAStringSet()
# ---- chunk 3 ----
## calculate pairwise hamming distances among sequences
tipseq_dist <- stringDist(tipseq_aln, method = "hamming")

## calculate the percentage of differences
tipseq_d <- as.matrix(tipseq_dist) / width(tipseq_aln[1]) * 100

## convert the matrix to a tidy data frame for facet_plot
dd <- as_tibble(tipseq_d)
dd$seq1 <- rownames(tipseq_d)
td <- gather(dd,seq2, dist, -seq1)
td$seq1 <- tl[td$seq1]
td$seq2 <- tl[td$seq2]

g <- p$data$group
names(g) <- p$data$label
td$clade <- g[td$seq2] 

## visualize the sequence differences using dot plot and line plot
## and align the sequence difference plot to the tree using facet_plot
p2 <- p + geom_facet(panel = "Sequence Distance", 
            data = td, geom = geom_point, alpha = .6, 
            mapping = aes(x = dist, color = clade, shape = clade)) +
    geom_facet(panel = "Sequence Distance", 
            data = td, geom = geom_path, alpha = .6, 
            mapping=aes(x = dist, group = seq2, color = clade)) + 
    scale_shape_manual(values = 1:8, guide = FALSE) 

print(p2)
