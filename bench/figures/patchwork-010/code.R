# gloss bench figure patchwork-010
# source: web-choropleth-barchart-map.Rmd (gallery)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- chunk 1 ----
knitr::opts_chunk$set(
  warning = FALSE,
  message = FALSE
  )
# ---- chunk 2 ----
library(ggplot2)
library(ggthemes)
library(patchwork)
library(dplyr)
library(readr)
library(sf)
# ---- chunk 3 ----
atlas <- readr::read_rds(
  "data/atlas_sp_hdi.rds"
  )
# ---- chunk 4 ----
#| out-width: "90%"
ggplot(atlas) +
  geom_sf(aes(fill = HDI), lwd = 0.05, color = "white")
# ---- chunk 5 ----
#| out-width: "90%"
ggplot(atlas) +
  geom_sf(aes(fill = HDI), lwd = 0.05, color = "white") +
  scale_fill_fermenter(
    name = "",
    breaks = seq(0.65, 0.95, 0.05),
    direction = 1,
    palette = "YlGnBu"
  )
# ---- chunk 6 ----
#| out-width: "100%"
#| out-height: 900px
#| fig-width: 9
#| fig-height: 11
#| fig-format: svg
pmap <- ggplot(atlas) +
  geom_sf(aes(fill = HDI), lwd = 0.05, color = "white") +
  scale_fill_fermenter(
    name = "",
    breaks = seq(0.65, 0.95, 0.05),
    direction = 1,
    palette = "YlGnBu"
  ) +
  labs(
    title = "HDI in Sao Paulo, BR (2010)",
    subtitle = "Microregion HDI in Sao Paulo",
    caption = "Source: Atlas Brasil"
  ) +
  theme_map() +
  theme(
    # Legend
    legend.position = "top",
    legend.justification = 0.5,
    legend.key.size = unit(1.25, "cm"),
    legend.key.width = unit(1.75, "cm"),
    legend.text = element_text(size = 12),
    legend.margin = margin(),
    # Increase size and horizontal alignment of the both the title and subtitle
    plot.title = element_text(size = 28, hjust = 0.5),
    plot.subtitle = element_text(hjust = 0.5)
  )

pmap
# ---- chunk 7 ----
# Calculate population share in each HDI group
pop_hdi <- atlas |> 
  st_drop_geometry() |> 
  mutate(
    group_hdi = findInterval(HDI, seq(0.65, 0.95, 0.05), left.open = FALSE),
    group_hdi = factor(group_hdi)
  ) |> 
  group_by(group_hdi) |> 
  summarise(score = sum(pop, na.rm = TRUE)) |> 
  ungroup() |> 
  mutate(share = score / sum(score) * 100) |> 
  na.omit()

ggplot(pop_hdi, aes(group_hdi, share, fill = group_hdi)) +
  geom_col()
# ---- chunk 8 ----
# Create a variable to store the position of the text label
pop_hdi <- pop_hdi |> 
  mutate(
    y_text = if_else(group_hdi %in% c(0, 7), share + 3, share - 3),
    label = paste0(round(share, 1), "%")
  )

ggplot(pop_hdi, aes(group_hdi, share, fill = group_hdi)) +
  geom_col() +
  geom_hline(yintercept = 0) +
  # Text labels
  geom_text(
    aes(y = y_text, label = label, color = group_hdi),
    size = 3
  ) +
  coord_flip() +
  # Use the same color palette as the map
  scale_fill_brewer(palette = "YlGnBu") +
  # Swap between black and white text
  scale_color_manual(values = c(rep("black", 5), rep("white", 2), "black")) +
  # Hide color legend
  guides(fill = "none", color = "none")
# ---- chunk 9 ----
# Labels for the color legend
x_labels <- c(
  "0.650 or less", "0.650 to 0.699", "0.700 to 0.749", "0.750 to 0.799",
  "0.800 to 0.849", "0.850 to 0.899", "0.900 to 0.949", "0.950 or more"
  )

pcol <- ggplot(pop_hdi, aes(group_hdi, share, fill = group_hdi)) +
  geom_col() +
  geom_hline(yintercept = 0) +
  geom_text(
    aes(y = y_text, label = label, color = group_hdi),
    size = 4
  ) +
  coord_flip() +
  scale_x_discrete(labels = x_labels) +
  scale_fill_brewer(palette = "YlGnBu") +
  scale_color_manual(values = c(rep("black", 5), rep("white", 2), "black")) +
  guides(fill = "none", color = "none") +
  labs(
    title = "Population share by HDI group",
    x = NULL,
    y = NULL
  ) +
  theme_void() +
  theme(
    panel.grid = element_blank(),
    plot.title = element_text(size = 14),
    axis.text.y = element_text(size = 8),
    axis.text.x = element_blank()
  )

pcol
# ---- chunk 10 ----
#| out-width: "100%"
#| out-height: 900px
#| fig-width: 9
#| fig-height: 11
#| fig-format: svg
p_hdi_atlas <- 
  pmap + inset_element(pcol, left = 0.50, bottom = 0.05, right = 1, top = 0.5)

p_hdi_atlas
