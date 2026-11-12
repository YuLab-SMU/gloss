# Reproduce from the repository root:
# Rscript dev_docs/figures/design/src/gloss-aluminium-example.R
# This is a documentation figure, not a gloss benchmark or a product screenshot.
library(ggplot2)
library(patchwork)

data_dir <- "dev_docs/figures/design/data/aluminium-6061"
out_dir <- "dev_docs/figures/design"
metadata <- read.csv(
  file.path(data_dir, "Datafile_master_list_6061T6.csv"),
  skip = 9, check.names = FALSE, fileEncoding = "latin1"
)
experiments <- c("4655", "4886", "5327")
rows <- lapply(experiments, function(id) {
  file_name <- paste0(id, "_analyzed_w_unc")
  meta <- metadata[metadata[[1]] == file_name, , drop = FALSE]
  stopifnot(nrow(meta) == 1L)
  d <- read.csv(
    file.path(data_dir, paste0(file_name, ".csv")),
    skip = 2, check.names = FALSE, strip.white = TRUE
  )
  stopifnot(all(is.finite(d[[2]])), all(is.finite(d[[3]])))
  data.frame(
    experiment = id,
    data_row = seq_len(nrow(d)),
    time_s = d[[1]],
    strain = d[[2]],
    stress_mpa = d[[3]],
    stress_unc_mpa = d[[6]],
    temperature_c = as.numeric(meta[[3]]),
    mean_strain_rate_s = as.numeric(meta[[5]]),
    heating_time_s = as.character(meta[[7]])
  )
})
curves <- do.call(rbind, rows)
cut_strain <- 0.10
section <- do.call(rbind, lapply(rows, function(d) {
  stopifnot(min(d$strain) < cut_strain, max(d$strain) > cut_strain)
  data.frame(
    experiment = d$experiment[1],
    temperature_c = d$temperature_c[1],
    mean_strain_rate_s = d$mean_strain_rate_s[1],
    heating_time_s = d$heating_time_s[1],
    strain = cut_strain,
    stress_mpa = approx(d$strain, d$stress_mpa, xout = cut_strain)$y,
    data_rows = nrow(d)
  )
}))
stopifnot(all(is.finite(section$stress_mpa)), all(diff(section$stress_mpa) < 0))
write.csv(section, file.path(data_dir, "section-at-strain-0.10.csv"), row.names = FALSE)
write.csv(
  curves[curves$experiment == "4886" & curves$data_row == 91L, ],
  file.path(data_dir, "selected-row-4886-91.csv"), row.names = FALSE
)

palette <- c("4655" = "#195C50", "4886" = "#2F9EAE", "5327" = "#DB8636")
legend_labels <- c("4655" = "23°C · 4655", "4886" = "305°C · 4886", "5327" = "499°C · 5327")
plot_theme <- theme_minimal(base_size = 16, base_family = "PingFang SC") +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(colour = "#E7EBE9", linewidth = 0.35),
    axis.line = element_line(colour = "#72867F", linewidth = 0.45),
    plot.title = element_text(face = "bold", colour = "#173F35", size = 18),
    plot.subtitle = element_text(colour = "#64756F", size = 12),
    legend.position = "bottom",
    legend.title = element_blank(),
    legend.text = element_text(size = 12),
    plot.margin = margin(12, 18, 8, 8)
  )

p_curves <- ggplot(curves, aes(strain, stress_mpa, colour = experiment, fill = experiment)) +
  geom_ribbon(aes(ymin = stress_mpa - stress_unc_mpa, ymax = stress_mpa + stress_unc_mpa),
              colour = NA, alpha = 0.13, show.legend = FALSE) +
  geom_line(linewidth = 0.8) +
  geom_vline(xintercept = cut_strain, colour = "#94A59F", linetype = "dashed", linewidth = 0.45) +
  geom_point(data = section, size = 2.5, show.legend = FALSE) +
  scale_colour_manual(values = palette, breaks = experiments, labels = legend_labels) +
  scale_fill_manual(values = palette) +
  scale_x_continuous(breaks = seq(0, 0.5, 0.1), limits = c(0, 0.5)) +
  scale_y_continuous(breaks = seq(0, 500, 100), limits = c(0, 500)) +
  labs(
    title = "(a) 应力—应变曲线",
    subtitle = "阴影：数据文件所列的应力不确定度",
    x = "真应变 ε（无量纲）", y = "真应力 σ（MPa）"
  ) + plot_theme

p_section <- ggplot(section, aes(temperature_c, stress_mpa, colour = experiment)) +
  geom_segment(aes(xend = temperature_c, y = 0, yend = stress_mpa), linewidth = 0.6, alpha = 0.4) +
  geom_point(size = 4.4) +
  geom_text(aes(label = sprintf("%.0f MPa", stress_mpa)),
            vjust = -1.3, family = "PingFang SC", size = 5.2, show.legend = FALSE) +
  scale_colour_manual(values = palette, breaks = experiments, labels = legend_labels) +
  scale_x_continuous(breaks = section$temperature_c, limits = c(-20, 550)) +
  scale_y_continuous(breaks = seq(0, 500, 100), limits = c(0, 500)) +
  labs(
    title = "(b) ε = 0.10 处的截面比较",
    subtitle = "由各条原始曲线分别线性插值；每个点对应一次实验",
    x = "初始温度（°C）", y = "真应力 σ（MPa）"
  ) + plot_theme + theme(legend.position = "none")

figure <- p_curves / p_section +
  plot_layout(heights = c(1.35, 1)) +
  plot_annotation(
    title = "6061-T6 铝合金：三次动态压缩实验",
    subtitle = "NIST 公开数据重绘｜试验 4655、4886、5327",
    caption = paste(
      "初始温度依次为 23、305、499°C；平均应变率为 2400、2900、3100 s⁻¹。",
      "三次试验条件不同；这张图不单独证明温度的因果作用。",
      "数据：NIST mds2-3090｜本图为 R 绘制的说明用科学图。", sep = "\n"
    ),
    theme = theme(
      text = element_text(family = "PingFang SC"),
      plot.title = element_text(face = "bold", colour = "#173F35", size = 21),
      plot.subtitle = element_text(colour = "#64756F", size = 13),
      plot.caption = element_text(hjust = 0, colour = "#64756F", size = 10),
      plot.margin = margin(20, 18, 18, 18)
    )
  )

ragg::agg_png(file.path(out_dir, "gloss-aluminium-original-v1.png"),
              width = 1440, height = 1680, res = 160, background = "white")
print(figure)
invisible(dev.off())
ggsave(file.path(out_dir, "gloss-aluminium-original-v1.svg"), figure,
       width = 9, height = 10.5, units = "in", device = svglite::svglite, bg = "white")
print(section, row.names = FALSE)
cat("Total raw observations:", nrow(curves), "\n")
cat("This comparison describes only the three selected experiments.\n")
