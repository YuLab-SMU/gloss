# Generate a rich, end-to-end standalone gloss Workbench HTML artifact
# showcasing all 9 semantic stages, external contextual semantics, a verified
# overall claim, a partial per-group claim with an explicit exception group,
# cross-panel relations, reading-order narrative, and materialised operations.
#
# Run from the repository root:
#   Rscript dev_docs/demo/workbench-demo.R

suppressMessages(devtools::load_all(".", quiet = TRUE))
library(ggplot2)

p <- ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) +
  geom_point(size = 2.6) +
  facet_wrap(~am, labeller = label_both) +
  labs(
    title = "mtcars: vehicle weight vs fuel economy",
    subtitle = "Faceted by transmission (0 = automatic, 1 = manual); coloured by cylinders",
    x = "Weight (1000 lbs)",
    y = "Miles per gallon (mpg)",
    colour = "Cylinders"
  ) +
  theme_bw(base_size = 11)

fig <- gloss(p, width = 8, height = 4.8)

# 0. External Context (Task 5A: data dictionary, literature, user context;
#    dataset_documentation is also auto-sniffed from datasets::mtcars!)
fig <- gl_add_context(
  fig, "data_dictionary",
  list(
    variables = list(
      list(name = "wt", unit = "1000 lbs", description = "Vehicle curb weight in thousands of US pounds"),
      list(name = "mpg", unit = "miles / US gallon", description = "Motor Trend highway/city fuel economy"),
      list(name = "cyl", unit = "count", description = "Number of engine cylinders (4, 6, or 8; rotary mapped to 6)"),
      list(name = "am", unit = "binary (0/1)", description = "Transmission type: 0 = automatic, 1 = manual")
    )
  ),
  source = "Motor Trend US 1974 codebook",
  source_type = "data_dictionary"
)
fig <- gl_add_context(
  fig, "literature",
  list(
    citation = "Henderson, H. V., & Velleman, P. F. (1981). Building multiple regression models interactively. Biometrics, 37(2), 391-411.",
    doi = "10.2307/2530428"
  ),
  source = "Biometrics 37(2)",
  source_type = "literature"
)
fig <- gl_add_context(
  fig, "user_context",
  list(
    question = "Explain every mark, cylinder group, transmission panel, and any exception to the negative weight-mpg trend.",
    audience = "data analyst & domain reviewer"
  ),
  source = "workbench-demo",
  source_type = "user_prompt"
)
if (!isTRUE(gl_context(fig, "dataset_documentation")$found)) {
  rd_doc <- gloss:::dataset_rd_summary("mtcars")
  if (!is.null(rd_doc)) {
    fig <- gl_add_context(
      fig, "dataset_documentation",
      list(source_type = "r_package_help", datasets = list(rd_doc)),
      source = "datasets::mtcars",
      source_type = "r_package_help"
    )
  }
}

# Locate two verified points across panels for rich anchored semantics
hit_rx4 <- gl_hit(fig, 2.62, 21.0, space = "data", panel = "panel2")
e_rx4 <- hit_rx4$id[hit_rx4$tag == "circle"][1L]

hit_hornet <- gl_hit(fig, 3.215, 21.4, space = "data", panel = "panel1")
e_hornet <- hit_hornet$id[hit_hornet$tag == "circle"][1L]

hit_corolla <- gl_hit(fig, 1.835, 33.9, space = "data", panel = "panel2")
e_corolla <- hit_corolla$id[hit_corolla$tag == "circle"][1L]

# 1. Analytical Meaning (in-figure, data-grounded)
fig <- gl_record(
  fig, "meaning", gl_anchor(element = e_rx4),
  list(
    type = "analytical_meaning",
    text = "Manual 6-cylinder vehicle at wt = 2.62 (1000 lbs) and mpg = 21.0 in panel am = 1.",
    provenance = "direct",
    evidence = list(table = "built_layer1", panel = "panel2", x = 2.62, y = 21.0)
  ),
  by = "gloss-analyst"
)

# 2. Contextual Meaning (out-of-figure domain knowledge + external provenance)
fig <- gl_record(
  fig, "meaning", gl_anchor(element = e_rx4),
  list(
    type = "domain_interpretation",
    label = "Mazda RX4",
    text = "Mazda RX4 (1974): rotary-powered compact coupe classified with 6-cylinder equivalents in Motor Trend road tests; markedly lighter than automatic 6-cylinder domestic sedans.",
    source = "Henderson & Velleman (1981), Biometrics 37(2):391-411",
    source_type = "dataset_documentation",
    evidence = list(
      entity = "Mazda RX4",
      dataset = "datasets::mtcars",
      units = list(wt = "1000 lbs", mpg = "US miles/gallon"),
      transmission = "4-speed manual (am = 1)"
    ),
    provenance = "derived",
    confidence = 0.94
  ),
  by = "domain-curator"
)

fig <- gl_record(
  fig, "meaning", gl_anchor(element = e_corolla),
  list(
    type = "domain_interpretation",
    label = "Toyota Corolla",
    text = "Toyota Corolla achieves the highest fuel economy in the 1974 Motor Trend cohort (33.9 mpg) at the second-lowest curb weight (1,835 lbs).",
    source = "Motor Trend US 1974 cohort notes",
    source_type = "project_notes",
    evidence = list(entity = "Toyota Corolla", mpg_rank = 1L, wt = 1.835),
    provenance = "derived",
    confidence = 0.91
  ),
  by = "domain-curator"
)

# 3. Relation (cross-panel comparison between 6-cyl manual vs 6-cyl automatic)
fig <- gl_record(
  fig, "relation",
  list(gl_anchor(element = e_rx4), gl_anchor(element = e_hornet)),
  list(
    type = "cross_panel_comparison",
    text = "Same 6-cylinder class across transmissions: manual Mazda RX4 (2.62k lbs, 21.0 mpg) vs automatic Hornet 4 Drive (3.22k lbs, 21.4 mpg).",
    provenance = "derived"
  ),
  by = "gloss-analyst"
)

# 4. Claims (one overall verified claim + one per-group partial claim showing the 1/6 exception!)
fig <- gl_record(
  fig, "claim", gl_anchor(element = e_rx4),
  list(
    text = "Across the entire plotted dataset, heavier vehicles have lower fuel economy (slope = -5.34 mpg per 1000 lbs).",
    check = list(
      kind = "trend",
      table = "built_layer1",
      args = list(response = "y", predictor = "x", expect = "negative")
    )
  ),
  by = "gloss-verifier"
)

overall_claim_id <- gl_records(fig, layer = "claim")$id[1L]

fig <- gl_record(
  fig, "claim", gl_anchor(element = e_hornet),
  list(
    text = "Heavier vehicles show lower fuel economy in 5 of 6 transmission-by-cylinder groups; only the small automatic 4-cylinder subset (n = 3) exhibits a positive slope.",
    check = list(
      kind = "trend",
      table = "built_layer1",
      args = list(response = "y", predictor = "x", by = c("PANEL", "group"), expect = "negative")
    )
  ),
  by = "gloss-verifier",
  depends_on = overall_claim_id
)

# 5. Narrative reading sequence
fig <- gl_record(
  fig, "narrative", gl_anchor(element = e_corolla),
  list(
    order = 1L,
    text = "Start at the upper-left manual cluster: lightweight 4-cylinder compacts led by Toyota Corolla (33.9 mpg).",
    alt_text = "Manual 4-cylinder compacts sit at the top-left of panel am = 1."
  ),
  by = "storyteller",
  depends_on = overall_claim_id
)

fig <- gl_record(
  fig, "narrative", gl_anchor(element = e_rx4),
  list(
    order = 2L,
    text = "Follow the downward weight-mpg slope through 6-cylinder manuals such as Mazda RX4 (2.62k lbs, 21.0 mpg)."
  ),
  by = "storyteller",
  depends_on = overall_claim_id
)

fig <- gl_record(
  fig, "narrative", gl_anchor(element = e_hornet),
  list(
    order = 3L,
    text = "Compare panel am = 0 (automatic): heavier sedans cluster lower-right, with automatic 4-cylinders forming the sole small-sample trend exception."
  ),
  by = "storyteller",
  depends_on = overall_claim_id
)

# 6. Behavior & materialised operations
fig <- gl_record(
  fig, "behavior", gl_anchor(element = e_rx4),
  list(
    type = "interaction",
    trigger = "hover",
    operation = "tooltip",
    field = "mpg",
    text = "Reveal checked built_layer1 row, inferred mtcars entity, and contextual provenance on hover."
  ),
  by = "interaction-designer"
)

fig <- gl_apply(fig, list(
  list(op = "style", target = gl_anchor(element = e_rx4), style = "highlight"),
  list(op = "focus", target = gl_anchor(element = e_rx4)),
  list(op = "tooltip", target = gl_anchor(element = e_rx4),
       text = "Mazda RX4 · wt = 2.62k lbs · 21.0 mpg (am = 1, 6 cyl)"),
  list(op = "tooltip", target = gl_anchor(element = e_corolla),
       text = "Toyota Corolla · wt = 1.84k lbs · 33.9 mpg (cohort max)"),
  list(op = "overlay", target = gl_anchor(element = e_rx4), kind = "leader",
       text = "verified trend: -5.34 mpg / 1k lbs", basis = overall_claim_id),
  list(op = "link", from = gl_anchor(element = e_rx4), to = gl_anchor(element = e_hornet),
       relation = "6-cyl: manual vs auto")
))

out_path <- "dev_docs/demo/mtcars-workbench.html"
gl_workbench(
  fig,
  path = out_path,
  embed = "all",
  mode = "full",
  theme = "paper",
  title = "mtcars: weight vs mpg"
)

back <- gl_read(out_path)
cat(sprintf(
  "Wrote %s (%s bytes)\n  Round-trip identical elements: %s | bindings: %s | records: %d\n",
  out_path,
  format(file.size(out_path), big.mark = ","),
  identical(gl_elements(back), gl_elements(fig)),
  identical(gl_bindings(back), gl_bindings(fig)),
  nrow(gl_records(back))
))
