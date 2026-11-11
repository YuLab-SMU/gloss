# gloss bench figure tree-020
# source: 04_ggtree_visualization.Rmd (book)
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
library("ape")
library("grid")
library("ggplot2")
library("cowplot")
library("treeio")
library("ggtree")
# ---- chunk 2 ----

library("treeio")
library("ggtree")

nwk <- system.file("extdata", "sample.nwk", package="treeio")
tree <- read.tree(nwk)

aplot::plot_list(
    ggplot(tree, aes(x, y)) + geom_tree() + theme_tree(),
    ggtree(tree, color="firebrick", size=2, linetype="dotted"),
    ggtree(tree, ladderize=FALSE),
    ggtree(tree, branch.length="none"),
    ncol=4, tag_levels='A')
# ---- chunk 3 ----
library(ggtree)
library(cowplot)

set.seed(2017-02-16)
tree <- rtree(50)
p1 <- ggtree(tree, layout="circular")
p2 <- ggtree(tree, layout="fan", open.angle=120)
#p1 <- ggplotify::as.ggplot(p1, scale=1.05)
#p2 <- ggplotify::as.ggplot(p2, scale=1.05)

playout <- plot_grid(
  ggtree(tree), # + ggtitle("rectangular layout")+theme(plot.title = element_text(hjust = 0.5)),
  ggtree(tree, layout="roundrect"),
  ggtree(tree, layout="slanted"), # + ggtitle("slanted layout")+theme(plot.title = element_text(hjust = 0.5)),
  ggtree(tree, layout="ellipse"),
  p1, # + ggtitle("circular layout")+theme(plot.title = element_text(hjust = 0.5), plot.margin = unit(c(0,0,0,0), "lines")),
  p2, # + ggtitle("fan layout")+theme(plot.title = element_text(hjust = 0.5), plot.margin = unit(c(0,0,0,0), "lines")),
  ggtree(tree, layout="equal_angle"),
  ggtree(tree, layout="daylight"),  
  ggtree(tree, branch.length='none'),
  ggtree(tree, layout="ellipse", branch.length="none"),
  ggtree(tree, branch.length='none', layout='circular'),
  ggtree(tree, layout="daylight", branch.length = 'none'),
  ncol=4, labels = LETTERS[1:12])
# save(playout, file="data/playout.rda")
playout
# ---- chunk 4 ----
# tree_angle <- grid::grid.grabExpr(print(ggtree(tree), newpage=TRUE, vp = grid::viewport(angle=-30, width=.9, height=.9)))
tree_angle <- ggplotify::as.ggplot(ggtree(tree), angle=-30, scale=.9)
# ---- chunk 5 ----
plot_grid(
    ggtree(tree) + scale_x_reverse(),
    ggtree(tree) + coord_flip(),
    ggtree(tree) + layout_dendrogram(),
    tree_angle,
    ggtree(tree, layout='slanted') + coord_flip(),
    ggtree(tree, layout='slanted', branch.length='none') + layout_dendrogram(),
    ggtree(tree, layout='circular') + xlim(-10, NA),
#    ggtree(tree) + scale_x_reverse() + coord_polar(theta='y'),
#    ggtree(tree) + scale_x_reverse(limits=c(15, 0)) + coord_polar(theta='y'),
    ggtree(tree) + layout_inward_circular(),
    ggtree(tree) + layout_inward_circular(xlim=15),
    ncol=3, labels=LETTERS[1:9])

# ---- chunk 6 ----
beast_file <- system.file("examples/MCC_FluA_H3.tree", 
                          package="ggtree")
beast_tree <- read.beast(beast_file)
ggtree(beast_tree, mrsd="2013-01-01") + theme_tree2()
# ---- chunk 7 ----
NAG_file <- system.file("examples/NAG_inHA1.txt", package="ggtree")

NAG.df <- read.table(NAG_file, sep="\t", header=FALSE, 
                     stringsAsFactors = FALSE)
NAG <- NAG.df[,2]
names(NAG) <- NAG.df[,1]

## separate the tree by host species
tip <- as.phylo(beast_tree)$tip.label
beast_tree <- groupOTU(beast_tree, tip[grep("Swine", tip)], 
                       group_name = "host")

p <- ggtree(beast_tree, aes(color=host), mrsd="2013-01-01", 
            yscale = "label", yscale_mapping = NAG) + 
  theme_classic() + theme(legend.position='none') +
  scale_color_manual(values=c("blue", "red"), 
                     labels=c("human", "swine")) +
  ylab("Number of predicted N-linked glycosylation sites")

## (optional) add more annotations to help interpretation
p + geom_nodepoint(color="grey", size=3, alpha=.8) +
  geom_rootpoint(color="black", size=3) +
  geom_tippoint(size=3, alpha=.5) + 
  annotate("point", 1992, 5.6, size=3, color="black") +
  annotate("point", 1992, 5.4, size=3, color="grey") +
  annotate("point", 1991.6, 5.2, size=3, color="blue") +
  annotate("point", 1992, 5.2, size=3, color="red") + 
  annotate("text", 1992.3, 5.6, hjust=0, size=4, label="Root node") +
  annotate("text", 1992.3, 5.4, hjust=0, size=4, 
           label="Internal nodes") +
  annotate("text", 1992.3, 5.2, hjust=0, size=4,
           label="Tip nodes (blue: human; red: swine)")
# ---- chunk 8 ----

cowplot::plot_grid(
    ggtree(tree) + geom_treescale(),
    ggtree(tree)+geom_treescale(x=0, y=45, width=1, color='red'),
    ggtree(tree)+geom_treescale(fontsize=6, linesize=2, offset=1),
    ggtree(tree) + theme_tree2(),
    ncol=2, labels=LETTERS[1:4])
# ---- chunk 9 ----
p1 <- ggtree(tree) + geom_point(aes(shape=isTip, color=isTip), size=3)

p <- ggtree(tree) + geom_nodepoint(color="#b5e521", alpha=1/4, size=10)
p2 <- p + geom_tippoint(color="#FDAC4F", shape=8, size=3)

plot_list(p1, p2, ncol=2, tag_levels='A')
# ---- chunk 10 ----
p1 <- p + geom_tiplab(size=3, color="purple")
p2 <- ggtree(tree, layout="circular") + geom_tiplab(aes(angle=angle), color='blue')
p2 = ggplotify::as.ggplot(p2 + ggimage::theme_transparent(), scale=1.3, hjust=-.1, vjust=.05)
p3 <- ggtree(tree) + geom_tiplab(as_ylab=TRUE, color='firebrick')
plot_list(p1, p2, p3, ncol=3, tag_levels='A', widths=c(1.1, 2, 1))
