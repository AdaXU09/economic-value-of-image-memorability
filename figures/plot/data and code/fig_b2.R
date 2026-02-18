################################################################################
# Figure B2 (Raincloud): Sentiment distribution + star-rating M/SD annotations
# Cloud uses original ggplot2 violin behavior (trimmed, scale as in geom_violin)
#
# Last updated: 2026-02-12
################################################################################

# ==============================================================================
# PACKAGES & ENVIRONMENT
# ==============================================================================

package_list <- c("tidyverse", "lemon", "grid", "scales", "svglite")

load_packages <- function(pkgs) {
  new_pkgs <- pkgs[!(pkgs %in% installed.packages()[, "Package"])]
  if (length(new_pkgs)) install.packages(new_pkgs)
  invisible(lapply(pkgs, library, character.only = TRUE))
}
load_packages(package_list)

if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
  setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
}

# ==============================================================================
# GLOBAL PARAMETERS
# ==============================================================================

FONT_FAMILY    <- "sans"
FONT_SIZE_PT   <- 14
FONT_SIZE_GEOM <- FONT_SIZE_PT / .pt

LINE_SIZE      <- 0.25
TICK_LENGTH_PT <- 5

group_colors <- c(
  "All businesses" = "#D55E00",
  "Restaurants"    = "#0072B2",
  "Drinks"         = "#009E73"
)

alpha_values <- c(
  "Established" = 0.75,
  "Emerging"    = 0.45
)

X_LIM    <- c(0.8, 3.55)
Y_LIM    <- c(-1, 1)
Y_BREAKS <- c(-1, -0.5, 0, 0.5, 1)

FIG_WIDTH  <- 10.5
FIG_HEIGHT <- 6.0

# Rain tuning
POINTS_MAX_PER_CELL   <- 1500
POINT_SIZE            <- 0.55
POINT_NUDGE           <- 0.02
POINT_JITTER_POSITIVE <- 0.22
POINT_SEED            <- 123

# Violin (match original)
VIOLIN_WIDTH <- 0.45
HALF_WIDTH   <- VIOLIN_WIDTH / 2

# ==============================================================================
# SHARED THEME
# ==============================================================================

theme_figure_b2 <- function() {
  list(
    theme_classic(base_size = FONT_SIZE_PT, base_family = FONT_FAMILY),
    theme(
      text              = element_text(size = FONT_SIZE_PT, family = FONT_FAMILY),
      axis.ticks.length = unit(TICK_LENGTH_PT, "pt"),
      axis.ticks        = element_line(colour = "black", linewidth = LINE_SIZE),
      axis.text         = element_text(size = FONT_SIZE_PT, colour = "black"),
      axis.line         = element_line(colour = "black", linewidth = LINE_SIZE),
      axis.title        = element_text(size = FONT_SIZE_PT, colour = "black"),
      legend.position   = "none",
      
      axis.ticks.x      = element_blank(),
      axis.text.x       = element_blank(),
      axis.line.x       = element_line(colour = NA),
      axis.title.x      = element_blank(),
      
      plot.margin       = margin(t = 6, r = 6, b = 38, l = 6, unit = "pt")
    ),
    coord_capped_cart(
      bottom = capped_horizontal(),
      left   = capped_vertical(capped = "both"),
      xlim   = X_LIM,
      ylim   = Y_LIM
    )
  )
}

# ==============================================================================
# DATA IMPORT & PREP
# ==============================================================================

file_business <- "study1_2_business_data.csv"
file_res      <- "study1_2_res_data.csv"
file_drink    <- "study1_2_drink_data.csv"

data_raw1 <- readr::read_csv(file_business, show_col_types = FALSE)
data_raw2 <- readr::read_csv(file_res,      show_col_types = FALSE)
data_raw3 <- readr::read_csv(file_drink,    show_col_types = FALSE)

if ("person_total_count_review_high" %in% names(data_raw3)) {
  data_raw3 <- data_raw3[, setdiff(names(data_raw3), "person_total_count_review_high")]
}

data_raw1$group <- "All businesses"
data_raw2$group <- "Restaurants"
data_raw3$group <- "Drinks"

data_combined <- dplyr::bind_rows(data_raw1, data_raw2, data_raw3) %>%
  mutate(
    group = factor(group, levels = c("All businesses", "Restaurants", "Drinks")),
    review_group = dplyr::case_when(
      review_group == "high" ~ "Established",
      review_group == "low"  ~ "Emerging",
      TRUE                   ~ as.character(review_group)
    ),
    review_group = factor(review_group, levels = c("Established", "Emerging"))
  )

# ==============================================================================
# POSITIONS
# ==============================================================================

x_positions  <- c(1.0, 1.4,  2.0, 2.4,  3.0, 3.4)
x_top_labels <- c(1.2, 2.2, 3.2)

pos_map <- tibble::tibble(
  group = factor(rep(c("All businesses", "Restaurants", "Drinks"), each = 2),
                 levels = c("All businesses", "Restaurants", "Drinks")),
  review_group = factor(rep(c("Established", "Emerging"), times = 3),
                        levels = c("Established", "Emerging")),
  x_pos = x_positions
)

data_combined <- data_combined %>%
  left_join(pos_map, by = c("group", "review_group"))

# ==============================================================================
# SUMMARY STATS (STAR RATINGS) + LABELS
# ==============================================================================

stats_table <- data_combined %>%
  group_by(group, review_group) %>%
  summarise(
    N    = n(),
    Mean = mean(star_avg, na.rm = TRUE),
    SD   = sd(star_avg, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  left_join(pos_map, by = c("group", "review_group")) %>%
  arrange(x_pos) %>%
  mutate(
    stats_label = paste0(
      "M = ", sprintf("%.2f", Mean), "\n",
      "SD = ", sprintf("%.2f", SD)
    ),
    xaxis_label = paste0(
      review_group, "\n",
      "(n = ", scales::comma(N), ")"
    )
  )

# ==============================================================================
# RAIN POINTS (sample per cell; one-sided jitter)
# ==============================================================================

set.seed(POINT_SEED)

rain_points <- data_combined %>%
  group_by(group, review_group) %>%
  mutate(.rand = runif(n())) %>%
  arrange(.rand, .by_group = TRUE) %>%
  { if (is.infinite(POINTS_MAX_PER_CELL)) . else slice_head(., n = POINTS_MAX_PER_CELL) } %>%
  ungroup() %>%
  select(-.rand) %>%
  mutate(
    x_scatter = x_pos + POINT_NUDGE + runif(n(), 0, POINT_JITTER_POSITIVE)
  )

# ==============================================================================
# MASK TO HIDE RIGHT HALF OF VIOLIN (keeps original violin scaling/tails)
# ==============================================================================

mask_df <- pos_map %>%
  mutate(
    xmin = x_pos,
    xmax = x_pos + HALF_WIDTH + 0.002,
    ymin = -Inf,
    ymax =  Inf
  )

# Flat edge line for each half-violin (matches trimmed min/max)
edge_df <- data_combined %>%
  group_by(group, review_group) %>%
  summarise(
    x     = unique(x_pos),
    y_min = min(contents_score_avg, na.rm = TRUE),
    y_max = max(contents_score_avg, na.rm = TRUE),
    .groups = "drop"
  )

# ==============================================================================
# FIGURE
# ==============================================================================

y_xlabels <- -1.05
y_stats   <- -0.90
y_note    <- -1.22

top_titles <- pos_map %>%
  group_by(group) %>%
  summarise(
    x = mean(x_pos) + POINT_NUDGE + 0.1 * POINT_JITTER_POSITIVE,
    y = 1.05,
    label = as.character(first(group)),
    .groups = "drop"
  )


note_text <- "Star ratings"

note_anchor <- stats_table %>%
  filter(group == "All businesses", review_group == "Established") %>%
  slice(1)

note_x <- note_anchor$x_pos
note_y <- y_stats + 0.22   # tweak this up/down as needed

figure_b2_raincloud <- ggplot(
  data_combined,
  aes(
    x     = x_pos,
    y     = contents_score_avg,
    fill  = group,
    alpha = review_group,
    group = interaction(group, review_group)
  )
) +
  # Cloud: original violin (full)
  geom_violin(
    trim      = TRUE,
    width     = VIOLIN_WIDTH,
    color     = "black",
    linewidth = LINE_SIZE
  ) +
  # Mask: hide right half to create a half-violin
  geom_rect(
    data = mask_df,
    aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax),
    inherit.aes = FALSE,
    fill = "white",
    color = NA
  ) +
  # Flat edge line
  geom_segment(
    data = edge_df,
    aes(x = x, xend = x, y = y_min, yend = y_max),
    inherit.aes = FALSE,
    color = "black",
    linewidth = LINE_SIZE
  ) +
  # Rain: sampled points to the right
  geom_point(
    data = rain_points,
    aes(x = x_scatter, y = contents_score_avg, color = group, alpha = review_group),
    inherit.aes = FALSE,
    size = POINT_SIZE,
    shape = 16
  ) +
  # Boxplot (sentiment)
  geom_boxplot(
    width         = 0.12,
    fill          = "white",
    color         = "black",
    linewidth     = LINE_SIZE,
    outlier.shape = NA,
    alpha         = 1
  ) +
  # Mean point (sentiment)
  stat_summary(
    fun    = mean,
    geom   = "point",
    shape  = 21,
    size   = 3.0,
    fill   = "black",
    color  = "white",
    stroke = LINE_SIZE,
    alpha  = 1
  ) +
  # Neutral reference line
  geom_hline(
    yintercept = 0,
    linetype   = "dashed",
    color      = "grey60",
    linewidth  = LINE_SIZE
  ) +
  annotate(
    "text",
    x      = 1.70,
    y      = 0.05,
    label  = "Neutral",
    hjust  = 0,
    vjust  = 0,
    size   = FONT_SIZE_GEOM,
    family = FONT_FAMILY,
    color  = "grey40"
  ) +
  # Star-rating M/SD labels
  annotate(
    "text",
    x      = stats_table$x_pos,
    y      = y_stats,
    label  = stats_table$stats_label,
    hjust  = 0.5,
    vjust  = 0,
    size   = FONT_SIZE_GEOM,
    family = FONT_FAMILY,
    color  = "grey40",
    lineheight = 1.1
  ) +
  # Top titles
  geom_text(
    data = top_titles,
    aes(x = x, y = y, label = label),
    inherit.aes = FALSE,
    hjust  = 0.5,
    vjust  = 0,
    size   = FONT_SIZE_GEOM,
    family = FONT_FAMILY
  ) +
  # Bottom labels (category + n)
  annotate(
    "text",
    x      = stats_table$x_pos,
    y      = y_xlabels,
    label  = stats_table$xaxis_label,
    hjust  = 0.5,
    vjust  = 1,
    size   = FONT_SIZE_GEOM,
    family = FONT_FAMILY,
    lineheight = 1.1
  ) +
  # Clarifying note
  annotate(
    "text",
    x      = note_x,
    y      = note_y,
    label  = note_text,
    hjust  = 0.5,
    vjust  = 0,              # anchor bottom of the note at note_y
    size   = FONT_SIZE_GEOM,
    family = FONT_FAMILY,
    color  = "grey40"
  )+
  scale_fill_manual(values = group_colors) +
  scale_color_manual(values = group_colors) +
  scale_alpha_manual(values = alpha_values) +
  scale_y_continuous(
    breaks = Y_BREAKS,
    labels = function(x) sprintf("%.1f", x)
  ) +
  labs(x = NULL, y = "Mean sentiment score") +
  theme_figure_b2()

figure_b2_raincloud$coordinates$clip <- "off"

# ==============================================================================
# EXPORT
# ==============================================================================

save_device <- tryCatch({
  grDevices::cairo_pdf(tempfile())
  grDevices::dev.off()
  grDevices::cairo_pdf
}, error = function(e) "pdf", warning = function(w) "pdf")

ggsave(
  filename = "fig_b2_raincloud.pdf",
  plot     = figure_b2_raincloud,
  width    = FIG_WIDTH,
  height   = FIG_HEIGHT,
  device   = save_device
)

ggsave(
  filename = "fig_b2_raincloud.svg",
  plot     = figure_b2_raincloud,
  width    = FIG_WIDTH,
  height   = FIG_HEIGHT,
  device   = "svg",
  units    = "in"
)

ggsave(
  filename = "fig_b2_raincloud.png",
  plot     = figure_b2_raincloud,
  width    = FIG_WIDTH,
  height   = FIG_HEIGHT,
  units    = "in",
  dpi      = 400,
  bg       = "white"
)
