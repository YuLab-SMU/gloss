# gloss bench figure gallery-037
# source: package/ggthemes.Rmd (gallery)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- chunk 1 ----
knitr::opts_chunk$set(warning = FALSE, message = FALSE, fig.align = "center")
# ---- chunk 2 ----
library(ggplot2)
library(ggthemes)
p <- ggplot(iris, aes(x = Sepal.Length, y = Sepal.Width, color = Species)) +
  geom_point(size = 4)
p + theme_economist() + scale_color_economist()
# ---- chunk 3 ----
# install.packages("ggthemes") # [bench: install call removed]
# ---- chunk 4 ----
library(ggplot2)
library(ggthemes)

p <- ggplot(iris, aes(x = Sepal.Length, y = Sepal.Width, color = Species, shape = Species)) +
  geom_point(size = 4) +
  labs(
    title = "Sepal Length vs Sepal Width by Species",
    x = "Sepal Length (cm)",
    y = "Sepal Width (cm)",
    caption = "Data source: Iris dataset"
  )

p + theme_economist()
# ---- chunk 5 ----
p + theme_fivethirtyeight() + scale_color_fivethirtyeight()
# ---- chunk 6 ----
p + theme_economist()
# ---- chunk 7 ----
p + theme_excel() + scale_color_excel()
# ---- chunk 8 ----
p + theme_calc() + scale_color_calc() + scale_shape_calc()
# ---- chunk 9 ----
p + theme_igray()
# ---- chunk 10 ----
p + theme_few()
# ---- chunk 11 ----
p + theme_solarized() + scale_color_solarized()
# ---- chunk 12 ----
p + theme_solarized(light = FALSE) + scale_color_solarized()
# ---- chunk 13 ----
p + theme_tufte()
# ---- chunk 14 ----
p + theme_wsj()
# ---- chunk 15 ----
p + theme_stata() + scale_color_stata() + scale_shape_stata()
