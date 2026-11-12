# gloss bench figure exts-008
# source: ggerror (examples)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(ggerror)
# ---- chunk 1 ----
### Name: stat_error
### Title: Summarising stat for 'geom_error()'
### Aliases: stat_error StatError GeomErrorStat

### ** Examples

library(ggplot2)

ggplot(mtcars, aes(factor(cyl), mpg)) + stat_error()
