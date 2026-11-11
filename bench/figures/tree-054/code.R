# gloss bench figure tree-054
# source: A-app-faq.Rmd (book)
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
library(ggplot2)
library(ggtree)
## example tree from https://support.bioconductor.org/p/72398/
tree<-read.tree(text="(Organism1.006G249400.1:0.03977,(Organism2.022118m:0.01337,(Organism3.J34265.1:0.00284,Organism4.G02633.1:0.00468)0.51:0.0104):0.02469);")
p <- ggtree(tree) + geom_tiplab()
p2 <- ggtree(tree) + geom_tiplab() + xlim(0, 0.1)
p3 <- p + coord_cartesian(clip = 'off') + 
  theme_tree2(plot.margin=margin(6, 140, 6, 6))
plot_list(p, p2, p3, ncol=3, tag_levels="A")
# ---- chunk 2 ----
tree <- read.tree(text = "((A, B), (C, D));")
d <- data.frame(label = LETTERS[1:4], 
                label2 = c("sunflower", "tree", "snail", "mushroom"))

## rename_taxa use 1st column as key and 2nd column as value by default                
## rename_taxa(tree, d)
rename_taxa(tree, d, label, label2) %>% write.tree
# ---- chunk 3 ----
tree2 <- full_join(tree, d, by = "label")
tree2
# ---- chunk 4 ----
p <- ggtree(tree) + xlim(NA, 3)
p1 <- p + geom_tiplab()

## the following command will produce an identical figure of p2
## ggtree(tree2) + geom_tiplab(aes(label = label2))
p2 <- p %<+% d + geom_tiplab(aes(label=label2))
plot_list(p1, p2, ncol=2, tag_levels = "A")
# ---- chunk 5 ----
# ---- chunk 6 ----
library(ggrepel)
library(ggtree)
raxml_file <- system.file("extdata/RAxML", 
                    "RAxML_bipartitionsBranchLabels.H3", package="treeio")
raxml <- read.raxml(raxml_file)
ggtree(raxml) + geom_label_repel(aes(label=bootstrap, fill=bootstrap)) + 
  theme(legend.position = c(.1, .8)) + scale_fill_viridis_c()
