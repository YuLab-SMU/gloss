# gloss bench figure gallery-053
# source: package/gganimate.Rmd (gallery)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- chunk 1 ----
knitr::opts_chunk$set(warning = FALSE, message = FALSE)
# ---- chunk 2 ----
library(ggplot2)
library(gganimate)
library(gapminder)

p <- ggplot(gapminder, aes(gdpPercap, lifeExp, size = pop, colour = country)) +
  geom_point(alpha = 0.7, show.legend = FALSE) +
  scale_colour_manual(values = country_colors) +
  scale_size(range = c(2, 12)) +
  scale_x_log10() +
  facet_wrap(~continent) +
  labs(title = "Year: {frame_time}", x = "GDP per capita", y = "life expectancy")

anim <- p + transition_time(year) +
  ease_aes("linear")

anim
