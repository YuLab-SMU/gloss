# Case 2: RNA-seq Anti-PD-1 Melanoma Volcano Plot (2,400 genes + ggrepel) + Hallmark Pathway Enrichment
# Run from repo root: R_LIBS_USER=/nonexistent Rscript dev_docs/demo/cases/case2-rnaseq-volcano.R

suppressPackageStartupMessages({
  devtools::load_all(quiet = TRUE)
  library(ggplot2)
  library(ggrepel)
  library(patchwork)
})

set.seed(2026)

# 1. Realistic 2,400-gene Anti-PD-1 responder vs non-responder differential expression table
n_bg <- 2382L
bg_lfc <- rnorm(n_bg, mean = 0, sd = 0.72)
bg_p <- 10^(-rexp(n_bg, rate = 1.35) - abs(bg_lfc) * runif(n_bg, 0.3, 1.45))
bg_p <- pmin(1, pmax(1e-18, bg_p))
bg_df <- data.frame(
  gene = sprintf("GENE_%04d", seq_len(n_bg)),
  log2FoldChange = round(bg_lfc, 3),
  padj = signif(bg_p, 3),
  baseMean = round(exp(rnorm(n_bg, 5.2, 1.4)), 1),
  pathway = "Background",
  highlight_label = "",
  stringsAsFactors = FALSE
)

# 18 authentic melanoma immunotherapy signature & resistance genes
sig_df <- data.frame(
  gene = c("CXCL9", "CXCL10", "IFNG", "STAT1", "CD274", "PDCD1", "LAG3", "GZMB", "PRF1",
           "HLA-DRA", "IDO1", "GBP1", "CTNNB1", "WNT5A", "VEGFA", "AXL", "TGFB1", "B2M"),
  log2FoldChange = c(3.42, 3.18, 2.86, 2.21, 2.54, 2.38, 2.15, 2.68, 2.04,
                     1.89, 2.95, 2.12, -2.62, -2.41, -2.18, -2.79, -1.94, 1.72),
  padj = c(1.2e-15, 4.8e-14, 3.1e-12, 2.5e-09, 6.4e-11, 1.8e-09, 9.2e-08, 4.1e-11, 8.7e-08,
           3.4e-07, 1.9e-12, 5.5e-08, 2.1e-11, 8.3e-10, 6.7e-09, 1.5e-12, 3.9e-07, 2.8e-06),
  baseMean = c(1840, 2210, 412, 3150, 980, 520, 440, 1120, 760,
               4820, 1290, 1650, 2940, 810, 2380, 1420, 1960, 5410),
  pathway = c("IFN-gamma Response", "IFN-gamma Response", "IFN-gamma Response", "IFN-gamma Response",
              "T-Cell Exhaustion / PD-1", "T-Cell Exhaustion / PD-1", "T-Cell Exhaustion / PD-1",
              "Cytotoxic Effector", "Cytotoxic Effector", "Antigen Presentation", "IFN-gamma Response",
              "IFN-gamma Response", "WNT / beta-Catenin", "WNT / beta-Catenin", "Angiogenesis / VEGF",
              "EMT / Invasive Resistance", "TGF-beta Signaling", "Antigen Presentation"),
  highlight_label = c("CXCL9", "CXCL10", "IFNG", "STAT1", "CD274", "PDCD1", "", "GZMB", "",
                      "HLA-DRA", "IDO1", "", "CTNNB1", "WNT5A", "VEGFA", "AXL", "TGFB1", "B2M"),
  stringsAsFactors = FALSE
)

volcano_df <- rbind(sig_df, bg_df)
volcano_df$neg_log10_padj <- round(-log10(volcano_df$padj), 3)
volcano_df$regulation <- ifelse(
  volcano_df$padj < 0.05 & volcano_df$log2FoldChange >= 1.0, "Up in Responders",
  ifelse(volcano_df$padj < 0.05 & volcano_df$log2FoldChange <= -1.0, "Down (Resistance)", "Not Significant")
)
volcano_df$regulation <- factor(volcano_df$regulation,
                                levels = c("Up in Responders", "Down (Resistance)", "Not Significant"))
rownames(volcano_df) <- volcano_df$gene

# Curated Hallmark / GO Pathway GSEA Enrichment Table (Panel B)
pathway_df <- data.frame(
  pathway_name = c(
    "Hallmark IFN-gamma Response",
    "Antigen Processing & Presentation",
    "T-Cell Receptor Signaling",
    "Allograft Rejection / Cytotoxicity",
    "IL-2 / STAT5 Signaling",
    "Inflammatory Response",
    "Oxidative Phosphorylation",
    "TGF-beta / Stromal Remodeling",
    "Angiogenesis / VEGF Program",
    "WNT / beta-Catenin Exclusion"
  ),
  nes = c(2.74, 2.48, 2.31, 2.22, 1.88, 1.76, -1.42, -1.89, -2.14, -2.38),
  zero_ref = 0.0,
  fdr_q = c(1e-05, 4e-05, 1.2e-04, 2.1e-04, 1.8e-03, 3.4e-03, 2.1e-02, 2.8e-03, 6.5e-04, 1.9e-04),
  gene_count = c(48L, 34L, 41L, 38L, 29L, 33L, 24L, 27L, 31L, 22L),
  direction = c(rep("Immune Activation (Responder)", 6), rep("Immune Exclusion (Resistance)", 4)),
  stringsAsFactors = FALSE
)
pathway_df$neg_log10_fdr <- round(-log10(pathway_df$fdr_q), 2)
pathway_df$pathway_name <- factor(pathway_df$pathway_name, levels = rev(pathway_df$pathway_name))
pathway_df$direction <- factor(pathway_df$direction,
                               levels = c("Immune Activation (Responder)", "Immune Exclusion (Resistance)"))
rownames(pathway_df) <- as.character(pathway_df$pathway_name)

reg_cols <- c("Up in Responders" = "#dc2626", "Down (Resistance)" = "#2563eb", "Not Significant" = "#cbd5e1")
dir_cols <- c("Immune Activation (Responder)" = "#dc2626", "Immune Exclusion (Resistance)" = "#2563eb")

# Panel A: 2,400-gene Volcano Plot
p_volc <- ggplot(volcano_df, aes(x = log2FoldChange, y = neg_log10_padj, colour = regulation)) +
  geom_vline(xintercept = c(-1, 1), linetype = "dashed", colour = "#64748b", linewidth = 0.5) +
  geom_hline(yintercept = -log10(0.05), linetype = "dashed", colour = "#64748b", linewidth = 0.5) +
  geom_point(alpha = 0.72, size = 1.55) +
  ggrepel::geom_text_repel(
    data = subset(volcano_df, nzchar(highlight_label)),
    aes(label = highlight_label),
    size = 2.9, fontface = "bold", max.overlaps = 20,
    box.padding = 0.3, segment.alpha = 0.55, seed = 42, show.legend = FALSE
  ) +
  scale_colour_manual(values = reg_cols, name = "DE Class") +
  labs(
    title = "A. Differential Expression (2,400 Genes)",
    subtitle = "Anti-PD-1 Responders vs Non-Responders (|log2FC| >= 1, FDR < 0.05)",
    x = "log2 Fold Change (Responder / Non-Responder)",
    y = "-log10(Adjusted P-value)"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    legend.position = "bottom",
    plot.title = element_text(face = "bold", size = 11.5),
    plot.subtitle = element_text(size = 8.8, colour = "#475569"),
    panel.grid.minor = element_blank()
  )

# Panel B: Hallmark / GO Pathway Enrichment Dotplot
p_path <- ggplot(pathway_df, aes(x = nes, y = pathway_name, colour = direction)) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "#64748b", linewidth = 0.6) +
  geom_segment(aes(x = 0, xend = nes, y = pathway_name, yend = pathway_name), linewidth = 0.75, alpha = 0.55) +
  geom_point(aes(size = gene_count)) +
  scale_colour_manual(values = dir_cols, name = "Enrichment Program") +
  scale_size_continuous(range = c(2.6, 5.6), name = "Leading-edge Genes", guide = "none") +
  scale_x_continuous(limits = c(-2.8, 3.1)) +
  labs(
    title = "B. Hallmark & GO Pathway Enrichment (GSEA)",
    subtitle = "Normalized Enrichment Score (NES); dot size = leading-edge gene count",
    x = "Normalized Enrichment Score (NES)",
    y = NULL
  ) +
  theme_minimal(base_size = 11) +
  theme(
    legend.position = "bottom",
    plot.title = element_text(face = "bold", size = 11.5),
    plot.subtitle = element_text(size = 8.8, colour = "#475569"),
    panel.grid.minor = element_blank()
  )

pw <- (p_volc | p_path) +
  patchwork::plot_layout(widths = c(1.18, 1.02)) +
  patchwork::plot_annotation(
    title = "Melanoma Anti-PD-1 Immunotherapy: Transcriptomic Volcano & Pathway Enrichment",
    subtitle = "Pre-treatment tumor RNA-seq differential expression (n = 2,400 genes) linked to Hallmark/GO GSEA pathways"
  )

fig <- gloss(pw, width = 12.0, height = 5.6)

# 2. External Context: Data Dictionary, Ontology, Literature, Experiment Metadata
fig <- gl_add_context(fig, "data_dictionary", list(
  source = "DESeq2 & fgsea Biomarker Analysis Specification",
  variables = list(
    list(name = "log2FoldChange", unit = "log2 ratio", description = "Shrunk log2 expression fold change (Anti-PD-1 Responder vs Non-Responder)"),
    list(name = "neg_log10_padj", unit = "-log10(FDR)", description = "Benjamini-Hochberg adjusted Wald test significance"),
    list(name = "baseMean", unit = "norm counts", description = "Mean normalized read count across all tumor biopsies"),
    list(name = "nes", unit = "NES", description = "GSEA Normalized Enrichment Score; positive = enriched in responders"),
    list(name = "gene_count", unit = "genes", description = "Number of leading-edge genes driving pathway enrichment")
  )
))

fig <- gl_add_context(fig, "ontology", list(
  terms = list(
    list(id = "GO:0034341", label = "Response to interferon-gamma", genes = c("CXCL9", "CXCL10", "IFNG", "STAT1", "IDO1")),
    list(id = "GO:0019882", label = "Antigen processing and presentation", genes = c("HLA-DRA", "B2M")),
    list(id = "MSigDB:M5913", label = "HALLMARK_INTERFERON_GAMMA_RESPONSE", direction = "Responder-enriched"),
    list(id = "MSigDB:M5903", label = "HALLMARK_WNT_BETA_CATENIN_SIGNALING", direction = "Immune-exclusion resistance")
  )
))

fig <- gl_add_context(fig, "literature", list(
  entries = list(
    list(citation = "Ayers M et al. (2017). IFN-gamma-related mRNA profile predicts clinical response to PD-1 blockade. J Clin Invest 127(8):2930-2940."),
    list(citation = "Spranger S, Bao R, Gajewski TF (2015). Melanoma-intrinsic beta-catenin signalling prevents anti-tumour immunity. Nature 523:231-235."),
    list(citation = "Hugo W et al. (2016). Genomic and transcriptomic features of response to anti-PD-1 therapy in metastatic melanoma. Cell 165(1):35-44.")
  )
))

fig <- gl_add_context(fig, "external_metadata", list(
  assay = "Bulk RNA-seq (Illumina NovaSeq, paired-end 150 bp)",
  pipeline = "STAR 2.7.11 -> featureCounts -> DESeq2 1.42 (apeglm shrinkage) -> fgsea",
  cutoffs = "|log2FoldChange| >= 1.0 and Benjamini-Hochberg FDR < 0.05"
))

fig <- gl_add_context(fig, "user_context", list(
  question = "Which transcriptomic signatures distinguish Anti-PD-1 responders from primary-resistant tumors, and which pathways oppose immune infiltration?",
  audience = "Translational oncology & computational biology lead"
))

# 3. Anchor signature genes & pathways across both panels
b <- gl_bindings(fig)
b_volc <- b[b$table == "plot1_built_layer3" & b$status == "verified", , drop = FALSE]
b_path <- b[b$table == "plot2_built_layer3" & b$status == "verified", , drop = FALSE]
vb <- fig$tables[["plot1_built_layer3"]]$data
pb <- fig$tables[["plot2_built_layer3"]]$data

find_gene_el <- function(sym) {
  r <- which(volcano_df$gene == sym)[1L]
  idx <- which(abs(vb$x[b_volc$row] - volcano_df$log2FoldChange[r]) < 1e-4 &
                 abs(vb$y[b_volc$row] - volcano_df$neg_log10_padj[r]) < 1e-4)
  b_volc$element[idx[1L]]
}
find_path_el <- function(pname) {
  r <- which(as.character(pathway_df$pathway_name) == pname)[1L]
  idx <- which(abs(pb$x[b_path$row] - pathway_df$nes[r]) < 1e-4)
  b_path$element[idx[1L]]
}

e_cxcl9   <- find_gene_el("CXCL9")
e_cd274   <- find_gene_el("CD274")
e_ctnnb1  <- find_gene_el("CTNNB1")
e_axl     <- find_gene_el("AXL")
e_p_ifng  <- find_path_el("Hallmark IFN-gamma Response")
e_p_wnt   <- find_path_el("WNT / beta-Catenin Exclusion")

# 4. Claims & Checks
fig <- gl_record(
  fig, "claim", gl_anchor(element = e_p_ifng),
  list(
    text = "Responder tumors enrich 6 immune-activation pathways (led by Hallmark IFN-gamma Response, NES = +2.74), whereas 4 opposing resistance programs (WNT/beta-catenin, Angiogenesis, TGF-beta, Oxidative Phosphorylation) enrich in non-responders.",
    check = list(
      kind = "compare",
      table = "plot2_raw",
      args = list(left = "nes", right = "zero_ref", stat = "mean", expect = "greater", by = c("pathway_name"))
    )
  ),
  by = "comp-bio"
)

fig <- gl_record(
  fig, "claim", gl_anchor(element = e_cxcl9),
  list(
    text = "Differential expression covers all 2,400 tested genes with substantial up- and down-regulated candidate sets.",
    check = list(
      kind = "count",
      table = "plot1_raw",
      args = list(by = c("regulation"), min = 20L)
    )
  ),
  by = "comp-bio"
)

# Contextual domain notes
fig <- gl_record(
  fig, "meaning", gl_anchor(element = e_cxcl9),
  list(
    label = "CXCL9 (T-Cell Recruitment Chemokine)",
    type = "domain_interpretation",
    text = "CXCL9 (log2FC = +3.42, padj = 1.2e-15) is a canonical IFN-gamma-induced CXCR3 ligand recruiting effector CD8+ T cells into the tumor bed and a core gene in the Ayers 18-gene T-cell-inflamed GEP signature.",
    source = "GO:0034341 / Ayers et al. (2017) JCI",
    source_type = "ontology",
    provenance = "derived",
    confidence = 0.96
  ),
  by = "comp-bio"
)

fig <- gl_record(
  fig, "meaning", gl_anchor(element = e_cd274),
  list(
    label = "CD274 / PD-L1 (Adaptive Immune Resistance)",
    type = "domain_interpretation",
    text = "CD274 (PD-L1, log2FC = +2.54) is upregulated downstream of IFN-gamma/STAT1 signaling in responder biopsies, reflecting pre-existing T-cell infiltration amenable to PD-1 blockade.",
    source = "HGNC:17635 / Drug Target Knowledgebase",
    source_type = "ontology",
    provenance = "derived",
    confidence = 0.95
  ),
  by = "comp-bio"
)

fig <- gl_record(
  fig, "meaning", gl_anchor(element = e_ctnnb1),
  list(
    label = "CTNNB1 (beta-Catenin Immune Exclusion)",
    type = "domain_interpretation",
    text = "Elevated CTNNB1 in non-responders (log2FC = -2.62, padj = 2.1e-11) suppresses CCL4 transcription and BATF3+ dendritic cell recruitment, driving a 'cold' T-cell-excluded tumor phenotype.",
    source = "Spranger et al. (2015), Nature 523:231-235",
    source_type = "literature",
    provenance = "derived",
    confidence = 0.93
  ),
  by = "comp-bio"
)

# Cross-panel gene <-> pathway links
fig <- gl_record(
  fig, "relation",
  anchor = list(gl_anchor(element = e_cxcl9), gl_anchor(element = e_p_ifng)),
  list(
    type = "gene_to_pathway_driver",
    text = "CXCL9 is the top leading-edge transcript driving Hallmark IFN-gamma Response enrichment (NES = +2.74) in Panel B."
  ),
  by = "comp-bio"
)
fig <- gl_apply(fig, list(list(
  op = "link",
  from = gl_anchor(element = e_cxcl9),
  to = gl_anchor(element = e_p_ifng),
  relation = "Leading-edge driver -> IFN-g (NES +2.74)"
)))

fig <- gl_record(
  fig, "relation",
  anchor = list(gl_anchor(element = e_ctnnb1), gl_anchor(element = e_p_wnt)),
  list(
    type = "resistance_driver_link",
    text = "CTNNB1 anchors the negatively enriched WNT / beta-Catenin Exclusion pathway (NES = -2.38) in non-responders."
  ),
  by = "comp-bio"
)
fig <- gl_apply(fig, list(list(
  op = "link",
  from = gl_anchor(element = e_ctnnb1),
  to = gl_anchor(element = e_p_wnt),
  relation = "Resistance driver -> WNT Exclusion (-2.38)"
)))

# 4-step translational narrative
fig <- gl_record(fig, "narrative", gl_anchor(element = e_cxcl9),
                 list(order = 1L, text = "Begin at the upper-right of the 2,400-gene volcano: chemokines CXCL9/CXCL10 and IFNG dominate responder biopsies."),
                 by = "comp-bio")
fig <- gl_record(fig, "narrative", gl_anchor(element = e_p_ifng),
                 list(order = 2L, text = "Follow the cross-panel link into Panel B: Hallmark IFN-gamma Response (NES = +2.74) and Antigen Presentation lead positive enrichment."),
                 by = "comp-bio")
fig <- gl_record(fig, "narrative", gl_anchor(element = e_ctnnb1),
                 list(order = 3L, text = "Inspect the left wing (Down / Resistance): CTNNB1, AXL, and VEGFA mark tumor-intrinsic immune exclusion and mesenchymal resistance."),
                 by = "comp-bio")
fig <- gl_record(fig, "narrative", gl_anchor(element = e_p_wnt),
                 list(order = 4L, text = "Verify the opposing resistance pathways in Panel B: WNT/beta-catenin, Angiogenesis, and TGF-beta programs emerge as checked exceptions to pure immune activation."),
                 by = "comp-bio")

out_path <- "dev_docs/demo/case2-rnaseq-volcano.html"
gl_workbench(fig, out_path, title = "Anti-PD-1 RNA-seq Volcano & Pathway Enrichment")
back <- gl_read(out_path)
cat(sprintf(
  "Case 2 OK: %s (%s bytes) | elements=%d | verified=%d | records=%d | roundtrip=%s\n",
  out_path, format(file.size(out_path), big.mark = ","),
  nrow(gl_elements(fig)), sum(b$status == "verified"), nrow(gl_records(fig)),
  identical(gl_elements(back), gl_elements(fig)) && identical(gl_bindings(back), gl_bindings(fig))
))
