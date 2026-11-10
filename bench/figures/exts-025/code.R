# gloss bench figure exts-025
# source: ggspectra (examples)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(ggspectra)
# ---- chunk 1 ----
### Name: scale_y_Tfr_continuous
### Title: Transmittance y-scale
### Aliases: scale_y_Tfr_continuous scale_y_Tfr_internal_continuous
###   scale_y_Tfr_total_continuous

### ** Examples


Tfr_as_default()

ggplot(yellow_gel.spct) +
  geom_line() +
  scale_y_Tfr_continuous(Tfr.type = getTfrType(yellow_gel.spct)) +
  scale_x_wl_continuous()

ggplot(yellow_gel.spct) +
  geom_line() +
  scale_y_Tfr_continuous(unit.exponent = -2,
                         Tfr.type = getTfrType(yellow_gel.spct)) +
  scale_x_wl_continuous()

ggplot(yellow_gel.spct) +
  geom_line() +
  scale_y_Tfr_continuous(unit.exponent = -3,
                         Tfr.type = getTfrType(yellow_gel.spct)) +
  scale_x_wl_continuous()

ggplot(yellow_gel.spct) +
  geom_line() +
  scale_y_Tfr_total_continuous() +
  scale_x_wl_continuous()

ggplot(yellow_gel.spct) +
  geom_line() +
  scale_y_Tfr_total_continuous(axis.symbols = FALSE) +
  scale_x_wl_continuous(axis.symbols = FALSE)

ggplot(normalize(yellow_gel.spct)) +
  geom_line() +
  scale_y_Tfr_total_continuous(normalized = "max") +
  scale_x_wl_continuous()
