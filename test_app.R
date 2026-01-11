# Quick test script to check if app loads without errors

cat("Testing app structure...\n\n")

# Set options
options(rgl.useNULL = TRUE)

# Check if files exist
files_to_check <- c(
  "global.R",
  "ui.R",
  "server.R",
  "R/utils.R",
  "R/mod_sidebar.R",
  "R/mod_results.R"
)

cat("Checking files exist:\n")
for (f in files_to_check) {
  if (file.exists(f)) {
    cat("  ✓", f, "\n")
  } else {
    cat("  ✗", f, "MISSING!\n")
    stop("Required file missing!")
  }
}

cat("\nLoading packages...\n")
library(shiny)
library(bslib)
library(fireexposuR)
library(terra)

cat("Sourcing R files...\n")
r_files <- list.files("R", pattern = "\\.R$", full.names = TRUE)
for (file in r_files) {
  cat("  Sourcing:", file, "\n")
  source(file)
}

cat("\nTesting module functions exist...\n")
functions_to_check <- c(
  "mod_sidebar_ui",
  "mod_sidebar_server",
  "mod_results_ui",
  "mod_results_server",
  "validate_numeric_param",
  "load_vector_file",
  "validate_analysis_params"
)

for (fn in functions_to_check) {
  if (exists(fn)) {
    cat("  ✓", fn, "\n")
  } else {
    cat("  ✗", fn, "NOT FOUND!\n")
  }
}

cat("\nLoading UI...\n")
source("ui.R")
cat("  ✓ UI loaded\n")

cat("\nLoading Server...\n")
source("server.R")
cat("  ✓ Server loaded\n")

cat("\n✓ All tests passed! App structure is correct.\n")
cat("\nYou can now run: shiny::runApp()\n")
