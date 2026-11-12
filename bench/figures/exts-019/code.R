# gloss bench figure exts-019
# source: ggsurveillance (examples)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(ggsurveillance)
# ---- chunk 1 ----
### Name: geom_vline_year
### Title: Automatically create lines at the turn of every year
### Aliases: geom_vline_year geom_hline_year

### ** Examples

library(ggplot2)
set.seed(1)

plot_data_epicurve_imp <- data.frame(
  date = rep(as.Date("2023-12-01") + ((0:300) * 1), times = rpois(301, 0.5))
)

# Break type day
ggplot(plot_data_epicurve_imp, aes(x = date, weight = 2)) +
  geom_epicurve(date_resolution = "week") +
  geom_vline_year() +
  labs(title = "Epicurve Example") +
  scale_y_cases_5er() +
  scale_x_date(date_breaks = "4 weeks", date_labels = "W%V'%g") + # Correct ISOWeek labels week'year
  theme_bw()
