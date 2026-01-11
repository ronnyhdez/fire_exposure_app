# Startup script for Fire Exposure Assessment Shiny App
# This script sets necessary options and launches the modular app

# Print startup message
cat("\n")
cat("==================================================\n")
cat("  Fire Exposure Assessment Tool\n")
cat("  Powered by fireexposuR\n")
cat("  (Modular Architecture)\n")
cat("==================================================\n")
cat("\n")

# Check if required packages are installed
required_packages <- c("shiny", "bslib", "fireexposuR", "terra")
missing_packages <- required_packages[!required_packages %in% installed.packages()[,1]]

if(length(missing_packages) > 0) {
  cat("ERROR: Missing required packages:\n")
  cat(paste("  -", missing_packages, collapse = "\n"))
  cat("\n\nPlease install missing packages:\n")
  cat(paste0("  install.packages(c('", paste(missing_packages, collapse = "', '"), "'))\n"))
  stop("Missing required packages")
}

cat("Starting modular Shiny app...\n")
cat("\n")
cat("App structure:\n")
cat("  - global.R: Configuration and package loading\n")
cat("  - ui.R: User interface\n")
cat("  - server.R: Server logic\n")
cat("  - R/mod_sidebar.R: Sidebar module\n")
cat("  - R/mod_results.R: Results module\n")
cat("  - R/utils.R: Utility functions\n")
cat("\n")

# Launch the app
shiny::runApp(
  appDir = ".",
  launch.browser = TRUE,
  quiet = FALSE
)
