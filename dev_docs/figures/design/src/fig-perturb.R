# Figure: what the perturbed and counterfactual versions of a benchmark figure
# look like (design.qmd, section "评测设计"). Real data (mtcars); the check is
# the per-figure slope of the y column on the x column, computed on the data
# each panel draws.
#
#   Rscript dev_docs/figures/design/src/fig-perturb.R
# writes dev_docs/figures/design/fig-perturb.png

library(ggplot2)
library(patchwork)
here <- "dev_docs/figures/design"
source(file.path(here, "src", "theme_research.R"))
fam <- "PingFang SC"
set.seed(20261108)

d0 <- data.frame(x = mtcars$wt, y = mtcars$mpg, g = factor(mtcars$cyl))

# Perturbed: names and levels replaced; each numeric column gets a random
# increasing affine map; row order shuffled. Structure is kept.
aff <- function(v) { a <- round(runif(1, 0.5, 3), 2); b <- round(runif(1, -20, 20), 1); a * v + b }
d1 <- d0[sample(nrow(d0)), ]
d1$x <- aff(d1$x); d1$y <- aff(d1$y)
levels(d1$g) <- c("k2", "q7", "z5")

# Counterfactual: real names kept; y reflected onto its own range
# (min + max - y), so the marginal range is unchanged and the trend reverses.
d2 <- d0
d2$y <- min(d0$y) + max(d0$y) - d0$y
stopifnot(isTRUE(all.equal(range(d2$y), range(d0$y))))

slope <- function(d) unname(coef(lm(y ~ x, d))[2])
s <- c(slope(d0), slope(d1), slope(d2))
stopifnot(s[1] < 0, s[2] < 0, s[3] > 0)

panel <- function(d, xlab, ylab, claim, ok, head) {
  verdict <- sprintf("%s  斜率 %+.2f，声明%s", if (ok) "✓" else "✗", slope(d), if (ok) "成立" else "不成立")
  ggplot(d, aes(x, y)) +
    geom_smooth(method = "lm", formula = y ~ x, se = FALSE, colour = rw$muted, linewidth = 0.7) +
    geom_point(aes(colour = g), size = 2.3) +
    annotate("label", x = Inf, y = Inf, label = claim, hjust = 1.05, vjust = 1.3, family = "Menlo",
             size = 3.6, colour = rw$output, fill = rw$card_body, label.size = 0.3) +
    scale_colour_manual(values = c("#5E5D59", "#9C9A92", "#C8C7BF"), name = NULL) +
    labs(x = xlab, y = ylab, title = head, subtitle = verdict) +
    theme_research(family = fam, grid = "xy") +
    theme(plot.title = element_text(size = 15, face = "bold", hjust = 0, colour = rw$ink),
          plot.subtitle = element_text(size = 12.5, hjust = 0,
                                       colour = if (ok) rw$ok else rw$highlight),
          legend.position = "bottom", legend.text = element_text(family = "Menlo", size = 10),
          axis.title = element_text(family = "Menlo", size = 11, colour = rw$body))
}

p <- panel(d0, "wt", "mpg", "heavier = thirstier", TRUE, "原图") +
  panel(d1, "dvx", "hlr", "more dvx = less hlr", TRUE, "扰动：改名、保序变换、打乱行序") +
  panel(d2, "wt", "mpg", "heavier = thirstier", FALSE, "反事实：名字不变，关系反过来")

# rw_card() takes a single ggplot, so the card is assembled here for a patchwork.
u <- grid::unit
pg <- patchwork::patchworkGrob(p & theme(plot.background = element_rect(fill = NA, colour = NA)))
card <- grid::gTree(children = grid::gList(
  grid::rectGrob(gp = grid::gpar(fill = rw$canvas, col = NA)),
  grid::textGrob("扰动去掉能认出来的线索；反事实让常识和数据给出相反的答案",
                 y = u(1, "npc") - u(0.5, "in"),
                 gp = grid::gpar(fontsize = 24, fontface = "bold", col = rw$ink, fontfamily = fam)),
  grid::textGrob("mtcars 实测，斜率在每个面板自己画出的数据上计算。只凭常识判断的模型，会在第三个面板上答错",
                 y = u(1, "npc") - u(0.9, "in"),
                 gp = grid::gpar(fontsize = 14, col = rw$muted, fontfamily = fam)),
  grid::grobTree(
    grid::roundrectGrob(r = u(0.22, "in"), gp = grid::gpar(fill = rw$panel, col = NA)),
    grid::grobTree(pg, vp = grid::viewport(width = u(1, "npc") - u(0.5, "in"),
                                           height = u(1, "npc") - u(0.35, "in"))),
    vp = grid::viewport(x = u(0.3, "in"), y = u(0.3, "in"), just = c("left", "bottom"),
                        width = u(1, "npc") - u(0.6, "in"), height = u(1, "npc") - u(1.45, "in")))
))
rw_save(card, file.path(here, "fig-perturb.png"), width = 14, height = 6.6)
