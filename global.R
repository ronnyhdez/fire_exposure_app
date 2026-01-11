# Global configuration for Fire Exposure Assessment Shiny App
# This file is loaded once when the app starts

# ============================================================================
# Package Loading
# ============================================================================

# Suppress rgl warnings/errors if OpenGL is not available
options(rgl.useNULL = TRUE)

# Load required packages
library(shiny)
library(bslib)
library(fireexposuR)
library(terra)

# ============================================================================
# Global Options
# ============================================================================

# Set default options
options(
  shiny.maxRequestSize = 100 * 1024^2  # Max upload size: 100MB
)

# ============================================================================
# Source Module Files
# ============================================================================

# Source all R files in the R/ directory
r_files <- list.files("R", pattern = "\\.R$", full.names = TRUE)
for (file in r_files) {
  source(file)
}
