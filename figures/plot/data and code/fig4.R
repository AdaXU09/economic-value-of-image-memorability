################################################################################
# Figure 4: Predicted Average Rating by Image Memorability and Business Visibility
#
# Last updated: 2026-01-26
################################################################################

# =============================================================================
# 1. PACKAGES & SETUP
# =============================================================================

# Function to install missing packages and load dependencies
load_packages <- function(pkgs) {
  new_pkgs <- pkgs[!(pkgs %in% installed.packages()[, "Package"])]
  if (length(new_pkgs)) install.packages(new_pkgs)
  invisible(lapply(pkgs, library, character.only = TRUE))
}

package_list <- c("tidyverse", "readr", "grid", "gridExtra", "gtable")
load_packages(package_list)

# Set working directory to source location (RStudio support)
if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
  setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
}

# =============================================================================
# 2. GLOBAL PARAMETERS (House Style)
# =============================================================================

# Typography
FONT_FAMILY    <- "sans"
FONT_SIZE_PT   <- 14
FONT_SIZE_GEOM <- FONT_SIZE_PT / .pt

# Geometry
LINE_WIDTH     <- 0.25
TICK_LENGTH    <- unit(0.25, "cm")

# Colors
COLOR_HIGH_VIS <- "#4E79A7" 
COLOR_LOW_VIS  <- "#767676" 

PALETTE_VIS    <- c("Established (high visibility)" = COLOR_HIGH_VIS, 
                    "Emerging (low visibility)" = COLOR_LOW_VIS)

# Line types mapping
LINE_PALETTE   <- c("Established (high visibility)" = "solid", 
                    "Emerging (low visibility)" = "dashed")

# Axes
Y_LIMITS       <- c(2, 5)
Y_BREAKS       <- seq(2, 5, by = 1)

X_LIMITS       <- c(0.6, 0.9)
X_BREAKS       <- seq(0.6, 0.9, by = 0.1)

# =============================================================================
# 3. THEME DEFINITION
# =============================================================================

theme_house_style <- function() {
  theme_classic(base_size = FONT_SIZE_PT, base_family = FONT_FAMILY) +
    theme(
      text = element_text(color = "black"),
      axis.title = element_text(face = "plain"),
      axis.text = element_text(color = "black"),
      plot.title = element_text(size = FONT_SIZE_PT, face = "plain", hjust = 0.5),
      
      # House style lines
      axis.line = element_line(color = "black", linewidth = LINE_WIDTH),
      axis.ticks = element_line(color = "black", linewidth = LINE_WIDTH),
      axis.ticks.length = TICK_LENGTH,
      
      # Clean Layout
      panel.grid = element_blank(),
      legend.background = element_blank(),
      legend.key = element_blank(),
      plot.margin = margin(t = 10, r = 10, b = 10, l = 10, unit = "pt")
    )
}

# =============================================================================
# 4. DATA LOADING & PROCESSING
# =============================================================================

# NOTE: Ensure your CSV file is in the working directory
df <- read_csv("plot_data_moderation_all.csv", show_col_types = FALSE)

# Ensure Factor Levels are correct for legend ordering
df$status <- factor(df$status, levels = c("Established (high visibility)", "Emerging (low visibility)"))

# Split data into subsets for the three panels
df_all  <- df %>% filter(sample == "All businesses")
df_rest <- df %>% filter(sample == "Restaurants")
df_drnk <- df %>% filter(sample == "Drinks")

# =============================================================================
# 5. PLOTTING FUNCTIONS
# =============================================================================

create_base_plot <- function(data, title_text, show_y_axis = TRUE, show_legend = FALSE) {
  
  # 1. Global aes definition (includes linetype for dashed/solid distinction)
  p <- ggplot(data, aes(x = memory_score, y = pred, color = status, fill = status, linetype = status)) +
    
    # 2. Confidence Interval Ribbons
    # show.legend = FALSE prevents the gray box from appearing in the final legend key
    geom_ribbon(aes(ymin = ci_low, ymax = ci_high), 
                alpha = 0.15, 
                color = NA, 
                linetype = "solid", 
                show.legend = FALSE) + 
    
    # Main Line
    geom_line(linewidth = 0.5) +
    
    # Scales
    scale_color_manual(values = PALETTE_VIS) +
    scale_fill_manual(values = PALETTE_VIS) +
    scale_linetype_manual(values = LINE_PALETTE) + 
    
    # Axes
    scale_x_continuous(breaks = X_BREAKS, labels = scales::number_format(accuracy = 0.1), expand = c(0, 0)) +
    scale_y_continuous(breaks = Y_BREAKS, expand = c(0, 0)) +
    
    # Coord (Clip on to allow points/lines to touch edge)
    coord_cartesian(ylim = Y_LIMITS, xlim = X_LIMITS, clip = "on") +
    
    # Labels
    labs(title = title_text, x = "Image memorability", y = "Predicted average rating") +
    
    # Theme application
    theme_house_style()+
    
    # Legend aesthetics adjustment
    # Override linewidth to 0.5 to ensure legend lines are thin and crisp
    guides(
      color    = guide_legend(override.aes = list(linewidth = 0.5)),
      fill     = guide_legend(override.aes = list(linewidth = 0.5)),
      linetype = guide_legend(override.aes = list(linewidth = 0.5))
    )
  
  # Conditional Y-Axis Removal (for middle and right plots)
  if (!show_y_axis) {
    p <- p + theme(
      axis.title.y = element_blank(),
      axis.text.y = element_blank(),
      axis.ticks.y = element_blank(),
      axis.line.y = element_blank()
    )
  }
  
  # Conditional Legend Placement (Center plot only)
  if (show_legend) {
    p <- p + theme(
      legend.position = c(0.5, 0.22),
      legend.title = element_blank(),
      legend.text = element_text(size = FONT_SIZE_PT),
      legend.key.height = unit(0.8, "cm"),
      legend.key.width = unit(1.5, "cm") # Ensure width is enough to see the dash
    )
  } else {
    p <- p + theme(legend.position = "none")
  }
  
  return(p)
}

# =============================================================================
# 6. GENERATE PLOTS
# =============================================================================

# Plot 1: All Businesses
# Note: x = " " is used instead of NULL to reserve vertical space for the label, 
# ensuring the plot area aligns perfectly with the middle plot (which has a label).
p1 <- create_base_plot(df_all, "All businesses", show_y_axis = TRUE, show_legend = FALSE) +
  labs(x = " ")

# Plot 2: Restaurants
# This plot contains the X-axis label and the Legend
p2 <- create_base_plot(df_rest, "Restaurants", show_y_axis = FALSE, show_legend = TRUE) +
  labs(x = "Image memorability") +
  theme(
    legend.position = c(0.5, 0.15),
    legend.direction = "vertical",
    legend.spacing.y = unit(0, "pt")
  )

# Plot 3: Drinks
# Note: x = " " reserves vertical space to match p2
p3 <- create_base_plot(df_drnk, "Drinks", show_y_axis = FALSE, show_legend = FALSE) +
  labs(x = " ")

# =============================================================================
# 7. COMBINE & EXPORT
# =============================================================================

# Arrange in 1 row, 3 columns
# Widths are adjusted (1.13 vs 1) to account for the Y-axis labels on the first plot
p_combined <- grid.arrange(p1, p2, p3, nrow = 1, widths = c(1.13, 1, 1))

# Save Dimensions
FIG_WIDTH  <- 10
FIG_HEIGHT <- 5

# Determine the best available PDF device
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
  filename = file.path("fig4.pdf"),
  plot     = p_combined,
  width    = FIG_WIDTH,
  height   = FIG_HEIGHT,
  device   = save_device
)

ggsave(
  filename = file.path("fig4.svg"),
  plot     = p_combined,
  device   = "svg",
  width    = FIG_WIDTH,
  height   = FIG_HEIGHT,
  units    = "in"
)

ggsave(
  filename = file.path("fig4.png"),
  plot     = p_combined,
  width    = FIG_WIDTH,
  height   = FIG_HEIGHT,
  units    = "in",
  dpi      = 400,
  bg       = "white"
)