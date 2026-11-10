# gloss bench figure exts-007
# source: ggpattern (examples)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(ggpattern)
# ---- chunk 1 ----
### Name: scale_pattern_manual
### Title: Create your own discrete scale
### Aliases: scale_pattern_manual scale_pattern_type_manual
###   scale_pattern_subtype_manual scale_pattern_angle_manual
###   scale_pattern_density_manual scale_pattern_spacing_manual
###   scale_pattern_xoffset_manual scale_pattern_yoffset_manual
###   scale_pattern_alpha_manual scale_pattern_linetype_manual
###   scale_pattern_size_manual scale_pattern_shape_manual
###   scale_pattern_colour_manual scale_pattern_fill_manual
###   scale_pattern_fill2_manual scale_pattern_aspect_ratio_manual
###   scale_pattern_key_scale_factor_manual scale_pattern_filename_manual
###   scale_pattern_filter_manual scale_pattern_gravity_manual
###   scale_pattern_scale_manual scale_pattern_orientation_manual
###   scale_pattern_phase_manual scale_pattern_frequency_manual
###   scale_pattern_grid_manual scale_pattern_res_manual
###   scale_pattern_rot_manual scale_pattern_units_manual
###   scale_pattern_color_manual

### ** Examples

  if (require('ggplot2')) {
    gg <- ggplot(mtcars) +
       geom_density_pattern(
         aes(
           x            = mpg,
           pattern_fill = as.factor(cyl),
           pattern_type = as.factor(cyl)
         ),
         pattern = 'polygon_tiling',
         pattern_key_scale_factor = 1.2
       ) +
       scale_pattern_type_manual(values = c('hexagonal', 'rhombille',
                                  'pythagorean')) +
       theme_bw(18) +
       theme(legend.key.size = unit(2, 'cm')) +
       labs(
         title    = 'ggpattern::geom_density_pattern()',
         subtitle = 'pattern = \'polygon_tiling\''
       )
    plot(gg)
  }
