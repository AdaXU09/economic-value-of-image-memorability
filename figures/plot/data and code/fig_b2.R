################################################################################
# Figure B2: Sentiment Score Distribution
#
# Last updated: 2026-01-26
################################################################################

# ==============================================================================
# PACKAGES & ENVIRONMENT
# ==============================================================================

package_list <- c("tidyverse", "readxl", "lemon", "gridExtra", "grid", "scales")

# Function to install missing packages and load dependencies
load_packages <- function(pkgs) {
  new_pkgs <- pkgs[!(pkgs %in% installed.packages()[, "Package"])]
  if (length(new_pkgs)) install.packages(new_pkgs)
  invisible(lapply(pkgs, library, character.only = TRUE))
}
load_packages(package_list)

# Set working directory to source file location (RStudio support)
if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
  setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
}

# ==============================================================================
# GLOBAL PARAMETERS
# ==============================================================================

# Typography
FONT_FAMILY    <- "sans"
FONT_SIZE_PT   <- 14
FONT_SIZE_GEOM <- FONT_SIZE_PT / .pt 

# Geometry
LINE_SIZE      <- 0.25
TICK_LENGTH_PT <- 5

# Colors
group_colors <- c(
  "All businesses" = "#D55E00", 
  "Restaurants"    = "#0072B2", 
  "Drinks"         = "#009E73"   
)

# Alpha transparency for review groups
alpha_values <- c(
  "Established" = 0.75,
  "Emerging"    = 0.45
)

# Axes
X_LIM    <- c(0.8, 4.3)
Y_LIM    <- c(-1, 1)
Y_BREAKS <- c(-1, -0.5, 0, 0.5, 1)

# Output Dimensions
FIG_WIDTH  <- 10.5
FIG_HEIGHT <- 6.0 

# ==============================================================================
# SHARED THEME
# ==============================================================================

theme_figure_b2 <- function() {
  list(
    theme_classic(base_size = FONT_SIZE_PT),
    theme(
      text              = element_text(size = FONT_SIZE_PT, family = FONT_FAMILY),
      axis.ticks.length = unit(TICK_LENGTH_PT, "pt"),
      axis.ticks        = element_line(colour = "black", linewidth = LINE_SIZE),
      axis.text         = element_text(size = FONT_SIZE_PT, colour = "black"),
      axis.line         = element_line(colour = "black", linewidth = LINE_SIZE),
      axis.title        = element_text(size = FONT_SIZE_PT, colour = "black"),
      legend.position   = "none",
      
      # Hide standard X axis elements (labels and ticks are handled via manual annotation)
      axis.ticks.x      = element_blank(),
      axis.text.x       = element_blank(),
      axis.line.x       = element_line(colour = NA),
      axis.title.x      = element_blank(),
      
      # Margins
      plot.margin       = margin(t = 6, r = 6, b = 25, l = 6, unit = "pt")
    ),
    coord_capped_cart(
      bottom = capped_horizontal(),
      left   = capped_vertical(capped = "both"),
      xlim   = X_LIM,
      ylim   = Y_LIM
      # Note: clip = "off" is handled manually on the plot object later
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
data_raw2 <- readr::read_csv(file_res, show_col_types = FALSE)
data_raw3 <- readr::read_csv(file_drink, show_col_types = FALSE)

# Clean specific column if it exists to avoid conflicts
if ("person_total_count_review_high" %in% names(data_raw3)) {
  data_raw3 <- data_raw3[, setdiff(names(data_raw3), "person_total_count_review_high")]
}

# Assign group labels
data_raw1$group <- "All businesses"
data_raw2$group <- "Restaurants"
data_raw3$group <- "Drinks"

# Combine and relabel review groups
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

# Define manual x-axis positions for the violin plots
x_positions  <- c(1, 1.5,  2.4, 2.9,  3.8, 4.3)
x_top_labels <- c(1.25, 2.65, 4.05)

# Map groups to x-positions
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
# SUMMARY STATS (UPDATED LABELS)
# ==============================================================================

# Calculate stats and create formatted labels for the plot
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
    # 1. Stats Label (Inside plot): Shows Mean (M) and Standard Deviation (SD)
    stats_label = paste0(
      "M = ", sprintf("%.2f", Mean), "\n",
      "SD = ", sprintf("%.2f", SD)
    ),
    # 2. X-Axis Label (Below plot): Shows Category + Count (n)
    xaxis_label = paste0(
      review_group, "\n",
      "(n = ", scales::comma(N), ")"
    )
  )

# ==============================================================================
# FIGURE B2
# ==============================================================================

# Layout locations (y-coordinates)
y_xlabels   <- -1.05  # Position for X-axis labels (below axis)
y_stats     <- -0.90  # Position for M/SD stats (inside bottom of plot)

figure_b2 <- ggplot(
  data_combined,
  aes(
    x     = x_pos,
    y     = contents_score_avg,
    fill  = group,
    alpha = review_group,
    group = interaction(group, review_group)
  )
) +
  # Violin Plot
  geom_violin(
    trim      = TRUE,
    width     = 0.45,
    color     = "black",
    linewidth = LINE_SIZE
  ) +
  # Boxplot (nested inside violin)
  geom_boxplot(
    width         = 0.12,
    fill          = "white",
    color         = "black",
    linewidth     = LINE_SIZE,
    outlier.shape = NA,
    alpha         = 1
  ) +
  # Mean point (black dot with white border)
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
  # Annotation: "Neutral" text label
  annotate(
    "text",
    x      = 1.8,
    y      = 0.05,
    label  = "Neutral",
    hjust  = 0,
    vjust  = 0,
    size   = FONT_SIZE_GEOM,
    family = FONT_FAMILY,
    color  = "grey40"
  ) +
  # Annotation: Statistics Labels (M/SD)
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
  # Scales and Theme
  scale_fill_manual(values = group_colors) +
  scale_alpha_manual(values = alpha_values) +
  scale_y_continuous(
    breaks = Y_BREAKS,
    labels = function(x) sprintf("%.1f", x)
  ) +
  labs(x = NULL, y = "Mean sentiment score") +
  theme_figure_b2() +
  
  # Annotation: Top titles (Group headings)
  annotate(
    "text",
    x      = x_top_labels,
    y      = 1.03,
    label  = c("All businesses", "Restaurants", "Drinks"),
    hjust  = 0.5,
    vjust  = 0,
    size   = FONT_SIZE_GEOM,
    family = FONT_FAMILY
  ) +
  # Annotation: Bottom Labels (Category + n)
  annotate(
    "text",
    x              = stats_table$x_pos,    
    y              = y_xlabels,
    label          = stats_table$xaxis_label, 
    hjust          = 0.5,
    vjust          = 1,
    size           = FONT_SIZE_GEOM,
    family         = FONT_FAMILY,
    lineheight = 1.1                    
  )

# Turn off clipping to allow text annotations outside plot area
figure_b2$coordinates$clip <- "off"

# ==============================================================================
# EXPORT
# ==============================================================================

# Determine the best available PDF device
save_device <- tryCatch({
  grDevices::cairo_pdf(tempfile())
  grDevices::dev.off()
  grDevices::cairo_pdf
}, error = function(e) "pdf", warning = function(w) "pdf")

ggsave(
  filename = "fig_b2.pdf",
  plot     = figure_b2,
  width    = FIG_WIDTH,
  height   = FIG_HEIGHT,
  device   = save_device
)

ggsave(
  filename = "fig_b2.svg",
  plot     = figure_b2,
  width    = FIG_WIDTH,
  height   = FIG_HEIGHT,
  device   = "svg",
  units    = "in"
)

ggsave(
  filename = file.path("fig_b2.png"),
  plot     = figure_b2,
  width    = FIG_WIDTH,
  height   = FIG_HEIGHT,
  units    = "in",
  dpi      = 400,
  bg       = "white"
)