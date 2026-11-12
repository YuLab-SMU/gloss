# gloss bench figure exts-006
# source: ggperiodic (examples)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(ggperiodic)
# ---- chunk 1 ----
### Name: periodic
### Title: Add or remove periodic variables
### Aliases: periodic periodic.default periodic.data.frame setperiodic

### ** Examples

library(ggplot2)

x <- seq(0, 360 - 20, by = 20)
df <- data.frame(x = x, y = cos(x*pi/180))
df_p <- periodic(df, x = c(0, 360))

ggplot(df_p, aes(x, y)) +
   geom_line() +            # periodic data
   geom_point(data = df)    # non periodic data

# Extend domain
ggplot(df_p, aes(x, y), x = c(-180, 540)) +
   geom_line() +
   geom_point(data = df)
