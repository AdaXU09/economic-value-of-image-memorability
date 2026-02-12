################################################################################
# Figure B1
# Distribution of review counts + ECDF (log10)
#
# Last updated: 2026-01-26
################################################################################

# ==============================================================================
# PACKAGES & ENVIRONMENT
# ==============================================================================

package_list <- c(
  "tidyverse",   # ggplot2, dplyr, tidyr, etc.
  "readxl",      # read_excel()
  "lemon",       # coord_capped_cart()
  "gridExtra",   # arrangeGrob()
  "grid",        # textGrob()
  "svglite"      # reliable SVG device for ggsave(device = "svg")
)

# Function to install missing packages and load dependencies
load_packages <- function(pkgs) {
  new_pkgs <- pkgs[!(pkgs %in% installed.packages()[, "Package"])]
  if (length(new_pkgs)) install.packages(new_pkgs)
  invisible(lapply(pkgs, library, character.only = TRUE))
}
load_packages(package_list)

# Set working directory to the folder containing this script (RStudio).
# If you're not using RStudio, just run the script from the folder where the
# data files are located.
if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
  setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
}

# ==============================================================================
# GLOBAL PARAMETERS (HOUSE STYLE)
# ==============================================================================

# Typography
FONT_FAMILY    <- "sans"
FONT_SIZE_PT   <- 14
FONT_SIZE_GEOM <- FONT_SIZE_PT / .pt

# Lines / strokes
LINE_SIZE      <- 0.25
TICK_LENGTH_PT <- 5

# Output size (inches)
FIG_WIDTH  <- 14
FIG_HEIGHT <- 7

# Palette (match reference figure)
COL_GROUP <- c(
  "All businesses" = "#D55E00",  # Vermilion
  "Restaurants"    = "#0072B2",  # Strong Blue
  "Drinks"         = "#009E73"   # Bluish Green
)

# Histogram bins
BIN_BREAKS <- c(0, 50, 100, 150, 200, 300, 400, 500, Inf)
BIN_LABELS <- c("1-50", "51-100", "101-150", "151-200",
                "201-300", "301-400", "401-500", ">500")

# Panel A y-limit (proportions)
Y_MAX_A <- 0.55

# ==============================================================================
# SHARED THEME
# ==============================================================================

theme_b1 <- function() {
  list(
    theme_classic(base_size = FONT_SIZE_PT),
    theme(
      text              = element_text(size = FONT_SIZE_PT, family = FONT_FAMILY),
      axis.ticks.length = unit(TICK_LENGTH_PT, "pt"),
      axis.ticks        = element_line(colour = "black", linewidth = LINE_SIZE),
      axis.text         = element_text(size = FONT_SIZE_PT, colour = "black"),
      axis.line         = element_line(colour = "black", linewidth = LINE_SIZE),
      axis.title        = element_text(size = FONT_SIZE_PT),
      
      # Plot title adjustment: Force size to match FONT_SIZE_PT
      plot.title        = element_text(size = FONT_SIZE_PT, hjust = 0, vjust = 0.5, face = "plain"),
      
      legend.text       = element_text(size = FONT_SIZE_PT),
      legend.title      = element_blank(),
      strip.text        = element_text(size = FONT_SIZE_PT),
      strip.background  = element_blank(),
      plot.margin       = margin(5, 25, 5, 5, "pt")
    ),
    coord_capped_cart(
      bottom = capped_horizontal(),
      left   = capped_vertical(capped = "both")
    )
  )
}

pct_label <- function(p) paste0(round(100 * p), "%")

# ==============================================================================
# DATA IMPORT (FILES IN THE SAME FOLDER)
# ==============================================================================

file_business <- "study1_2_business_data.csv"
file_res      <- "study1_2_res_data.csv"
file_drink    <- "study1_2_drink_data.csv"

data_business <- readr::read_csv(file_business, show_col_types = FALSE)
data_res      <- readr::read_csv(file_res, show_col_types = FALSE)
data_drink    <- readr::read_csv(file_drink, show_col_types = FALSE)

data_business$group <- "All businesses"
data_res$group      <- "Restaurants"
data_drink$group    <- "Drinks"

data_all <- bind_rows(data_business, data_res, data_drink) %>%
  mutate(
    group = factor(group, levels = c("All businesses", "Restaurants", "Drinks")),
    review_count = as.numeric(review_count)
  ) %>%
  filter(!is.na(review_count) & review_count > 0)

# 67th percentile (top tertile threshold) computed on ALL businesses
threshold_tertile <- as.numeric(quantile(data_business$review_count, probs = 2/3, na.rm = TRUE))

# ==============================================================================
# PANEL A: DISTRIBUTION (FACETED FOR STANDARDIZED HEIGHTS)
# ==============================================================================

# Helper to bin data manually for custom histograms
make_bin_df <- function(df) {
  df %>%
    mutate(bin = cut(review_count,
                     breaks = BIN_BREAKS,
                     labels = BIN_LABELS,
                     include.lowest = TRUE,
                     right = TRUE)) %>%
    count(bin, name = "n") %>%
    mutate(
      bin = factor(bin, levels = BIN_LABELS),
      pct = n / sum(n),
      label = pct_label(pct)
    )
}

# 1. Pre-calculate bins for each group
d_panel_a <- bind_rows(
  make_bin_df(data_business) %>% mutate(group = "All businesses"),
  make_bin_df(data_res)      %>% mutate(group = "Restaurants"),
  make_bin_df(data_drink)    %>% mutate(group = "Drinks")
) %>%
  mutate(group = factor(group, levels = names(COL_GROUP)))

# 2. Create label data for custom "Upper Right" placement
#    We place x near the middle/end (4.5 or 8) and y at the max height (Y_MAX_A).
panel_a_labels <- d_panel_a %>%
  select(group) %>%
  distinct()

# 3. Create the plot
panel_a <- ggplot(d_panel_a, aes(x = bin, y = pct, fill = group)) +
  geom_col(width = 1, colour = "black", linewidth = LINE_SIZE) +
  
  # Percentage labels above bars
  geom_text(
    aes(label = label),
    vjust = -0.4,
    size  = FONT_SIZE_GEOM,
    family = FONT_FAMILY,
    colour = "black"
  ) +
  
  # Custom Group Labels (Upper Right inside panel)
  # Instead of using facet strips, we place text manually inside the plot.
  geom_text(
    data    = panel_a_labels,
    aes(label = group, x = 4.5, y = Y_MAX_A * 0.85), # x=4.5 centers it roughly in the right half
    hjust   = 0.5,      
    vjust   = 1,      
    size    = FONT_SIZE_GEOM,
    family  = FONT_FAMILY,
    fontface = "plain",
    colour  = "black"
  ) +
  
  scale_y_continuous(limits = c(0, Y_MAX_A), expand = c(0, 0)) +
  scale_fill_manual(values = COL_GROUP) +
  labs(
    title = "a. Distribution of review counts",
    x = "Review count", 
    y = NULL
  ) +
  
  # Stack panels vertically
  facet_wrap(~group, ncol = 1) + 
  
  theme_b1() +
  theme(
    # --- REMOVE DEFAULT FACET STRIPS ---
    strip.background = element_blank(),
    strip.text       = element_blank(), # This hides the default labels
    
    # --- LAYOUT ---
    panel.spacing = unit(10, "pt"),
    
    # --- AXIS CLEANUP ---
    axis.text.y  = element_blank(),
    axis.ticks.y = element_blank(),
    axis.line.y  = element_line(colour = NA),
    axis.title.y = element_blank(),
    
    # --- TEXT ROTATION ---
    axis.text.x  = element_text(angle = 45, hjust = 1, vjust = 1, margin = margin(t = 5)),
    axis.title.x = element_text(margin = margin(t = 15)),
    
    legend.position = "none"
  )

# ==============================================================================
# PANEL B: ECDF (LOG10 X)
# ==============================================================================

P_B <- ggplot(data_all, aes(x = review_count, colour = group)) +
  
  # 1. Log ticks annotation
  # Note: Use 'linewidth' instead of 'size' for newer ggplot2 compatibility
  annotation_logticks(
    sides     = "b", 
    outside   = TRUE,
    linewidth = LINE_SIZE, 
    colour    = "black",
    short     = unit(3, "pt"), 
    mid       = unit(5, "pt"),
    long      = unit(0, "pt")  # Suppress long ticks (handled by axis breaks)
  ) +
  
  stat_ecdf(linewidth = 0.6) +
  scale_colour_manual(values = COL_GROUP) +
  scale_x_log10(
    breaks = c(1, 10, 100, 1000, 10000),
    labels = c("1", "10", "100", "1,000", "10,000"), 
    limits = c(1, 10000),
    expand = c(0, 0)
  ) +
  scale_y_continuous(
    breaks = c(0, 0.25, 0.50, 0.75, 1.00),
    labels = c("0.00", "0.25", "0.50", "0.75", "1.00"),
    limits = c(0, 1),
    expand = c(0, 0)
  ) +
  
  # Reference lines for tertile cutoffs
  geom_hline(yintercept = 2/3, linetype = "dashed", colour = "gray60", linewidth = LINE_SIZE) +
  geom_vline(xintercept = threshold_tertile, linetype = "dashed", colour = "gray60", linewidth = LINE_SIZE) +
  
  # Annotations for reference lines
  annotate(
    "text", x = 600, y = 0.70, label = "67th percentile cutoff",
    hjust = 0, family = FONT_FAMILY, size = FONT_SIZE_GEOM, colour = "black"
  ) +
  annotate(
    "text", x = 3.5, y = 0.95, label = paste0("Top tertile: >", threshold_tertile, " reviews"),
    hjust = 0, family = FONT_FAMILY, size = FONT_SIZE_GEOM, colour = "black"
  ) +
  
  labs(
    title = "b. Empirical cumulative distribution of review counts",
    x = "Review count (log scale)",
    y = "Cumulative probability",
    colour = NULL
  ) +
  
  theme_b1() +
  
  # Coordinate system with capped axes
  # Note: Do NOT set clip = "off" here if using coord_capped_cart; it is handled manually below.
  coord_capped_cart(
    bottom = capped_horizontal(),
    left   = capped_vertical(capped = "both")
  ) +
  
  theme(
    legend.position      = c(0.72, 0.18),
    legend.justification = c(0, 0),
    legend.background    = element_blank(),
    legend.key           = element_blank()
  )

# 2. Manual Clip Adjustment
# Manually force clipping off on the plot object to allow annotations to render near edges.
P_B$coordinates$clip <- "off"

# ==============================================================================
# COMBINE + EXPORT
# ==============================================================================

# Combine plots with a spacer in between
# Using grid::nullGrob() creates a visual gap between Panels A and B.
P_combined <- gridExtra::arrangeGrob(
  grobs  = list(panel_a, grid::nullGrob(), P_B),
  ncol   = 3,              # 3 columns: [Panel A] [Spacer] [Panel B]
  widths = c(1, 0.01, 1.05) 
)

# Export logic: prefer cairo_pdf for font handling
save_device <- tryCatch({
  cairo_pdf(tempfile())
  dev.off()
  cairo_pdf
}, error = function(e) "pdf", warning = function(w) "pdf")

ggsave(
  filename = "fig_b1.pdf",
  plot     = P_combined,
  width    = FIG_WIDTH,
  height   = FIG_HEIGHT,
  units    = "in",
  device   = save_device
)

ggsave(
  filename = "fig_b1.svg",
  plot     = P_combined,
  width    = FIG_WIDTH,
  height   = FIG_HEIGHT,
  units    = "in",
  device   = "svg"
)

ggsave(
  filename = "fig_b1.png",
  plot     = P_combined,
  width    = FIG_WIDTH,
  height   = FIG_HEIGHT,
  units    = "in",
  dpi      = 400,
  bg       = "white"
)