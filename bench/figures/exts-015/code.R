# gloss bench figure exts-015
# source: ggsurvfit (examples)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(ggsurvfit)
# ---- chunk 1 ----
### Name: add_confidence_interval
### Title: Add Confidence Interval
### Aliases: add_confidence_interval

### ** Examples

survfit2(Surv(time, status) ~ sex, data = df_lung) %>%
  ggsurvfit() +
  add_confidence_interval() +
  scale_ggsurvfit()
