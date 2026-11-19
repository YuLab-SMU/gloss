# Case 1: Phase III Oncology Clinical Trial (survival::colon)
# Multi-panel patchwork: Kaplan-Meier Overall Survival + Subgroup Cox Forest Plot
# Run from repo root: R_LIBS_USER=/nonexistent Rscript dev_docs/demo/cases/case1-clinical-trial.R

suppressPackageStartupMessages({
  devtools::load_all(quiet = TRUE)
  library(ggplot2)
  library(patchwork)
  library(survival)
})

# 1. Real NCCTG 84-46-52 / Intergroup 0035 Phase III colon cancer trial (death endpoint, n = 929)
d_os <- subset(survival::colon, etype == 2)
d_os$years <- d_os$time / 365.25
d_os$arm <- factor(d_os$rx, levels = c("Obs", "Lev", "Lev+5FU"),
                   labels = c("Observation", "Levamisole", "Levamisole + 5-FU"))

# Kaplan-Meier estimates & 1..5 year clinical landmarks
fit_km <- survival::survfit(survival::Surv(years, status) ~ arm, data = d_os)
km_summary <- summary(fit_km, times = seq(0, 6.5, by = 0.25), extend = TRUE)
km_df <- data.frame(
  time_yr = km_summary$time,
  survival = km_summary$surv,
  lower_ci = km_summary$lower,
  upper_ci = km_summary$upper,
  n_risk = km_summary$n.risk,
  arm = factor(sub("^arm=", "", as.character(km_summary$strata)),
               levels = levels(d_os$arm)),
  stringsAsFactors = FALSE
)

lm_summary <- summary(fit_km, times = c(1, 2, 3, 4, 5), extend = TRUE)
landmark_df <- data.frame(
  landmark_id = sprintf("%s (%dy)", sub("^arm=", "", as.character(lm_summary$strata)), lm_summary$time),
  time_yr = lm_summary$time,
  survival = round(lm_summary$surv, 4),
  lower_ci = round(lm_summary$lower, 4),
  upper_ci = round(lm_summary$upper, 4),
  n_risk = lm_summary$n.risk,
  arm = factor(sub("^arm=", "", as.character(lm_summary$strata)),
               levels = levels(d_os$arm)),
  stringsAsFactors = FALSE
)
rownames(landmark_df) <- landmark_df$landmark_id

# Subgroup Cox PH Forest Plot: Levamisole + 5-FU vs Observation
d_two <- subset(d_os, rx %in% c("Obs", "Lev+5FU"))
d_two$treated <- as.integer(d_two$rx == "Lev+5FU")

subgroup_defs <- list(
  list(name = "Overall Trial Cohort",       idx = rep(TRUE, nrow(d_two))),
  list(name = "Nodes > 4 (High Risk)",      idx = d_two$node4 == 1),
  list(name = "Nodes <= 4 (Lower Risk)",    idx = d_two$node4 == 0),
  list(name = "Extent: Serosa (T3)",        idx = d_two$extent == 3),
  list(name = "Extent: Muscle (T2)",        idx = d_two$extent == 2),
  list(name = "Extent: Contiguous (T4)",    idx = d_two$extent == 4),
  list(name = "Age >= 60 years",            idx = d_two$age >= 60),
  list(name = "Age < 60 years",             idx = d_two$age < 60),
  list(name = "Bowel Obstruction: Yes",     idx = d_two$obstruct == 1),
  list(name = "Tumor Perforation: Yes",     idx = d_two$perfor == 1)
)

forest_rows <- lapply(subgroup_defs, function(sg) {
  sub_df <- d_two[which(sg$idx), , drop = FALSE]
  cx <- survival::coxph(survival::Surv(years, status) ~ treated, data = sub_df)
  s <- summary(cx)
  ci <- s$conf.int[1, ]
  p_val <- s$coefficients[1, "Pr(>|z|)"]
  data.frame(
    subgroup = sg$name,
    n_patients = nrow(sub_df),
    events = sum(sub_df$status == 1),
    hr = round(unname(ci["exp(coef)"]), 3),
    lower_ci = round(unname(ci["lower .95"]), 3),
    upper_ci = round(unname(ci["upper .95"]), 3),
    null_hr = 1.0,
    p_value = round(p_val, 4),
    evidence = if (ci["upper .95"] < 1.0) "Significant benefit (CI < 1)" else "Inconclusive (CI crosses 1)",
    stringsAsFactors = FALSE
  )
})
forest_df <- do.call(rbind, forest_rows)
forest_df$subgroup <- factor(forest_df$subgroup, levels = rev(forest_df$subgroup))
rownames(forest_df) <- as.character(forest_df$subgroup)

arm_cols <- c("Observation" = "#64748b", "Levamisole" = "#d97706", "Levamisole + 5-FU" = "#0d9488")
ev_cols <- c("Significant benefit (CI < 1)" = "#0d9488", "Inconclusive (CI crosses 1)" = "#dc2626")

# Panel A: Kaplan-Meier OS curve + 1..5y interactive landmarks
p_km <- ggplot(landmark_df, aes(x = time_yr, y = survival, colour = arm)) +
  geom_ribbon(
    data = km_df,
    aes(x = time_yr, ymin = lower_ci, ymax = upper_ci, fill = arm),
    inherit.aes = FALSE, alpha = 0.14
  ) +
  geom_step(
    data = km_df,
    aes(x = time_yr, y = survival, colour = arm),
    inherit.aes = FALSE, linewidth = 0.95
  ) +
  geom_point(size = 2.8) +
  scale_colour_manual(values = arm_cols, name = "Treatment Arm") +
  scale_fill_manual(values = arm_cols, guide = "none") +
  scale_y_continuous(limits = c(0.35, 1.0), labels = function(x) paste0(round(x * 100), "%")) +
  scale_x_continuous(breaks = 0:6) +
  labs(
    title = "A. Kaplan-Meier Overall Survival",
    subtitle = "Stage B/C colon cancer (n = 929); points mark 1-5y landmarks",
    x = "Follow-up Time (years)",
    y = "Overall Survival Probability"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    legend.position = "bottom",
    plot.title = element_text(face = "bold", size = 11.5),
    plot.subtitle = element_text(size = 9, colour = "#475569"),
    panel.grid.minor = element_blank()
  )

# Panel B: Subgroup Cox PH Forest Plot
p_forest <- ggplot(forest_df, aes(x = hr, y = subgroup, colour = evidence)) +
  geom_vline(xintercept = 1.0, linetype = "dashed", colour = "#64748b", linewidth = 0.7) +
  geom_segment(aes(x = lower_ci, xend = upper_ci, y = subgroup, yend = subgroup), linewidth = 1.05) +
  geom_point(aes(size = n_patients)) +
  scale_colour_manual(values = ev_cols, name = "Cox PH Result") +
  scale_size_continuous(range = c(2.4, 5.2), name = "Subgroup N", guide = "none") +
  scale_x_continuous(breaks = c(0.5, 1.0, 1.5, 2.0, 2.5)) +
  coord_cartesian(xlim = c(0.25, 2.65)) +
  labs(
    title = "B. Subgroup Hazard Ratios (Lev+5FU vs Obs)",
    subtitle = "Cox PH estimate with 95% CI; values < 1 favor Levamisole + 5-FU",
    x = "Hazard Ratio (HR, 95% CI)",
    y = NULL
  ) +
  theme_minimal(base_size = 11) +
  theme(
    legend.position = "bottom",
    plot.title = element_text(face = "bold", size = 11.5),
    plot.subtitle = element_text(size = 9, colour = "#475569"),
    panel.grid.minor = element_blank()
  )

pw <- (p_km | p_forest) +
  patchwork::plot_layout(widths = c(1.05, 1.15)) +
  patchwork::plot_annotation(
    title = "NCCTG 84-46-52 Phase III Colon Cancer Adjuvant Trial: Survival & Subgroup Efficacy",
    subtitle = "Reproducible analysis of survival::colon (n = 929) comparing Observation, Levamisole, and Levamisole + 5-FU"
  )

fig <- gloss(pw, width = 11.5, height = 5.4)

# 2. Attach rich clinical & regulatory external context
fig <- gl_add_context(fig, "data_dictionary", list(
  source = "NCCTG 84-46-52 / Intergroup 0035 Case Report Form Dictionary",
  variables = list(
    list(name = "survival", unit = "proportion (0-1)", description = "Kaplan-Meier overall survival probability at clinical landmark"),
    list(name = "time_yr", unit = "years", description = "Time from randomization to death from any cause"),
    list(name = "n_risk", unit = "patients", description = "Number of trial participants remaining at risk at landmark"),
    list(name = "hr", unit = "hazard ratio", description = "Cox proportional hazards ratio (Levamisole+5-FU vs Observation); < 1 favors treatment"),
    list(name = "lower_ci", unit = "95% CI low", description = "Lower 95% confidence bound of subgroup hazard ratio"),
    list(name = "upper_ci", unit = "95% CI high", description = "Upper 95% confidence bound; crossing 1.0 indicates non-significant subgroup effect"),
    list(name = "n_patients", unit = "patients", description = "Combined patient count in Lev+5FU and Observation arms for subgroup"),
    list(name = "p_value", unit = "Wald p", description = "Two-sided Cox model Wald test p-value")
  )
))

fig <- gl_add_context(fig, "external_metadata", list(
  study_id = "NCCTG 84-46-52 / Intergroup 0035",
  phase = "Phase III Randomized Controlled Trial",
  indication = "Resected Stage B2 / Stage C Colon Adenocarcinoma",
  primary_endpoint = "Overall Survival (OS, etype == 2) and Recurrence-Free Survival",
  randomization = "1:1:1 across Observation, Levamisole monotherapy, and Levamisole + 5-Fluorouracil"
))

fig <- gl_add_context(fig, "literature", list(
  entries = list(
    list(citation = "Moertel CG et al. (1990). Levamisole and fluorouracil for adjuvant therapy of resected colon carcinoma. NEJM 322(6):352-358."),
    list(citation = "Moertel CG et al. (1995). Fluorouracil plus levamisole as effective adjuvant therapy after resection of stage III colon carcinoma: a final report. Ann Intern Med 122(5):321-326.")
  )
))

fig <- gl_add_context(fig, "user_context", list(
  question = "Does Levamisole + 5-FU improve overall survival consistently across clinical risk strata, and which subgroups have inconclusive confidence intervals?",
  audience = "Oncology biostatistician & regulatory clinical reviewer"
))

# 3. Locate key verified elements across both patchwork panels
b <- gl_bindings(fig)
b_lm <- b[b$table == "plot1_built_layer3" & b$status == "verified", , drop = FALSE]
b_hr <- b[b$table == "plot2_built_layer3" & b$status == "verified", , drop = FALSE]

# Find Lev+5FU 5y landmark in plot1 and Overall / Nodes > 4 / Perforation in plot2
lm_built <- fig$tables[["plot1_built_layer3"]]$data
hr_built <- fig$tables[["plot2_built_layer3"]]$data

e_lev5_5y <- b_lm$element[which(abs(lm_built$x[b_lm$row] - 5) < 1e-6 &
                                  lm_built$colour[b_lm$row] == arm_cols["Levamisole + 5-FU"])[1L]]
e_obs_5y  <- b_lm$element[which(abs(lm_built$x[b_lm$row] - 5) < 1e-6 &
                                  lm_built$colour[b_lm$row] == arm_cols["Observation"])[1L]]

find_forest_el <- function(sg_name) {
  target_hr <- forest_df$hr[as.character(forest_df$subgroup) == sg_name][1L]
  idx <- which(abs(hr_built$x[b_hr$row] - target_hr) < 1e-4)
  if (length(idx)) b_hr$element[idx[1L]] else b_hr$element[1L]
}
e_overall <- find_forest_el("Overall Trial Cohort")
e_nodes4  <- find_forest_el("Nodes > 4 (High Risk)")
e_perfor  <- find_forest_el("Tumor Perforation: Yes")
e_t2      <- find_forest_el("Extent: Muscle (T2)")

# 4. Semantic records & deterministic checks (verified + partial exception!)
fig <- gl_record(
  fig, "claim", gl_anchor(element = e_lev5_5y),
  list(
    text = "Overall survival declines monotonically across 1-5 year landmarks in all three trial arms, with Levamisole + 5-FU staying highest at every landmark.",
    check = list(
      kind = "trend",
      table = "plot1_raw",
      args = list(response = "survival", predictor = "time_yr", by = c("arm"), expect = "negative")
    )
  ),
  by = "biostatistician"
)

fig <- gl_record(
  fig, "claim", gl_anchor(element = e_overall),
  list(
    text = "Within every clinical subgroup, the upper 95% confidence bound of the Lev+5FU vs Observation hazard ratio remains strictly below 1.0.",
    check = list(
      kind = "compare",
      table = "plot2_raw",
      args = list(left = "upper_ci", right = "null_hr", stat = "max", expect = "less", by = c("subgroup"))
    )
  ),
  by = "biostatistician"
)

fig <- gl_record(
  fig, "meaning", gl_anchor(element = e_overall),
  list(
    label = "Overall OS Benefit (HR = 0.69)",
    type = "domain_interpretation",
    text = sprintf(
      "Across all %d randomized patients in Lev+5FU vs Observation, adjuvant Levamisole + 5-FU reduced mortality hazard by 31%% (HR = %.2f, 95%% CI %.2f-%.2f, p = %.4f), establishing 5-FU-based adjuvant chemotherapy as standard of care in Stage III colon cancer.",
      forest_df$n_patients[1], forest_df$hr[1], forest_df$lower_ci[1], forest_df$upper_ci[1], forest_df$p_value[1]
    ),
    source = "Moertel et al. (1990), NEJM 322:352-358",
    source_type = "literature",
    provenance = "derived",
    confidence = 0.98
  ),
  by = "medical-monitor"
)

fig <- gl_record(
  fig, "meaning", gl_anchor(element = e_nodes4),
  list(
    label = "High-Risk Nodes > 4",
    type = "domain_interpretation",
    text = sprintf(
      "Patients with > 4 positive lymph nodes (N2 disease, n = %d) show pronounced survival benefit with Lev+5FU (HR = %.2f, 95%% CI %.2f-%.2f), confirming efficacy in the highest nodal risk stratum.",
      forest_df$n_patients[2], forest_df$hr[2], forest_df$lower_ci[2], forest_df$upper_ci[2]
    ),
    source = "AJCC Nodal Staging / NCCTG 84-46-52 Subgroup Plan",
    source_type = "dataset_metadata",
    provenance = "derived",
    confidence = 0.94
  ),
  by = "medical-monitor"
)

fig <- gl_record(
  fig, "meaning", gl_anchor(element = e_perfor),
  list(
    label = "Tumor Perforation Subgroup (Small N)",
    type = "domain_interpretation",
    text = sprintf(
      "Tumor perforation at surgery occurred in only n = %d patients (%d deaths). The wide 95%% CI (%.2f-%.2f) spans 1.0 due to very low event power rather than confirmed lack of treatment effect.",
      forest_df$n_patients[10], forest_df$events[10], forest_df$lower_ci[10], forest_df$upper_ci[10]
    ),
    source = "FDA Subgroup Analysis Review Considerations",
    source_type = "regulatory_guidance",
    provenance = "speculative",
    confidence = 0.82
  ),
  by = "biostatistician"
)

# Cross-panel relation & interactive link: Panel A 5y OS <-> Panel B Overall HR
fig <- gl_record(
  fig, "relation",
  anchor = list(gl_anchor(element = e_lev5_5y), gl_anchor(element = e_overall)),
  list(
    type = "cross_panel_efficacy_correspondence",
    text = "The ~11 percentage-point 5-year OS separation between Levamisole + 5-FU and Observation in Panel A corresponds to the overall Cox hazard ratio of 0.69 in Panel B."
  ),
  by = "biostatistician"
)
fig <- gl_apply(fig, list(list(
  op = "link",
  from = gl_anchor(element = e_lev5_5y),
  to = gl_anchor(element = e_overall),
  relation = "5y OS gain -> Overall HR 0.69"
)))

# 4-step clinical review narrative walkthrough
fig <- gl_record(fig, "narrative", gl_anchor(element = e_lev5_5y),
                 list(order = 1L, text = "Start in Panel A: Levamisole + 5-FU separates cleanly from Observation and Levamisole monotherapy, reaching ~63% 5-year overall survival vs ~52% in Observation."),
                 by = "medical-writer")
fig <- gl_record(fig, "narrative", gl_anchor(element = e_overall),
                 list(order = 2L, text = "Move to Panel B: the overall Cox proportional hazards model confirms a 31% reduction in death hazard (HR = 0.69, 95% CI 0.55-0.86)."),
                 by = "medical-writer")
fig <- gl_record(fig, "narrative", gl_anchor(element = e_nodes4),
                 list(order = 3L, text = "Inspect high-risk nodal disease (Nodes > 4): efficacy remains robust in patients with heavy lymphatic involvement."),
                 by = "medical-writer")
fig <- gl_record(fig, "narrative", gl_anchor(element = e_perfor),
                 list(order = 4L, text = "Audit the statistical exceptions: small or lower-event strata such as Tumor Perforation and T2 Muscle extent have wide 95% CIs crossing 1.0 and are flagged explicitly."),
                 by = "medical-writer")

out_path <- "dev_docs/demo/case1-clinical-trial.html"
gl_workbench(fig, out_path, title = "Phase III Colon Cancer Trial (survival::colon)")
back <- gl_read(out_path)
cat(sprintf(
  "Case 1 OK: %s (%s bytes) | elements=%d | verified=%d | records=%d | roundtrip=%s\n",
  out_path, format(file.size(out_path), big.mark = ","),
  nrow(gl_elements(fig)), sum(b$status == "verified"), nrow(gl_records(fig)),
  identical(gl_elements(back), gl_elements(fig)) && identical(gl_bindings(back), gl_bindings(fig))
))
