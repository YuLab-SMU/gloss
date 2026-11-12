# gloss bench figure tree-061
# source: 07_ggtree_tree_with_data.Rmd (book)
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
library(knitr)
opts_chunk$set(message=FALSE, warning=FALSE, eval=TRUE, echo=TRUE, cache=TRUE)
# ---- chunk 2 ----
library(ggimage)
library(ggtree)
library(TDbook)

# load `tree_boots`, `df_tip_data`, and `df_inode_data` from 'TDbook'
p <- ggtree(tree_boots) %<+% df_tip_data + xlim(-.1, 4)
p2 <- p + geom_tiplab(offset = .6, hjust = .5) +
    geom_tippoint(aes(shape = trophic_habit, color = trophic_habit, 
                size = mass_in_kg)) + 
    theme(legend.position = "right") + 
    scale_size_continuous(range = c(3, 10))

p2 %<+% df_inode_data + 
    geom_label(aes(label = vernacularName.y, fill = posterior)) + 
    scale_fill_gradientn(colors = RColorBrewer::brewer.pal(3, "YlGnBu"))
# ---- chunk 3 ----
library(ggtree)
library(TDbook)

## load `tree_nwk`, `df_info`, `df_alleles`, and `df_bar_data` from 'TDbook'
tree <- tree_nwk
snps <- df_alleles
snps_strainCols <- snps[1,] 
snps<-snps[-1,] # drop strain names
colnames(snps) <- snps_strainCols

gapChar <- "?"
snp <- t(snps)
lsnp <- apply(snp, 1, function(x) {
        x != snp[1,] & x != gapChar & snp[1,] != gapChar
    })
lsnp <- as.data.frame(lsnp)
lsnp$pos <- as.numeric(rownames(lsnp))
lsnp <- tidyr::gather(lsnp, name, value, -pos)
snp_data <- lsnp[lsnp$value, c("name", "pos")]

## visualize the tree 
p <- ggtree(tree) 

## attach the sampling information data set 
## and add symbols colored by location
p <- p %<+% df_info + geom_tippoint(aes(color=location))

## visualize SNP and Trait data using dot and bar charts,
## and align them based on tree structure
p + geom_facet(panel = "SNP", data = snp_data, geom = geom_point, 
               mapping=aes(x = pos, color = location), shape = '|') +
    geom_facet(panel = "Trait", data = df_bar_data, geom = geom_col, 
                aes(x = dummy_bar_value, color = location, 
                fill = location), orientation = 'y', width = .6) +
    theme_tree2(legend.position=c(.05, .85))
