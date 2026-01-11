# Helper script to extract example data from fireexposuR package
# Run this script to get test data for the Shiny app

library(terra)
library(fireexposuR)

cat("Extracting example data from fireexposuR package...\n")

# Create example_data directory if it doesn't exist
if (!dir.exists("example_data")) {
  dir.create("example_data")
}

# Get example hazard raster
hazard_path <- system.file("extdata/hazard.tif", package = "fireexposuR")
if (file.exists(hazard_path)) {
  file.copy(hazard_path, "example_data/hazard.tif", overwrite = TRUE)
  cat("✓ Copied hazard.tif to example_data/\n")
} else {
  cat("✗ Could not find hazard.tif in fireexposuR package\n")
}

# Get example polygon shapefile (need all components)
polygon_dir <- system.file("extdata", package = "fireexposuR")
polygon_files <- list.files(polygon_dir, pattern = "polygon\\.(shp|shx|dbf|prj)$", full.names = TRUE)

if (length(polygon_files) > 0) {
  for (f in polygon_files) {
    file.copy(f, file.path("example_data", basename(f)), overwrite = TRUE)
  }
  cat("✓ Copied polygon shapefile components to example_data/\n")
} else {
  cat("✗ Could not find polygon shapefile in fireexposuR package\n")
}

cat("\nExample data extracted successfully!\n")
cat("\nYou can now upload these files in the Shiny app:\n")
cat("  - Hazard GeoTIFF: example_data/hazard.tif\n")
cat("  - Area of Interest: example_data/polygon.shp\n")
