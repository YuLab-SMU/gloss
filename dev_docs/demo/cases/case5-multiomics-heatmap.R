# Case 5: ComplexHeatmap Multi-Omics Breast Cancer PAM50 Signature Matrix
# Pure grid / ComplexHeatmap engine (non-ggplot2!) with 864 color-verified matrix cells,
# clinical top annotations, row/column subtype splits, and hierarchical dendrograms.
# Run from repo root: R_LIBS_USER=/nonexistent Rscript dev_docs/demo/cases/case5-multiomics-heatmap.R

suppressPackageStartupMessages({
  devtools::load_all(quiet = TRUE)
  library(ComplexHeatmap)
  library(circlize)
  library(grid)
})

set.seed(505)

# 1. 24 PAM50 / biological pathway genes x 36 breast tumor biopsies (864 cells)
luminal_genes <- c("ESR1", "PGR", "FOXA1", "GATA3", "BCL2", "NAT1", "MLPH", "XBP1")
her2_genes    <- c("ERBB2", "GRB7", "PGAP3", "STARD3", "FGFR4", "TMEM45B", "ORMDL3", "MIEN1")
basal_genes   <- c("MKI67", "KRT5", "KRT14", "KRT17", "FOXC1", "SFRP1", "MYC", "CCNE1")
genes <- c(luminal_genes, her2_genes, basal_genes)
gene_module <- factor(
  c(rep("Luminal / ER", 8), rep("HER2 Amplicon", 8), rep("Basal / Prolif", 8)),
  levels = c("Luminal / ER", "HER2 Amplicon", "Basal / Prolif")
)

subtypes <- factor(
  c(rep("Luminal A", 12), rep("HER2-Enriched", 12), rep("Basal-like", 12)),
  levels = c("Luminal A", "HER2-Enriched", "Basal-like")
)
samples <- c(sprintf("LumA_%02d", 1:12), sprintf("HER2_%02d", 1:12), sprintf("Basal_%02d", 1:12))

# Realistic z-score expression structure with 1 intentional discordant clinical sample (LumA_11: high MKI67)
mat <- matrix(rnorm(24 * 36, 0, 0.55), nrow = 24, ncol = 36, dimnames = list(genes, samples))
mat[1:8,   1:12]  <- mat[1:8,   1:12]  + 2.1   # Luminal module high in Luminal A
mat[1:8,   25:36] <- mat[1:8,   25:36] - 1.7   # Luminal module low in Basal-like
mat[9:16,  13:24] <- mat[9:16,  13:24] + 2.3   # HER2 amplicon high in HER2-Enriched
mat[9:16,  1:12]  <- mat[9:16,  1:12]  - 1.0
mat[17:24, 25:36] <- mat[17:24, 25:36] + 2.2   # Basal/Proliferation high in Basal-like
mat[17:24, 1:12]  <- mat[17:24, 1:12]  - 1.4
# Clinical anomaly: LumA_11 is ER+ Luminal A but shows discordant high proliferation (MKI67 = +2.35, Luminal-B-like risk!)
mat["MKI67", "LumA_11"] <- 2.35
mat["CCNE1", "LumA_11"] <- 1.88
mat["ESR1",  "LumA_04"] <- 2.84
mat["GATA3", "LumA_04"] <- 2.52
mat["ERBB2", "HER2_03"] <- 3.12
mat[] <- round(pmax(-3.2, pmin(3.2, mat)), 2)

er_status <- ifelse(subtypes == "Luminal A", "ER+", ifelse(subtypes == "Basal-like", "ER-", rep(c("ER-", "ER+"), each = 6)))
stage <- rep(c("Stage I", "Stage II", "Stage III"), length.out = 36)
ki67_pct <- round(c(
  pmax(4, rnorm(12, 11, 4)),
  pmax(12, rnorm(12, 34, 8)),
  pmax(25, rnorm(12, 58, 11))
))
ki67_pct[11] <- 44 # LumA_11 high Ki-67 proliferation outlier!

ha_top <- HeatmapAnnotation(
  Subtype = subtypes,
  ER = er_status,
  Stage = stage,
  `Ki-67 %` = anno_barplot(ki67_pct, gp = gpar(fill = "#475569", col = NA), height = unit(1.1, "cm")),
  col = list(
    Subtype = c("Luminal A" = "#2563eb", "HER2-Enriched" = "#d97706", "Basal-like" = "#dc2626"),
    ER      = c("ER+" = "#0d9488", "ER-" = "#94a3b8"),
    Stage   = c("Stage I" = "#e2e8f0", "Stage II" = "#94a3b8", "Stage III" = "#334155")
  ),
  annotation_name_gp = gpar(fontsize = 8.5, fontface = "bold")
)

col_fun <- circlize::colorRamp2(c(-2.5, 0, 2.5), c("#1d4ed8", "#f8fafc", "#b91c1c"))

ht <- Heatmap(
  mat,
  name = "zscore",
  col = col_fun,
  top_annotation = ha_top,
  row_split = gene_module,
  column_split = subtypes,
  cluster_row_slices = FALSE,
  cluster_column_slices = FALSE,
  show_column_names = TRUE,
  column_names_gp = gpar(fontsize = 6.8),
  row_names_gp = gpar(fontsize = 8.0, fontface = "bold"),
  row_title_gp = gpar(fontsize = 9.0, fontface = "bold"),
  column_title_gp = gpar(fontsize = 9.5, fontface = "bold"),
  heatmap_legend_param = list(title = "Expression\n(Row Z-score)"),
  use_raster = FALSE
)

fig <- gloss(ht, width = 11.8, height = 7.2)

# 2. External Multi-Omics & Pathology Context
fig <- gl_add_context(fig, "data_dictionary", list(
  source = "Breast Cancer PAM50 / Multi-Omics Expression Matrix Schema",
  variables = list(
    list(name = "zscore", unit = "row z-score", description = "Variance-stabilized RNA-seq log2 expression standardized per gene across 36 biopsies"),
    list(name = "Ki-67 %", unit = "% nuclei", description = "Immunohistochemistry proliferation index; > 20% indicates high-proliferation Luminal B risk")
  )
))

fig <- gl_add_context(fig, "ontology", list(
  terms = list(
    list(id = "HGNC:3467", label = "ESR1 (Estrogen Receptor 1)", module = "Luminal / ER"),
    list(id = "HGNC:3430", label = "ERBB2 / HER2 (17q12 amplicon)", module = "HER2 Amplicon"),
    list(id = "HGNC:7107", label = "MKI67 (Proliferation marker Ki-67)", module = "Basal / Prolif")
  )
))

fig <- gl_add_context(fig, "external_metadata", list(
  engine = "ComplexHeatmap (pure grid vector rendering, use_raster = FALSE)",
  clustering = "Euclidean distance, complete linkage within fixed biological modules & clinical subtypes",
  pairing_note = "All 864 matrix body cells are position- and color-verified by gloss engine-heatmap; clinical top annotations and dendrograms remain geometry-only (honestly reported)."
))

fig <- gl_add_context(fig, "literature", list(
  entries = list(
    list(citation = "Parker JS et al. (2009). Supervised risk predictor of breast cancer based on intrinsic subtypes (PAM50). J Clin Oncol 27(8):1160-1167."),
    list(citation = "Perou CM et al. (2000). Molecular portraits of human breast tumours. Nature 406:747-752.")
  )
))

fig <- gl_add_context(fig, "user_context", list(
  question = "Do the 24 PAM50 signature genes cleanly stratify Luminal A, HER2-Enriched, and Basal-like tumors, and are there high-proliferation outliers inside Luminal A?",
  audience = "Molecular pathologist & translational bioinformatics lead"
))

# 3. Locate exact code-verified heatmap cell elements via flat column-major matrix index!
b <- gl_bindings(fig)
b_mat <- b[b$table == "matrix_zscore" & b$status == "verified", , drop = FALSE]
find_cell_el <- function(gene_sym, sample_id) {
  ri <- match(gene_sym, rownames(mat))
  ci <- match(sample_id, colnames(mat))
  flat <- (ci - 1L) * nrow(mat) + ri
  idx <- which(b_mat$row == flat)
  if (length(idx)) b_mat$element[idx[1L]] else b_mat$element[1L]
}

e_esr1_luma  <- find_cell_el("ESR1", "LumA_04")
e_gata3_luma <- find_cell_el("GATA3", "LumA_04")
e_erbb2_her2 <- find_cell_el("ERBB2", "HER2_03")
e_mki67_anom <- find_cell_el("MKI67", "LumA_11")

# 4. Deterministic checks directly on matrix_zscore!
fig <- gl_record(
  fig, "claim", gl_anchor(element = e_esr1_luma),
  list(
    text = "All standardized expression z-scores across the 24-gene signature in sample LumA_04 remain bounded within [-3.5, +3.5].",
    check = list(
      kind = "range",
      table = "matrix_zscore",
      args = list(column = "LumA_04", min = -3.5, max = 3.5)
    )
  ),
  by = "mol-path"
)

fig <- gl_record(
  fig, "claim", gl_anchor(element = e_mki67_anom),
  list(
    text = "Within Luminal A biopsy LumA_11, every gene in the 24-gene panel remains below the +2.0 high-expression threshold (tests for discordant proliferation outliers).",
    check = list(
      kind = "range",
      table = "matrix_zscore",
      args = list(column = "LumA_11", min = -3.5, max = 2.0)
    )
  ),
  by = "mol-path"
)

# Contextual molecular pathology records
fig <- gl_record(
  fig, "meaning", gl_anchor(element = e_mki67_anom),
  list(
    label = "Discordant High MKI67 in LumA_11",
    type = "domain_interpretation",
    text = "Although classified as Luminal A by ER/Luminal gene expression, biopsy LumA_11 displays sharply elevated MKI67 (z = +2.35), CCNE1 (+1.88), and IHC Ki-67 = 44% — characteristic of borderline Luminal B biology with higher relapse risk that may warrant adjuvant chemotherapy review.",
    source = "St. Gallen Consensus Ki-67 > 20% Cutoff / PAM50 Risk Score",
    source_type = "clinical_pathology",
    provenance = "derived",
    confidence = 0.90
  ),
  by = "mol-path"
)

fig <- gl_record(
  fig, "meaning", gl_anchor(element = e_erbb2_her2),
  list(
    label = "ERBB2 (17q12 Amplicon) Peak",
    type = "domain_interpretation",
    text = "Co-amplification of ERBB2 (z = +3.12) alongside neighboring 17q12 genes GRB7, PGAP3, and STARD3 defines the HER2-Enriched molecular slice and predicts sensitivity to anti-HER2 targeted therapy (trastuzumab / T-DXd).",
    source = "HGNC:3430 / ASCO-CAP HER2 Testing Guideline",
    source_type = "ontology",
    provenance = "derived",
    confidence = 0.96
  ),
  by = "mol-path"
)

fig <- gl_record(
  fig, "meaning", gl_anchor(element = e_esr1_luma),
  list(
    label = "ESR1 Luminal Transcriptional Axis",
    type = "domain_interpretation",
    text = "ESR1 (z = +2.84) co-activates with pioneer factor FOXA1 and lineage transcription factor GATA3 (+2.52) across the Luminal A slice, confirming estrogen-receptor-driven luminal identity.",
    source = "Parker et al. (2009), JCO 27:1160-1167",
    source_type = "literature",
    provenance = "derived",
    confidence = 0.95
  ),
  by = "mol-path"
)

fig <- gl_record(
  fig, "relation",
  anchor = list(gl_anchor(element = e_esr1_luma), gl_anchor(element = e_gata3_luma)),
  list(
    type = "coexpression_module_pair",
    text = "ESR1 and GATA3 form the core positive feedback loop of the Luminal / ER signaling module inside sample LumA_04."
  ),
  by = "mol-path"
)
fig <- gl_apply(fig, list(list(
  op = "link",
  from = gl_anchor(element = e_esr1_luma),
  to = gl_anchor(element = e_gata3_luma),
  relation = "ESR1 and GATA3 Luminal co-expression"
)))

# 4-step molecular pathology walkthrough
fig <- gl_record(fig, "narrative", gl_anchor(element = e_esr1_luma),
                 list(order = 1L, text = "Start in the upper-left Luminal / ER slice: all 864 ComplexHeatmap tiles are individually position- and color-verified; hover any cell to read exact Gene x Sample z-scores."),
                 by = "mol-path")
fig <- gl_record(fig, "narrative", gl_anchor(element = e_erbb2_her2),
                 list(order = 2L, text = "Inspect the central HER2-Enriched slice: ERBB2 and neighboring 17q12 amplicon genes (GRB7, PGAP3, STARD3) form a sharply demarcated high-expression block."),
                 by = "mol-path")
fig <- gl_record(fig, "narrative", gl_anchor(element = e_mki67_anom),
                 list(order = 3L, text = "Spot the clinical outlier in Luminal A: cell MKI67 x LumA_11 stands out in bright red (+2.35), matching the elevated Ki-67 bar directly above it in the clinical track."),
                 by = "mol-path")
fig <- gl_record(fig, "narrative", gl_anchor(element = e_gata3_luma),
                 list(order = 4L, text = "Open the Data drawer -> zscore Matrix and click any gene row to spotlight that gene across all 36 tumor biopsies simultaneously."),
                 by = "mol-path")

out_path <- "dev_docs/demo/case5-multiomics-heatmap.html"
gl_workbench(fig, out_path, title = "Breast Cancer PAM50 Multi-Omics ComplexHeatmap")
back <- gl_read(out_path)
cat(sprintf(
  "Case 5 OK: %s (%s bytes) | elements=%d | verified=%d | records=%d | roundtrip=%s\n",
  out_path, format(file.size(out_path), big.mark = ","),
  nrow(gl_elements(fig)), sum(b$status == "verified"), nrow(gl_records(fig)),
  identical(gl_elements(back), gl_elements(fig)) && identical(gl_bindings(back), gl_bindings(fig))
))
