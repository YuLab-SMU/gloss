# gloss bench figure tree-049
# source: 02_tidytree.Rmd (book)
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
library("ape")
library("tidytree")
library(treeio)
# ---- chunk 3 ----
options(show_data_for_treedata = FALSE)
# ---- chunk 4 ----
library(ape)
set.seed(2017)
tree <- rtree(4)
tree
x <- as_tibble(tree)
x
# ---- chunk 5 ----
as.phylo(x)
# ---- chunk 6 ----
d <- tibble(label = paste0('t', 1:4),
            trait = rnorm(4))

y <- full_join(x, d, by = 'label')
y
# ---- chunk 7 ----
as.treedata(y)
# ---- chunk 8 ----
y %>% as.treedata %>% as_tibble
# ---- chunk 9 ----
child(y, 5)
parent(y, 2)
offspring(y, 5)
ancestor(y, 2)
sibling(y, 2)
MRCA(y, 2, 3)
# ---- chunk 10 ----
child(tree, 5)
# ---- chunk 11 ----
beast_file <- system.file("examples/MCC_FluA_H3.tree", package="ggtree")
rst_file <- system.file("examples/rst", package="ggtree")
mlc_file <- system.file("examples/mlc", package="ggtree")
beast_tree <- read.beast(beast_file)
codeml_tree <- read.codeml(rst_file, mlc_file)

merged_tree <- merge_tree(beast_tree, codeml_tree)
merged_tree
# ---- chunk 12 ----
library(dplyr)
df <- merged_tree %>% 
  as_tibble() %>%
  select(dN_vs_dS, dN, dS, rate) %>%
  subset(dN_vs_dS >=0 & dN_vs_dS <= 1.5) %>%
  tidyr::gather(type, value, dN_vs_dS:dS)
df$type[df$type == 'dN_vs_dS'] <- 'dN/dS'
df$type <- factor(df$type, levels=c("dN/dS", "dN", "dS"))
ggplot(df, aes(rate, value)) + geom_hex() + 
  facet_wrap(~type, scale='free_y') 
# ---- chunk 13 ----
phylo <- as.phylo(beast_tree)
N <- Nnode2(phylo)
d <- tibble(node = 1:N, fake_trait = rnorm(N), another_trait = runif(N))
fake_tree <- treedata(phylo = phylo, data = d)
triple_tree <- merge_tree(merged_tree, fake_tree)
triple_tree
# ---- chunk 14 ----
library(ape)
data(woodmouse)
d <- dist.dna(woodmouse)
tr <- nj(d)
bp <- boot.phylo(tr, woodmouse, function(x) nj(dist.dna(x)))
bp2 <- tibble(node=1:Nnode(tr) + Ntip(tr), bootstrap = bp)
full_join(tr, bp2, by="node")
# ---- chunk 15 ----
file <- system.file("extdata/BEAST", "beast_mcc.tree", package="treeio")
beast <- read.beast(file)
x <- tibble(label = as.phylo(beast)$tip.label, trait = rnorm(Ntip(beast)))
full_join(beast, x, by="label")
# ---- chunk 16 ----
nwk <- '(((((((A:4,B:4):6,C:5):8,D:6):3,E:21):10,((F:4,G:12):14,H:8):13):
        13,((I:5,J:2):30,(K:11,L:11):2):17):4,M:56);'
tree <- read.tree(text=nwk)

groupClade(as_tibble(tree), c(17, 21))
# ---- chunk 17 ----
set.seed(2017)
tr <- rtree(4)
x <- as_tibble(tr)
## the input nodes can be node ID or label
groupOTU(x, c('t1', 't4'), group_name = "fake_group")
# ---- chunk 18 ----
groupOTU(tr, c('t2', 't4'), group_name = "fake_group") %>%
  as_tibble
# ---- chunk 19 ----
cls <- list(c1=c("A", "B", "C", "D", "E"),
            c2=c("F", "G", "H"),
            c3=c("L", "K", "I", "J"),
            c4="M")

as_tibble(tree) %>% groupOTU(cls)
# ---- chunk 20 ----
library(ggtree)
library(treeio)
library(tidytree)
library(TDbook)

# load `tree_boots`, `df_tip_data`, and `df_inode_data` from 'TDbook'

trda <- tree_boots %>% 
        left_join(df_tip_data, by=c("label" = "Newick_label")) %>% 
        left_join(df_inode_data, by=c("label" = "newick_label"))
trda
# ---- chunk 21 ----
# reroot
trda2 <- root(trda, outgroup = "Suricata_suricatta", edgelabel = TRUE)
# The original tree
p1 <- trda %>%
      ggtree() +
      geom_nodelab(
        mapping = aes(
          x = branch,
          label = bootstrap
        ),
        nudge_y = 0.36
      ) +
      xlim(-.1, 4.5) +
      geom_tippoint(
        mapping = aes(
          shape = trophic_habit, 
          color = trophic_habit, 
          size = mass_in_kg
        )
      ) +
      scale_size_continuous(range = c(3, 10)) +
      geom_tiplab(
        offset = .14, 
      ) +
      geom_nodelab(
        mapping = aes(
          label = vernacularName.y, 
          fill = posterior
        ),
        geom = "label"
      ) + 
      scale_fill_gradientn(colors = RColorBrewer::brewer.pal(3, "YlGnBu")) +
      theme(legend.position = "right")  

# after reroot
p2 <- trda2 %>%
      ggtree() +
      geom_nodelab(
        mapping = aes(
          x = branch,
          label = bootstrap
        ),
        nudge_y = 0.36
      ) +
      xlim(-.1, 5.5) +
      geom_tippoint(
        mapping = aes(
          shape = trophic_habit,
          color = trophic_habit,
          size = mass_in_kg
        )
      ) +
      scale_size_continuous(range = c(3, 10)) +
      geom_tiplab(
        offset = .14,
      ) +
      geom_nodelab(
        mapping = aes(
          label = vernacularName.y,
          fill = posterior
        ),
        geom = "label"
      ) +
      scale_fill_gradientn(colors = RColorBrewer::brewer.pal(3, "YlGnBu")) +
      theme(legend.position = "right")

plot_list(p1, p2, tag_levels='A', ncol=2)
# ---- chunk 22 ----
p1 <- ggtree(merged_tree) + theme_tree2()
p2 <- ggtree(rescale_tree(merged_tree, 'dN')) + theme_tree2()
p3 <- ggtree(rescale_tree(merged_tree, 'rate')) + theme_tree2()

plot_list(p1, p2, p3, ncol=3, tag_levels='A')
# ---- chunk 23 ----
f <- system.file("extdata/NHX", "phyldog.nhx", package="treeio")
nhx <- read.nhx(f)
to_drop <- c("Physonect_sp_@2066767",
            "Lychnagalma_utricularia@2253871",
            "Kephyes_ovata@2606431")
p1 <- ggtree(nhx) + geom_tiplab(aes(color = label %in% to_drop)) +
  scale_color_manual(values=c("black", "red")) + xlim(0, 0.8)

nhx_reduced <- drop.tip(nhx, to_drop)
p2 <- ggtree(nhx_reduced) + geom_tiplab() + xlim(0, 0.8)  
plot_list(p1, p2, ncol=2, tag_levels = "A")
# ---- chunk 24 ----
beast_file <- system.file("examples/MCC_FluA_H3.tree", package="ggtree")
beast_tree <- read.beast(beast_file)

p1 = ggtree(beast_tree) + 
  geom_tiplab(offset=.05) +  xlim(0, 40) + theme_tree2()

tree2 = tree_subset(beast_tree, "A/Swine/HK/168/2012", levels_back=4)  
p2 <- ggtree(tree2, aes(color=group)) +
  scale_color_manual(values = c("black", "red"), guide = 'none') +
  geom_tiplab(offset=.2) +  xlim(0, 4.5) + theme_tree2() 

p3 <- p2 +   
  geom_point(aes(fill = rate), shape = 21, size = 4) +
  scale_fill_continuous(low = 'blue', high = 'red') +
  xlim(0,5) + theme(legend.position = 'right')

p4 <- ggtree(tree2, aes(color=group), 
          root.position = as.phylo(tree2)$root.edge) +
  geom_tiplab() + xlim(18, 24) + 
  scale_color_manual(values = c("black", "red"), guide = 'none') +
  theme_tree2()

p5 <- p4 + 
  geom_rootedge() + xlim(0, 50) 

plot_list(p1, p2, p3, p4, p5, 
        design="AABBCC\nAADDEE", tag_levels='A')
