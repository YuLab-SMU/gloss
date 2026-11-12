# gloss bench figure tree-046
# source: 06_ggtree_manipulation.Rmd (book)
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
library("ggplot2")
library("cowplot")
library("ggtree")
expand <- ggtree::expand
rotate <- ggtree::rotate
flip <- ggtree::flip
# ---- chunk 2 ----
treeman <- matrix(c(
  "collapse", "Collapse a selecting clade",
  "expand", "Expand collapsed clade",
  "flip", "Exchange position of 2 clades that share a parent node",
  "groupClade", "Grouping clades",
  "groupOTU", "Grouping OTUs by tracing back to the most recent common ancestor",
  "identify", "Interactive tree manipulation",
  "rotate", "Rotating a selected clade by 180 degrees",
  "rotate_tree", "Rotating circular layout tree by a specific angle",
  "scaleClade", "Zoom in or zoom out selecting clade",
  "open_tree", "Convert a tree to fan layout by specific open angle"
), ncol=2, byrow=TRUE)
treeman <- as.data.frame(treeman)
colnames(treeman) <- c("Function", "Description")
knitr::kable(treeman, caption = "Tree manipulation functions.", booktabs = T) %>%
  kable_styling(latex_options = c("striped", "hold_position"), full_width = T)
# ---- chunk 3 ----
library(ggtree)
nwk <- system.file("extdata", "sample.nwk", package="treeio")
tree <- read.tree(nwk)
p <- ggtree(tree) + geom_tiplab()
p2 <- viewClade(p, MRCA(p, "I", "L"))
plot_list(p, p2, ncol=2, tag_levels="A")
