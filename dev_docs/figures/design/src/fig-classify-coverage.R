# Figure: deterministic classification coverage, one square per drawn element.
# Numbers come from dev_docs/research/capture-groups/classify.out (re-run 2026-11-08);
# the two misclassified base elements are the legend box (graphics-plot-1-rect-1)
# and the legend line (graphics-plot-1-segments-1), both matched by the "data" rule.
#
#   Rscript dev_docs/figures/design/src/fig-classify-coverage.R
# writes dev_docs/figures/design/fig-classify-coverage.png

library(ggplot2)
here <- "dev_docs/figures/design"
source(file.path(here, "src", "theme_research.R"))
fam <- "PingFang SC"

blocks <- list(
  list(title = "ggplot：分面 + 回归 + 注释 + 图例", n = 134, residual = 2, wrong = 0,
       note = "2 条 annotate() 文字：未分类，留给 agent"),
  list(title = "ComplexHeatmap：热图 + 注释轨道 + 树状图", n = 292, residual = 0, wrong = 0,
       note = "全部由规则分类"),
  list(title = "base：散点 + 回归线 + 图例", n = 60, residual = 1, wrong = 2,
       note = c("图例文字：未分类，留给 agent", "图例的框和线：被错分为数据标记"))
)

cols <- 30
sq <- list(); ttl <- list(); lab <- list()
y0 <- 0
for (b in blocks) {
  status <- c(rep("rule", b$n - b$residual - b$wrong), rep("residual", b$residual), rep("wrong", b$wrong))
  i <- seq_len(b$n) - 1
  d <- data.frame(x = i %% cols + 1, y = y0 - 1.6 - i %/% cols, status = status)
  sq[[length(sq) + 1]] <- d
  ok <- b$n - b$residual - b$wrong
  ttl[[length(ttl) + 1]] <- data.frame(x = 0.5, y = y0, title = b$title,
                                       count = sprintf("规则分对 %d / %d", ok, b$n))
  last <- d[nrow(d), ]
  if (length(b$note) == 1) {
    lab[[length(lab) + 1]] <- data.frame(x = last$x + 1.1, y = last$y, text = b$note,
      colour = if (b$residual > 0) rw$output else rw$muted)
  } else {
    lab[[length(lab) + 1]] <- data.frame(x = last$x + 1.1, y = last$y + c(0.55, -0.55), text = b$note,
      colour = c(rw$output, rw$highlight))
  }
  y0 <- min(d$y) - 1.9
}
sq <- do.call(rbind, sq); ttl <- do.call(rbind, ttl); lab <- do.call(rbind, lab)

fill <- c(rule = "#9DBBE0", residual = "#FFFFFF", wrong = rw$highlight)
line <- c(rule = NA, residual = rw$output, wrong = NA)

p <- ggplot() +
  geom_tile(data = sq, aes(x, y, fill = status, colour = status), width = 0.8, height = 0.8, linewidth = 0.7) +
  scale_fill_manual(values = fill, guide = "none") +
  scale_colour_manual(values = line, guide = "none", na.value = NA) +
  geom_text(data = ttl, aes(x, y, label = title), hjust = 0, vjust = 0.5, family = fam,
            fontface = "bold", size = 4.6, colour = rw$ink) +
  geom_text(data = ttl, aes(x + 30.5, y, label = count), hjust = 1, vjust = 0.5, family = fam,
            size = 4.2, colour = rw$internal) +
  geom_text(data = lab, aes(x, y, label = text, colour = I(colour)), hjust = 0, vjust = 0.5,
            family = fam, size = 4.2) +
  coord_equal(xlim = c(0.4, 45), clip = "off") +
  theme_research(family = fam, grid = "none") +
  theme(axis.text = element_blank(), axis.title = element_blank(), axis.line = element_blank(),
        panel.background = element_rect(fill = NA, colour = NA))

card <- rw_card(p, title = "只靠命名规则，486 个绘制元素分对了 481 个",
                subtitle = "剩下的 5 个都是注释文字或 base 图例　·　每个方块是一个绘制出来的元素",
                family = fam)
rw_save(card, file.path(here, "fig-classify-coverage.png"), width = 12, height = 7.2)
