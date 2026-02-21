################################################################################
# Figure 2 — Average Image Memorability by Topic (Bubble plot)
#
# Last updated: 2026-01-26
################################################################################

# ==============================================================================
# PACKAGES & ENVIRONMENT
# ==============================================================================

package_list <- c("tidyverse", "readxl", "lemon", "svglite")

# Function to install missing packages and load dependencies
load_packages <- function(pkgs) {
  new_pkgs <- pkgs[!(pkgs %in% installed.packages()[, "Package"])]
  if (length(new_pkgs)) install.packages(new_pkgs)
  invisible(lapply(pkgs, library, character.only = TRUE))
}
load_packages(package_list)

# ------------------------------------------------------------------------------
# WORKING DIRECTORY
# ------------------------------------------------------------------------------
get_script_dir <- function() {
  # 1. Detect RStudio environment
  if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
    p <- rstudioapi::getActiveDocumentContext()$path
    if (!is.null(p) && nzchar(p)) return(dirname(p))
  }
  # 2. Detect Rscript execution (command line)
  cmd <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", cmd, value = TRUE)
  if (length(file_arg) > 0) {
    p <- sub("^--file=", "", file_arg[1])
    if (nzchar(p)) return(dirname(normalizePath(p, mustWork = FALSE)))
  }
  # 3. Fallback to current working directory
  getwd()
}

SCRIPT_DIR <- get_script_dir()
setwd(SCRIPT_DIR)

# ==============================================================================
# GLOBAL PARAMETERS
# ==============================================================================

# Typography
FONT_FAMILY    <- "sans"
FONT_SIZE_PT   <- 14
FONT_SIZE_GEOM <- FONT_SIZE_PT / .pt

# Geometry
LINE_WIDTH     <- 0.25
TICK_LENGTH_PT <- 5
DODGE_WIDTH    <- 0.60

BUBBLE_ALPHA   <- 0.70
BUBBLE_MAXSIZE <- 15

# Color palette
COL_GROUP <- c(
  "All businesses" = "#D55E00",  # Vermilion
  "Restaurants"    = "#0072B2",  # Strong Blue
  "Drinks"         = "#009E73"   # Bluish Green
)

COL_GROUP_LIGHT <- c(
  "All businesses" = "#F4C29F",
  "Restaurants"    = "#99C6E0",
  "Drinks"         = "#99D8C5"
)

# Axis
Y_LIMITS <- c(0.5, 1)
Y_BREAKS <- seq(0.5, 1, 0.10)

# I/O
FIG_WIDTH  <- 10*0.8
FIG_HEIGHT <- 6*0.8
OUTPUT_DIR <- "."  # same folder as this script
INPUT_DIR  <- "."  # same folder as this script

# ==============================================================================
# SHARED THEME
# ==============================================================================

theme_figure2 <- function() {
  list(
    theme_classic(base_size = FONT_SIZE_PT),
    theme(
      text              = element_text(size = FONT_SIZE_PT, family = FONT_FAMILY),
      axis.ticks.length = unit(TICK_LENGTH_PT, "pt"),
      axis.ticks        = element_line(colour = "black", linewidth = LINE_WIDTH),
      axis.text         = element_text(size = FONT_SIZE_PT, colour = "black"),
      axis.text.x       = element_text(size = FONT_SIZE_PT, margin = margin(t = 8, unit = "pt")),
      axis.text.y       = element_text(size = FONT_SIZE_PT, margin = margin(r = 8, unit = "pt")),
      axis.line         = element_line(colour = "black", linewidth = LINE_WIDTH),
      axis.title        = element_text(size = FONT_SIZE_PT, colour = "black"),
      axis.title.x      = element_text(size = FONT_SIZE_PT, margin = margin(t = 3, unit = "pt")),
      axis.title.y      = element_text(size = FONT_SIZE_PT, margin = margin(r = 5, unit = "pt")),
      legend.position   = c(0.985, 1.00),
      legend.justification = c("right", "top"),
      legend.text       = element_text(size = FONT_SIZE_PT),
      legend.title      = element_text(size = FONT_SIZE_PT),
      legend.background = element_blank(),
      legend.key        = element_blank(),
      plot.title        = element_text(size = FONT_SIZE_PT, face = "bold", hjust = 0.5),
      plot.caption      = element_text(size = FONT_SIZE_PT),
      plot.tag          = element_text(size = FONT_SIZE_PT, face = "bold"),
      plot.margin       = margin(t = 10, r = 15, b = 1, l = 10, unit = "pt")
    ),
    coord_capped_cart(
      bottom = capped_horizontal(),
      left   = capped_vertical(capped = "both")
    )
  )
}

# ==============================================================================
# DATA IMPORT
# ==============================================================================
data_path <- file.path(INPUT_DIR, "bubble_plot_data.csv")
bubble_data <- readr::read_csv(data_path, show_col_types = FALSE)

bubble_data <- bubble_data %>%
  mutate(
    group = factor(group, levels = c("All businesses", "Restaurants", "Drinks")),
    topic = factor(
      label,
      levels = c("drink", "food", "inside", "menu", "outside"),
      labels = c("Drink", "Food", "Inside", "Menu", "Outside")
    ),
    pct_label   = sprintf("%.1f%%", percentage),
    bubble_size = percentage,
    
    # LABEL POSITIONING LOGIC (vjust):
    # Adjust vertical alignment to prevent overlap with bubbles.
    # Note: "Food" and "Inside" topics require wider spacing due to larger bubbles/positioning.
    #
    # 1. Restaurants (Labels placed below bubble):
    #    - "Food"/"Inside": vjust = 4.0
    #    - Others:          vjust = 2.5 (Standard)
    #
    # 2. All other groups (Labels placed above bubble):
    #    - "Food"/"Inside": vjust = -2.8
    #    - Others:          vjust = -1.5 (Standard)
    vjust_val = case_when(
      topic %in% c("Food", "Inside") & group == "Restaurants" ~ 4.0,
      topic %in% c("Food", "Inside")                          ~ -2.8,
      group == "Restaurants"                                  ~ 2.2,
      TRUE                                                    ~ -1.5
    ),
    # 0.5 = Centered
    # 0.2 = Moves text Right (shifts the anchor to the left side of the text)
    hjust_val = case_when(
      group %in% c("Restaurants", "Drinks") ~ 0.4, 
      TRUE                                  ~ 0.5
    )
  )

# ==============================================================================
# PLOT
# ==============================================================================

pos <- position_dodge(width = DODGE_WIDTH)

Figure2 <- ggplot(bubble_data, aes(x = topic, y = memory_score, colour = group, fill = group)) +
  geom_errorbar(
    aes(ymin = ci_lower, ymax = ci_upper),
    position  = pos,
    width     = 0,
    linewidth = LINE_WIDTH
  ) +
  geom_point(
    aes(size = bubble_size),
    position = pos,
    alpha    = BUBBLE_ALPHA,
    shape    = 21,          # <--- Critical: Allows separate fill & stroke
    stroke   = 0.25          # <--- Optional: Makes the border slightly thicker/visible
  ) +
  geom_text(
    aes(
      label = pct_label, 
      vjust = vjust_val,
      hjust = hjust_val,
      group = group
    ),
    position  = pos,
    size      = FONT_SIZE_GEOM,
    colour    = "black"
  ) +
  scale_colour_manual(values = COL_GROUP) +       # Borders & Error Bars (Dark)
  scale_fill_manual(values = COL_GROUP_LIGHT) +   # Bubble Fills (Light)
  
  scale_size_continuous(range = c(3, BUBBLE_MAXSIZE), guide = "none") +
  scale_y_continuous(limits = Y_LIMITS, breaks = Y_BREAKS, expand = expansion(add = c(0, 0))) +
  labs(x = "Image topic", y = "Mean memory score", colour = NULL, fill = NULL) +
  guides(
    colour = guide_legend(override.aes = list(shape = 21, size = 5, fill = COL_GROUP_LIGHT, color = COL_GROUP, stroke = 0.25, linetype = 0)),
    fill   = guide_legend(override.aes = list(shape = 21, size = 5, fill = COL_GROUP_LIGHT, color = COL_GROUP, stroke = 0.25, linetype = 0))
  ) +
  theme_figure2()

Figure2

# ==============================================================================
# EXPORT (PDF + SVG + PNG)
# ==============================================================================

# Determine the best available PDF device
# Tries to use cairo_pdf for better font handling; falls back to standard "pdf" if unavailable.
save_device <- tryCatch(
  {
    cairo_pdf(tempfile())
    dev.off()
    cairo_pdf
  },
  error = function(e) "pdf",
  warning = function(w) "pdf"
)

ggsave(
  filename = file.path(OUTPUT_DIR, "fig2.pdf"),
  plot     = Figure2,
  width    = FIG_WIDTH,
  height   = FIG_HEIGHT,
  device   = save_device
)

ggsave(
  filename = file.path(OUTPUT_DIR, "fig2.svg"),
  plot     = Figure2,
  device   = "svg",
  width    = FIG_WIDTH,
  height   = FIG_HEIGHT,
  units    = "in"
)

ggsave(
  filename = file.path(OUTPUT_DIR, "fig2.png"),
  plot     = Figure2,
  width    = FIG_WIDTH,
  height   = FIG_HEIGHT,
  units    = "in",
  dpi      = 400,
  bg       = "white"
)