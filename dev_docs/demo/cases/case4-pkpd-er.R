# Case 4: Phase I/II Oncology Oral Kinase Inhibitor PK/PD & Exposure-Response (Project Optimus)
# Multi-panel patchwork: Longitudinal PK Concentration-Time Spaghetti Curves + Exposure-Response Scatter
# Run from repo root: R_LIBS_USER=/nonexistent Rscript dev_docs/demo/cases/case4-pkpd-er.R

suppressPackageStartupMessages({
  devtools::load_all(quiet = TRUE)
  library(ggplot2)
  library(patchwork)
})

set.seed(404)

# 1. Simulate realistic 48-patient 4-cohort oral PK/PD study (25, 50, 100, 200 mg QD)
cohorts <- c("25 mg QD", "50 mg QD", "100 mg QD", "200 mg QD")
doses <- c(25, 50, 100, 200)
times <- c(0, 0.5, 1, 2, 4, 8, 12, 24)

pk_rows <- list()
er_rows <- list()

for (ci in seq_along(cohorts)) {
  dose <- doses[ci]
  cname <- cohorts[ci]
  for (pi in 1:12) {
    pid <- sprintf("PT-%d-%02d", dose, pi)
    # Patient PT-100-09 is a CYP3A4 poor metabolizer -> ~2.1x higher exposure -> Grade 3 ALT/AST DLT
    is_cyp_pm <- (pid == "PT-100-09")
    cl_factor <- if (is_cyp_pm) 0.44 else exp(rnorm(1, 0, 0.22))
    ka <- 1.35 * exp(rnorm(1, 0, 0.12))
    ke <- 0.115 * cl_factor
    vd <- 0.36 * exp(rnorm(1, 0, 0.14))

    # One-compartment oral absorption steady-state-like profile
    conc <- (dose / vd) * (ka / (ka - ke)) * (exp(-ke * times) - exp(-ka * times))
    conc <- round(pmax(0, conc * (1 + rnorm(length(times), 0, 0.04))), 1)
    conc[1] <- round(max(4, conc[length(times)] * 0.92), 1) # steady-state trough at t=0

    # Trapezoidal AUC_0-24 and Cmax
    auc_ss <- round(sum(diff(times) * (head(conc, -1) + tail(conc, -1)) / 2), 0)
    cmax <- max(conc)

    # Emax tumor shrinkage model (saturating around -55% above AUC ~ 4200 ng*h/mL)
    emax_resp <- -62 * (auc_ss / (1650 + auc_ss)) + rnorm(1, 0, 11)
    tumor_chg <- round(max(-88, min(38, emax_resp)), 1)
    dlt_g3 <- (cmax > 450)

    pk_rows[[length(pk_rows) + 1L]] <- data.frame(
      patient_id = pid,
      cohort = cname,
      dose_mg = dose,
      time_hr = times,
      conc_ng_ml = conc,
      stringsAsFactors = FALSE
    )

    er_rows[[length(er_rows) + 1L]] <- data.frame(
      patient_id = pid,
      cohort = cname,
      dose_mg = dose,
      auc_ss = auc_ss,
      cmax_ng_ml = cmax,
      safety_ceiling = 450.0,
      tumor_change_pct = tumor_chg,
      recist_response = ifelse(tumor_chg <= -30, "PR (Shrinkage >= 30%)",
                               ifelse(tumor_chg >= 20, "PD", "SD")),
      safety_flag = ifelse(dlt_g3, "Grade 3 Hepatotoxicity (DLT)", "Tolerable (<= Grade 2)"),
      cyp3a4_phenotype = ifelse(is_cyp_pm, "CYP3A4 Poor Metabolizer", "Normal Metabolizer"),
      stringsAsFactors = FALSE
    )
  }
}

pk_df <- do.call(rbind, pk_rows)
pk_df$cohort <- factor(pk_df$cohort, levels = cohorts)
er_df <- do.call(rbind, er_rows)
er_df$cohort <- factor(er_df$cohort, levels = cohorts)
rownames(er_df) <- er_df$patient_id

pk_mean <- aggregate(conc_ng_ml ~ cohort + time_hr, data = pk_df, FUN = mean)

dose_cols <- c("25 mg QD" = "#64748b", "50 mg QD" = "#2563eb", "100 mg QD" = "#0d9488", "200 mg QD" = "#dc2626")

# Panel A: PK Concentration-Time Profiles (multi-row geom_line spaghetti + cohort mean + therapeutic window)
p_pk <- ggplot(pk_df, aes(x = time_hr, y = conc_ng_ml, colour = cohort, group = patient_id)) +
  annotate("rect", xmin = 0, xmax = 24, ymin = 120, ymax = 450, fill = "#0d9488", alpha = 0.08) +
  geom_hline(yintercept = 450, linetype = "dashed", colour = "#dc2626", linewidth = 0.7) +
  geom_hline(yintercept = 120, linetype = "dotted", colour = "#0d9488", linewidth = 0.65) +
  geom_line(alpha = 0.30, linewidth = 0.55) +
  geom_line(
    data = pk_mean,
    aes(x = time_hr, y = conc_ng_ml, colour = cohort, group = cohort),
    inherit.aes = FALSE, linewidth = 1.35
  ) +
  scale_colour_manual(values = dose_cols, name = "Dose Cohort") +
  scale_x_continuous(breaks = c(0, 4, 8, 12, 16, 20, 24)) +
  labs(
    title = "A. Steady-State PK Concentration-Time Profiles",
    subtitle = "48 patients (thin) + cohort means (bold); green band = therapeutic window (120-450 ng/mL)",
    x = "Time Post-Dose (hours)",
    y = "Plasma Concentration (ng/mL)"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    legend.position = "bottom",
    plot.title = element_text(face = "bold", size = 11.5),
    plot.subtitle = element_text(size = 8.6, colour = "#475569"),
    panel.grid.minor = element_blank()
  )

# Panel B: Exposure-Response Scatter (AUC_ss vs Best Tumor Change %)
p_er <- ggplot(er_df, aes(x = auc_ss, y = tumor_change_pct, colour = cohort)) +
  geom_hline(yintercept = -30, linetype = "dashed", colour = "#0d9488", linewidth = 0.7) +
  geom_hline(yintercept = 0, colour = "#94a3b8", linewidth = 0.45) +
  geom_point(size = 2.8, alpha = 0.88) +
  scale_colour_manual(values = dose_cols, name = "Dose Cohort") +
  scale_y_continuous(limits = c(-92, 42), breaks = seq(-90, 30, by = 30)) +
  labs(
    title = "B. Exposure-Response (E-R) Efficacy & Safety",
    subtitle = "Dashed line = RECIST 1.1 Partial Response (-30%); efficacy plateaus above ~4,000 ng*h/mL",
    x = "Steady-State Exposure AUC0-24 (ng*h/mL)",
    y = "Best Target Lesion Change (%)"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    legend.position = "bottom",
    plot.title = element_text(face = "bold", size = 11.5),
    plot.subtitle = element_text(size = 8.6, colour = "#475569"),
    panel.grid.minor = element_blank()
  )

pw <- (p_pk | p_er) +
  patchwork::plot_layout(widths = c(1.08, 1.02)) +
  patchwork::plot_annotation(
    title = "Phase I/II Kinase Inhibitor Dose Optimization (Project Optimus): PK & Exposure-Response",
    subtitle = "Supporting 100 mg QD RP2D selection: balancing RECIST efficacy saturation against >450 ng/mL hepatotoxicity ceiling"
  )

fig <- gloss(pw, width = 12.0, height = 5.4)

# 2. External Clinical Pharmacology Context
fig <- gl_add_context(fig, "data_dictionary", list(
  source = "Clinical Pharmacology PopPK / E-R Analysis Plan",
  variables = list(
    list(name = "conc_ng_ml", unit = "ng/mL", description = "Validated LC-MS/MS plasma drug concentration at Cycle 1 Day 15"),
    list(name = "time_hr", unit = "hours", description = "Nominal sampling time post steady-state oral dose"),
    list(name = "auc_ss", unit = "ng*h/mL", description = "Steady-state area under concentration-time curve over 24h dosing interval"),
    list(name = "cmax_ng_ml", unit = "ng/mL", description = "Observed peak plasma concentration; > 450 ng/mL linked to Grade 3 transaminitis"),
    list(name = "tumor_change_pct", unit = "% from baseline", description = "Best percentage change in sum of target lesion diameters per RECIST 1.1")
  )
))

fig <- gl_add_context(fig, "project_notes", list(
  summary = "RP2D Recommendation: 100 mg QD achieves >80% of Emax tumor shrinkage while keeping normal metabolizers within the 120-450 ng/mL therapeutic window. Escalating to 200 mg QD yields minimal incremental RECIST gain while breaching the 450 ng/mL hepatic safety ceiling.",
  dosing_caveat = "CYP3A4 poor metabolizers or strong CYP3A4 inhibitor co-administration require dose reduction to 50 mg QD."
))

fig <- gl_add_context(fig, "literature", list(
  entries = list(
    list(citation = "U.S. FDA (2023). Optimizing the Dosage of Human Prescription Drugs and Biological Products for the Treatment of Oncologic Diseases (Project Optimus Guidance)."),
    list(citation = "Shah M et al. (2021). The Drug Dosing Conundrum in Oncology — When Less Is More. NEJM 385:1445-1447.")
  )
))

fig <- gl_add_context(fig, "user_context", list(
  question = "Why is 100 mg QD preferred over 200 mg QD as the Recommended Phase 2 Dose (RP2D), and which patients breached the 450 ng/mL safety ceiling?",
  audience = "Clinical pharmacologist & FDA Project Optimus reviewer"
))

# 3. Anchor key patients in Panel B (E-R scatter)
b <- gl_bindings(fig)
b_er <- b[b$table == "plot2_built_layer3" & b$status == "verified", , drop = FALSE]
eb <- fig$tables[["plot2_built_layer3"]]$data

find_pt_el <- function(pid) {
  r <- which(er_df$patient_id == pid)[1L]
  idx <- which(abs(eb$x[b_er$row] - er_df$auc_ss[r]) < 1e-3 &
                 abs(eb$y[b_er$row] - er_df$tumor_change_pct[r]) < 1e-3)
  b_er$element[idx[1L]]
}

e_cyp_pm  <- find_pt_el("PT-100-09")
best_100  <- er_df$patient_id[er_df$cohort == "100 mg QD" & er_df$patient_id != "PT-100-09"]
best_100_pt <- best_100[which.min(er_df$tumor_change_pct[match(best_100, er_df$patient_id)])]
e_rep_100 <- find_pt_el(best_100_pt)
high_200  <- er_df$patient_id[er_df$cohort == "200 mg QD"]
max_200_pt <- high_200[which.max(er_df$cmax_ng_ml[match(high_200, er_df$patient_id)])]
e_max_200 <- find_pt_el(max_200_pt)
low_25_pt <- er_df$patient_id[er_df$cohort == "25 mg QD"][1L]
e_low_25  <- find_pt_el(low_25_pt)

# 4. Statistical Checks: Overall E-R efficacy (verified) + Cohort Safety Ceiling (partial exception!)
fig <- gl_record(
  fig, "claim", gl_anchor(element = e_rep_100),
  list(
    text = "Higher steady-state plasma exposure (AUC0-24) is associated with deeper tumor shrinkage across the full dose-escalation cohort.",
    check = list(
      kind = "trend",
      table = "plot2_raw",
      args = list(response = "tumor_change_pct", predictor = "auc_ss", expect = "negative")
    )
  ),
  by = "clin-pharm"
)

fig <- gl_record(
  fig, "claim", gl_anchor(element = e_cyp_pm),
  list(
    text = "Cohorts up to 100 mg QD remain below the 450 ng/mL hepatic safety ceiling at the cohort level, while 200 mg QD breaches the safety ceiling without delivering meaningful additional tumor shrinkage.",
    check = list(
      kind = "compare",
      table = "plot2_raw",
      args = list(left = "cmax_ng_ml", right = "safety_ceiling", stat = "max", expect = "less_equal", by = c("cohort"))
    )
  ),
  by = "clin-pharm"
)

# Contextual clinical pharmacology notes
pm_row <- er_df[er_df$patient_id == "PT-100-09", ]
fig <- gl_record(
  fig, "meaning", gl_anchor(element = e_cyp_pm),
  list(
    label = "PT-100-09 (CYP3A4 Poor Metabolizer Outlier)",
    type = "domain_interpretation",
    text = sprintf(
      "Despite receiving 100 mg QD, PT-100-09 exhibited supratherapeutic exposure (Cmax = %.0f ng/mL, AUC = %.0f ng*h/mL) due to CYP3A4 poor-metabolizer status and experienced Grade 3 reversible transaminitis — directly informing our 50 mg QD label reduction for CYP3A4 inhibitors.",
      pm_row$cmax_ng_ml, pm_row$auc_ss
    ),
    source = "Pharmacogenomics Sub-study & DSMB Safety Narrative",
    source_type = "clinical_safety",
    provenance = "derived",
    confidence = 0.97
  ),
  by = "clin-pharm"
)

fig <- gl_record(
  fig, "meaning", gl_anchor(element = e_rep_100),
  list(
    label = paste0(best_100_pt, " (100 mg QD RP2D Benchmark)"),
    type = "domain_interpretation",
    text = "100 mg QD normal metabolizers achieve deep RECIST Partial Responses (<= -30% target lesion shrinkage) safely inside the 120-450 ng/mL therapeutic window, near the top of the Emax plateau.",
    source = "FDA Project Optimus RP2D Dossier",
    source_type = "regulatory_guidance",
    provenance = "derived",
    confidence = 0.92
  ),
  by = "clin-pharm"
)

fig <- gl_record(
  fig, "relation",
  anchor = list(gl_anchor(element = e_cyp_pm), gl_anchor(element = e_max_200)),
  list(
    type = "supratherapeutic_exposure_match",
    text = "PT-100-09 (100 mg QD, CYP3A4 PM) reaches the same supratherapeutic exposure regime as 200 mg QD patients without additional efficacy gain."
  ),
  by = "clin-pharm"
)
fig <- gl_apply(fig, list(list(
  op = "link",
  from = gl_anchor(element = e_cyp_pm),
  to = gl_anchor(element = e_max_200),
  relation = "CYP3A4 PM matches 200 mg toxic exposure"
)))

# 4-step Project Optimus guided story
fig <- gl_record(fig, "narrative", gl_anchor(element = e_low_25),
                 list(order = 1L, text = "Start at 25 mg QD: exposures fall below the 120 ng/mL target coverage threshold, yielding minimal tumor shrinkage."),
                 by = "clin-pharm")
fig <- gl_record(fig, "narrative", gl_anchor(element = e_rep_100),
                 list(order = 2L, text = "100 mg QD hits the sweet spot: trough/peak profiles track the green therapeutic window and drive consistent RECIST Partial Responses."),
                 by = "clin-pharm")
fig <- gl_record(fig, "narrative", gl_anchor(element = e_max_200),
                 list(order = 3L, text = "Escalating to 200 mg QD breaches the 450 ng/mL hepatotoxicity ceiling while tumor shrinkage plateaus (classic Project Optimus saturation)."),
                 by = "clin-pharm")
fig <- gl_record(fig, "narrative", gl_anchor(element = e_cyp_pm),
                 list(order = 4L, text = "Notice the single 100 mg outlier PT-100-09: pharmacogenomics explains this exception as a CYP3A4 poor metabolizer, triggering a targeted dose-modification rule."),
                 by = "clin-pharm")

out_path <- "dev_docs/demo/case4-pkpd-er.html"
gl_workbench(fig, out_path, title = "Kinase Inhibitor PK/PD & Exposure-Response (Project Optimus)")
back <- gl_read(out_path)
cat(sprintf(
  "Case 4 OK: %s (%s bytes) | elements=%d | verified=%d | records=%d | roundtrip=%s\n",
  out_path, format(file.size(out_path), big.mark = ","),
  nrow(gl_elements(fig)), sum(b$status == "verified"), nrow(gl_records(fig)),
  identical(gl_elements(back), gl_elements(fig)) && identical(gl_bindings(back), gl_bindings(fig))
))
