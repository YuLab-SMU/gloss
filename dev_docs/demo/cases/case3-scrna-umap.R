# Case 3: Single-Cell RNA-seq TME Atlas (1,800 cells UMAP + Canonical Marker Dotplot)
# Run from repo root: R_LIBS_USER=/nonexistent Rscript dev_docs/demo/cases/case3-scrna-umap.R

suppressPackageStartupMessages({
  devtools::load_all(quiet = TRUE)
  library(ggplot2)
  library(patchwork)
})

set.seed(303)

# 1. 1,800 single cells across 8 tumor microenvironment (TME) populations
clusters <- data.frame(
  cluster_id = paste0("C", 0:7),
  cell_type = c(
    "CD8+ Effector T",
    "Exhausted CD8+ T",
    "CD4+ Treg",
    "NK Cells",
    "M1 Macrophage",
    "M2 TAM",
    "B Cells",
    "CAF / Fibroblast"
  ),
  n_cells = c(320L, 210L, 180L, 160L, 240L, 290L, 190L, 210L),
  cx = c(-4.2, -5.8, -1.8, -3.5, 3.8, 5.4, 0.8, 3.2),
  cy = c(3.4, 1.1, 4.3, -1.2, 3.1, 0.2, -3.8, -4.4),
  sx = c(0.85, 0.72, 0.68, 0.65, 0.82, 0.90, 0.70, 0.78),
  sy = c(0.82, 0.68, 0.65, 0.62, 0.75, 0.88, 0.66, 0.74),
  stringsAsFactors = FALSE
)

cell_list <- lapply(seq_len(nrow(clusters)), function(i) {
  cl <- clusters[i, ]
  data.frame(
    cell_barcode = sprintf("%s_%04d", cl$cluster_id, seq_len(cl$n_cells)),
    cluster = cl$cluster_id,
    cell_type = cl$cell_type,
    umap_1 = round(rnorm(cl$n_cells, cl$cx, cl$sx), 3),
    umap_2 = round(rnorm(cl$n_cells, cl$cy, cl$sy), 3),
    pdcd1_expr = round(pmax(0, rnorm(cl$n_cells, if (cl$cluster_id == "C1") 2.9 else if (cl$cluster_id == "C0") 0.8 else 0.12, 0.45)), 2),
    gzmb_expr  = round(pmax(0, rnorm(cl$n_cells, if (cl$cluster_id %in% c("C0", "C3")) 3.1 else if (cl$cluster_id == "C1") 1.4 else 0.1, 0.5)), 2),
    stringsAsFactors = FALSE
  )
})
umap_df <- do.call(rbind, cell_list)
umap_df$cell_type <- factor(umap_df$cell_type, levels = clusters$cell_type)
rownames(umap_df) <- umap_df$cell_barcode

# 2. Canonical Marker Gene Expression Matrix (8 cell types x 10 genes = 80 dotplot entries)
markers <- c("CD3D", "CD8A", "GZMB", "PDCD1", "LAG3", "FOXP3", "NKG7", "CD163", "MS4A1", "COL1A1")
avg_mat <- matrix(
  c(
    # CD3D  CD8A  GZMB  PDCD1 LAG3  FOXP3 NKG7  CD163 MS4A1 COL1A1
      2.3,  2.5,  2.4,  0.5,  0.4,  0.1,  1.8,  0.0,  0.0,  0.0,  # CD8+ Effector T
      2.1,  2.2,  1.1,  2.9,  2.6,  0.2,  1.2,  0.0,  0.0,  0.0,  # Exhausted CD8+ T
      2.2,  0.2,  0.2,  1.1,  0.9,  2.8,  0.1,  0.0,  0.0,  0.0,  # CD4+ Treg
      0.3,  0.4,  2.7,  0.2,  0.4,  0.0,  2.9,  0.0,  0.0,  0.0,  # NK Cells
      0.1,  0.0,  0.1,  0.1,  0.1,  0.0,  0.1,  0.9,  0.0,  0.1,  # M1 Macrophage
      0.0,  0.0,  0.0,  0.1,  0.1,  0.0,  0.1,  2.8,  0.0,  0.1,  # M2 TAM
      0.1,  0.0,  0.0,  0.1,  0.0,  0.0,  0.0,  0.0,  2.9,  0.0,  # B Cells
      0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.1,  0.0,  3.0   # CAF / Fibroblast
  ),
  nrow = 8, byrow = TRUE,
  dimnames = list(clusters$cell_type, markers)
)
pct_mat <- avg_mat
pct_mat[] <- pmin(96, pmax(2, round(avg_mat * 31 + runif(80, 1, 7), 1)))

dot_df <- expand.grid(
  cell_type = clusters$cell_type,
  gene = markers,
  stringsAsFactors = FALSE
)
dot_df$avg_expr <- as.numeric(avg_mat[cbind(dot_df$cell_type, dot_df$gene)])
dot_df$pct_expressed <- as.numeric(pct_mat[cbind(dot_df$cell_type, dot_df$gene)])
dot_df$checkpoint_cutoff <- 2.0
dot_df$cell_type <- factor(dot_df$cell_type, levels = rev(clusters$cell_type))
dot_df$gene <- factor(dot_df$gene, levels = markers)
rownames(dot_df) <- paste0(dot_df$cell_type, " | ", dot_df$gene)

ct_cols <- c(
  "CD8+ Effector T"  = "#2563eb",
  "Exhausted CD8+ T" = "#dc2626",
  "CD4+ Treg"        = "#9333ea",
  "NK Cells"         = "#0891b2",
  "M1 Macrophage"    = "#16a34a",
  "M2 TAM"           = "#d97706",
  "B Cells"          = "#ec4899",
  "CAF / Fibroblast" = "#64748b"
)

# Panel A: 1,800-cell UMAP
p_umap <- ggplot(umap_df, aes(x = umap_1, y = umap_2, colour = cell_type)) +
  geom_point(size = 1.25, alpha = 0.78) +
  scale_colour_manual(values = ct_cols, name = "TME Population") +
  labs(
    title = "A. Single-Cell UMAP Atlas (1,800 Cells)",
    subtitle = "8 Leiden clusters integrated across tumor biopsies (click legend to isolate)",
    x = "UMAP 1",
    y = "UMAP 2"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    legend.position = "bottom",
    legend.text = element_text(size = 8.2),
    plot.title = element_text(face = "bold", size = 11.5),
    plot.subtitle = element_text(size = 8.8, colour = "#475569"),
    panel.grid.minor = element_blank()
  ) +
  guides(colour = guide_legend(nrow = 2, override.aes = list(size = 2.8, alpha = 1)))

# Panel B: Canonical Marker Dotplot
p_dot <- ggplot(dot_df, aes(x = gene, y = cell_type, size = pct_expressed, colour = avg_expr)) +
  geom_point() +
  scale_colour_gradient(low = "#e2e8f0", high = "#b91c1c", name = "Scaled Expr") +
  scale_size_continuous(range = c(1.2, 6.2), name = "% Expressing") +
  labs(
    title = "B. Canonical Lineage & Checkpoint Markers",
    subtitle = "Dot size = % cells expressing; color = scaled average expression",
    x = "Marker Gene",
    y = NULL
  ) +
  theme_minimal(base_size = 11) +
  theme(
    axis.text.x = element_text(angle = 40, hjust = 1, face = "bold", size = 8.8),
    legend.position = "bottom",
    plot.title = element_text(face = "bold", size = 11.5),
    plot.subtitle = element_text(size = 8.8, colour = "#475569"),
    panel.grid.minor = element_blank()
  )

pw <- (p_umap | p_dot) +
  patchwork::plot_layout(widths = c(1.12, 1.08)) +
  patchwork::plot_annotation(
    title = "Tumor Microenvironment Single-Cell Atlas: Cluster Geometry & Marker Evidence",
    subtitle = "Separating verifiable marker expression (Panel B) from ontology-backed cell-state annotation (Panel A)"
  )

fig <- gloss(pw, width = 12.2, height = 5.6)

# 3. External Context (Cell Ontology + Single-cell QC + Literature)
fig <- gl_add_context(fig, "data_dictionary", list(
  source = "Single-Cell TME Annotation Schema",
  variables = list(
    list(name = "umap_1", unit = "UMAP dim 1", description = "First non-linear embedding coordinate after Harmony batch integration"),
    list(name = "umap_2", unit = "UMAP dim 2", description = "Second non-linear embedding coordinate"),
    list(name = "pdcd1_expr", unit = "log1p(CP10K)", description = "Normalized PD-1 (PDCD1) transcript level per cell"),
    list(name = "avg_expr", unit = "scaled z", description = "Cluster-level scaled mean expression of canonical marker gene"),
    list(name = "pct_expressed", unit = "% cells", description = "Percentage of cells within cluster with UMI count > 0")
  )
))

fig <- gl_add_context(fig, "ontology", list(
  terms = list(
    list(id = "CL:0000625", label = "CD8-positive, alpha-beta T cell", markers = c("CD3D", "CD8A", "GZMB")),
    list(id = "CL:0000815", label = "Regulatory T cell (Treg)", markers = c("CD3D", "FOXP3")),
    list(id = "CL:0000623", label = "Natural killer cell", markers = c("NKG7", "GZMB")),
    list(id = "CL:0000235", label = "Macrophage (M2-polarized TAM)", markers = c("CD163")),
    list(id = "CL:0000236", label = "B cell", markers = c("MS4A1")),
    list(id = "CL:0000057", label = "Cancer-associated fibroblast (CAF)", markers = c("COL1A1"))
  )
))

fig <- gl_add_context(fig, "external_metadata", list(
  platform = "10x Genomics Chromium 3' v3.1",
  integration = "Seurat v5 + Harmony (30 PCs), Leiden clustering resolution = 0.6",
  qc_filters = "nFeature_RNA > 400, percent.mt < 15%, DoubletFinder filtered"
))

fig <- gl_add_context(fig, "literature", list(
  entries = list(
    list(citation = "Sade-Feldman M et al. (2018). Defining T cell states associated with response to checkpoint immunotherapy in melanoma. Cell 175(4):998-1013."),
    list(citation = "Zheng L et al. (2021). Pan-cancer single-cell landscape of tumor-infiltrating T cells. Science 374(6574):abe6474.")
  )
))

fig <- gl_add_context(fig, "user_context", list(
  question = "Which UMAP cluster represents exhausted PD-1+ CD8+ T cells, what marker evidence supports it, and which annotations remain biological hypotheses?",
  audience = "Single-cell immunologist & biomarker scientist"
))

# 4. Anchor representative cells & marker dots
b <- gl_bindings(fig)
b_umap <- b[b$table == "plot1_built_layer1" & b$status == "verified", , drop = FALSE]
b_dot  <- b[b$table == "plot2_built_layer1" & b$status == "verified", , drop = FALSE]
ub <- fig$tables[["plot1_built_layer1"]]$data
db <- fig$tables[["plot2_built_layer1"]]$data

# Pick cell closest to Exhausted CD8+ T centroid, Treg centroid, and M2 TAM centroid
find_cluster_center_el <- function(ct_name) {
  sub_idx <- which(umap_df$cell_type == ct_name)
  cl_row <- clusters[clusters$cell_type == ct_name, ]
  best_r <- sub_idx[which.min((umap_df$umap_1[sub_idx] - cl_row$cx)^2 + (umap_df$umap_2[sub_idx] - cl_row$cy)^2)]
  idx <- which(abs(ub$x[b_umap$row] - umap_df$umap_1[best_r]) < 1e-4 &
                 abs(ub$y[b_umap$row] - umap_df$umap_2[best_r]) < 1e-4)
  b_umap$element[idx[1L]]
}
find_dot_el <- function(ct_name, gene_name) {
  gx <- which(levels(dot_df$gene) == gene_name)
  gy <- which(levels(dot_df$cell_type) == ct_name)
  idx <- which(abs(db$x[b_dot$row] - gx) < 0.01 & abs(db$y[b_dot$row] - gy) < 0.01)
  b_dot$element[idx[1L]]
}

e_exh_cell  <- find_cluster_center_el("Exhausted CD8+ T")
e_treg_cell <- find_cluster_center_el("CD4+ Treg")
e_m2_cell   <- find_cluster_center_el("M2 TAM")
e_dot_pdcd1 <- find_dot_el("Exhausted CD8+ T", "PDCD1")
e_dot_foxp3 <- find_dot_el("CD4+ Treg", "FOXP3")
e_dot_cd163 <- find_dot_el("M2 TAM", "CD163")

# 5. Checked claims + Epistemically distinct annotations (verified vs derived vs speculative!)
fig <- gl_record(
  fig, "claim", gl_anchor(element = e_exh_cell),
  list(
    text = "All 8 TME populations are adequately sampled with at least 150 cells per cluster in the UMAP atlas.",
    check = list(
      kind = "count",
      table = "plot1_raw",
      args = list(by = c("cell_type"), min = 150L)
    )
  ),
  by = "sc-analyst"
)

fig <- gl_record(
  fig, "claim", gl_anchor(element = e_dot_pdcd1),
  list(
    text = "Seven of eight TME clusters show a strong canonical marker above 2.0 scaled expression on this 10-gene panel; M1 Macrophages lack a dedicated M1-specific marker here and rely on intermediate CD163 expression.",
    check = list(
      kind = "compare",
      table = "plot2_raw",
      args = list(left = "avg_expr", right = "checkpoint_cutoff", stat = "max", expect = "greater", by = c("cell_type"))
    )
  ),
  by = "sc-analyst"
)

fig <- gl_record(
  fig, "meaning", gl_anchor(element = e_exh_cell),
  list(
    label = "Cluster C1: Exhausted CD8+ T Cells",
    type = "domain_interpretation",
    text = "Cluster C1 co-expresses CD3D, CD8A, PDCD1 (PD-1, scaled avg = 2.9), and LAG3 (2.6) with reduced GZMB relative to C0 Effector T cells, matching a terminally exhausted tumor-reactive CD8+ T-cell state.",
    source = "Cell Ontology CL:0000625 / Zheng et al. (2021) Science",
    source_type = "ontology",
    provenance = "derived",
    confidence = 0.91
  ),
  by = "immunologist"
)

fig <- gl_record(
  fig, "meaning", gl_anchor(element = e_m2_cell),
  list(
    label = "Cluster C5: Immunosuppressive M2 TAM",
    type = "domain_interpretation",
    text = "Cluster C5 strongly expresses CD163 (scaled avg = 2.8) and may mediate local T-cell exclusion and anti-PD-1 resistance; spatial validation via multiplex IHC is recommended before therapeutic stratification.",
    source = "Cell Ontology CL:0000235 / Internal Biomarker Hypothesis",
    source_type = "domain_hypothesis",
    provenance = "speculative",
    confidence = 0.71
  ),
  by = "immunologist"
)

# Cross-panel cluster <-> canonical marker dot link
fig <- gl_record(
  fig, "relation",
  anchor = list(gl_anchor(element = e_exh_cell), gl_anchor(element = e_dot_pdcd1)),
  list(
    type = "cluster_to_marker_evidence",
    text = "UMAP Cluster C1 (Exhausted CD8+ T) is anchored by peak PDCD1 expression (avg = 2.9) in Panel B."
  ),
  by = "immunologist"
)
fig <- gl_apply(fig, list(list(
  op = "link",
  from = gl_anchor(element = e_exh_cell),
  to = gl_anchor(element = e_dot_pdcd1),
  relation = "Cluster C1 -> PDCD1 peak (2.9)"
)))

fig <- gl_record(fig, "narrative", gl_anchor(element = e_exh_cell),
                 list(order = 1L, text = "Start in Panel A: 1,800 TME cells partition into 8 clusters; click any cell type in the legend to isolate its spatial distribution."),
                 by = "immunologist")
fig <- gl_record(fig, "narrative", gl_anchor(element = e_dot_pdcd1),
                 list(order = 2L, text = "Follow Cluster C1 into Panel B: co-expression of PDCD1 and LAG3 distinguishes Exhausted CD8+ T cells from cytotoxic CD8+ Effectors."),
                 by = "immunologist")
fig <- gl_record(fig, "narrative", gl_anchor(element = e_dot_foxp3),
                 list(order = 3L, text = "Confirm lineage specificity: FOXP3 sharply isolates CD4+ Tregs while MS4A1 and COL1A1 anchor B cells and CAFs."),
                 by = "immunologist")
fig <- gl_record(fig, "narrative", gl_anchor(element = e_m2_cell),
                 list(order = 4L, text = "Review epistemic status on M2 TAM (CD163+): marker positivity is data-verified, while its resistance-driving role is explicitly marked as a Hypothesis (speculative)."),
                 by = "immunologist")

out_path <- "dev_docs/demo/case3-scrna-umap.html"
gl_workbench(fig, out_path, title = "Single-Cell TME UMAP & Marker Atlas")
back <- gl_read(out_path)
cat(sprintf(
  "Case 3 OK: %s (%s bytes) | elements=%d | verified=%d | records=%d | roundtrip=%s\n",
  out_path, format(file.size(out_path), big.mark = ","),
  nrow(gl_elements(fig)), sum(b$status == "verified"), nrow(gl_records(fig)),
  identical(gl_elements(back), gl_elements(fig)) && identical(gl_bindings(back), gl_bindings(fig))
))
