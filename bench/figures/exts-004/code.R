# gloss bench figure exts-004
# source: gginnards (examples)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(gginnards)
# ---- chunk 1 ----
### Name: gginnards-package
### Title: gginnards: Explore the Innards of 'ggplot2' Objects
### Aliases: gginnards gginnards-package

### ** Examples

# echo the 'data' and 'params' as received by 'draw_panel()'
ggplot(mtcars, aes(cyl, mpg, color = factor(cyl))) +
  geom_point() +
  geom_debug_panel()

# echo the 'data' and 'params' as received by 'draw_group()'
ggplot(mtcars, aes(cyl, mpg, color = factor(cyl))) +
  geom_point() +
  geom_debug_group()

# echo the 'data' and 'params' as received by 'draw_panel()'
ggplot(mtcars, aes(cyl, mpg, colour = factor(cyl))) +
  stat_summary(fun.data = "mean_se") +
  stat_summary(fun.data = "mean_se", geom = "debug_panel")

# echo the 'data' received by 'compute_panel()'
ggplot(mtcars, aes(cyl, mpg, color = factor(cyl))) +
  geom_point() +
  stat_debug_panel()

# echo the 'data' received by 'compute_group()'
ggplot(mtcars, aes(cyl, mpg, color = factor(cyl))) +
  geom_point() +
  stat_debug_group()
