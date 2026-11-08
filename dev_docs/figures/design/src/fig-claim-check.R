# Figure: checking the annotation "heavier = thirstier" against the built data.
# One linear fit of mpg on wt per facet (am) x colour group (cyl), exactly the
# groups geom_smooth() draws. The claim holds in a group when the slope is < 0.
#
#   Rscript dev_docs/figures/design/src/fig-claim-check.R
# writes dev_docs/figures/design/fig-claim-check.png

library(ggplot2)
here <- "dev_docs/figures/design"
source(file.path(here, "src", "theme_research.R"))
fam <- "PingFang SC"

g <- split(mtcars, list(mtcars$am, mtcars$cyl))
d <- do.call(rbind, lapply(g, function(x) data.frame(
  am = x$am[1], cyl = x$cyl[1], n = nrow(x), slope = unname(coef(lm(mpg ~ wt, x))[2]))))
d$label <- sprintf("%s · %d 缸　n = %d", ifelse(d$am == 0, "自动挡", "手动挡"), d$cyl, d$n)
d <- d[order(d$am, d$cyl), ]
d$label <- factor(d$label, rev(d$label))
d$fails <- d$slope > 0
d$value <- sprintf("%+.2f", d$slope)
stopifnot(sum(!d$fails) == 5, abs(d$slope[d$fails] - 3.07) < 0.01)

xr <- c(-15, 5)
p <- ggplot(d, aes(slope, label)) +
  annotate("rect", xmin = 0, xmax = Inf, ymin = -Inf, ymax = Inf, fill = rw$tint_neg) +
  geom_vline(xintercept = 0, colour = rw$muted, linetype = "dashed", linewidth = 0.5) +
  annotate("text", x = -0.3, y = 6.55, label = "斜率 < 0：符合声明", hjust = 1, family = fam,
           size = 4, colour = rw$muted) +
  annotate("text", x = 0.3, y = 6.55, label = "斜率 > 0：违背声明", hjust = 0, family = fam,
           size = 4, colour = rw$highlight) +
  geom_segment(aes(x = 0, xend = slope, yend = label, colour = fails), linewidth = 0.9) +
  geom_point(aes(colour = fails), size = 4.2) +
  geom_text(aes(label = value, colour = fails, hjust = ifelse(slope > 0, -0.35, 1.35)),
            family = "Menlo", size = 4) +
  scale_colour_manual(values = c(`FALSE` = rw$neutral_dark, `TRUE` = rw$highlight), guide = "none") +
  scale_x_continuous(limits = xr, breaks = seq(-15, 5, 5)) +
  scale_y_discrete(expand = expansion(add = c(0.6, 1.1))) +
  labs(x = "回归斜率：车重每增加 1000 磅，每加仑行驶英里数（mpg）的变化", y = NULL) +
  theme_research(family = fam, grid = "x") +
  theme(axis.text.y = element_text(colour = rw$body, size = 12, hjust = 0),
        axis.line.y = element_blank(), panel.background = element_rect(fill = NA, colour = NA))

card <- rw_card(p, title = "“越重越费油”在 6 个分组里只有 5 个成立",
                subtitle = "唯一的例外是自动挡 4 缸组：只有 3 辆车，斜率为正",
                family = fam)
rw_save(card, file.path(here, "fig-claim-check.png"), width = 12, height = 6.75)
