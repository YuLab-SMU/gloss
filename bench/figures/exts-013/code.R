# gloss bench figure exts-013
# source: geomtextpath (examples)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(geomtextpath)
# ---- chunk 1 ----
### Name: geom_textcurve
### Title: Text on a curve
### Aliases: geom_textcurve geom_labelcurve

### ** Examples

t <- seq(0, 2 * pi, length.out = 4)[-1]

df <- data.frame(
  x = cos(t),
  y = sin(t),
  xend = cos(t + 1.8),
  yend = sin(t + 1.8)
)

ggplot(df, aes(x, y, xend = xend, yend = yend)) +
  geom_textcurve(
    label = c(
      "A chicken lays an egg",
      "A chick becomes a chicken",
      "An egg hatches into a chick"
    ),
    curvature = 0.5, vjust = 2,
    arrow = arrow(ends = "first")
  ) +
  coord_equal(xlim = c(-1.1, 1.1), ylim = c(-1.1, 1.1))
