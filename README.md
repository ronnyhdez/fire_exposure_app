# Fire Exposure Assessment Shiny App

A basic interactive web application for exploring wildfire exposure using the [fireexposuR](https://github.com/ropensci/fireexposuR) R package.

**Architecture:** This app uses a modular Shiny structure for maintainability and scalability. See [ARCHITECTURE.md](ARCHITECTURE.md) for details.

## Overview

This Shiny app provides a user-friendly interface to:
- Upload hazard data (GeoTIFF rasters)
- Configure exposure analysis parameters
- Visualize exposure maps and statistics
- Perform directional vulnerability assessments
- Download results

## Features

### 1. Data Upload
- **Hazard GeoTIFF**: Binary raster where 1 = wildland fuels that can generate embers
- **Area of Interest** (optional): Polygon shapefile, GeoPackage, or GeoJSON

### 2. Parameter Configuration
- **Transmission Distance**: Distance (in meters) that embers can travel from source
- **Exposure Threshold**: Minimum exposure value to consider as "high exposure" for directional analysis
- **Classification Method**: Choose between continuous, local, or landscape classification for visualization

### 3. Analysis Outputs

#### Exposure Map
Visual representation of wildfire exposure across your study area:
- Continuous scale showing raw exposure values (0-1)
- Classified maps with exposure categories (low, moderate, high, extreme)

#### Summary Statistics
Tabular breakdown of exposure by class:
- Area and proportion by exposure category
- Available when using classified visualization

#### Directional Analysis
Assessment of directional vulnerability toward your area of interest:
- Radial plot showing vulnerable directions
- Map visualization of directional transects
- Only available when an AOI polygon is uploaded

### 4. Download Results
- Export exposure raster as GeoTIFF
- Export directional analysis as GeoPackage (when available)

## Installation

### Prerequisites

1. **R** (version 4.0 or higher)

2. **XQuartz (macOS only)**:
   - Required for OpenGL support (used by `rgl` package)
   - Download from: https://www.xquartz.org/
   - Install and restart your computer

3. **Required R packages**:
   ```r
   install.packages(c("shiny", "bslib", "terra"))
   install.packages("fireexposuR")  # from CRAN
   ```

**Note:** If you encounter OpenGL/rgl errors, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for solutions.

### Running the App

1. Clone or download this repository
2. Open R or RStudio
3. Set working directory to the app folder:
   ```r
   setwd("/path/to/fire_exposure_app")
   ```
4. Run the app:
   ```r
   shiny::runApp()
   ```

Alternatively, if you have RStudio, simply open `app.R` and click the "Run App" button.

## Usage Example

### Basic Workflow

1. **Prepare your data**:
   - Hazard raster: Binary GeoTIFF (1 = fuel, 0 = no fuel)
   - (Optional) Area of interest: Polygon shapefile or GeoPackage

2. **Upload files**:
   - Click "Upload Hazard GeoTIFF" and select your raster file
   - If you have an AOI, click "Upload Area of Interest" and select your polygon

3. **Configure parameters**:
   - Set transmission distance (e.g., 500 meters for long-range embers)
   - Adjust exposure threshold if needed (default: 0.75)
   - Choose classification method for visualization

4. **Run analysis**:
   - Click "Calculate Exposure" button
   - Wait for processing (progress bar will show status)

5. **Explore results**:
   - View exposure map in "Exposure Map" tab
   - Check summary statistics in "Summary Statistics" tab
   - If AOI was uploaded, explore "Directional Analysis" tab

6. **Download results**:
   - Use download buttons to save raster and vector outputs

### Example Data

For testing purposes, you can use example data from the fireexposuR package:

```r
# Extract example hazard raster
library(terra)
library(fireexposuR)

# Get example hazard file path
hazard_path <- system.file("extdata/hazard.tif", package = "fireexposuR")

# Get example polygon
polygon_path <- system.file("extdata", "polygon.shp", package = "fireexposuR")

# Copy to a working directory
file.copy(hazard_path, "test_hazard.tif")
file.copy(
  list.files(dirname(polygon_path), pattern = "polygon", full.names = TRUE),
  "."
)
```

Then upload `test_hazard.tif` and `polygon.shp` in the app.

## Input Data Requirements

### Hazard Raster
- **Format**: GeoTIFF (.tif, .tiff)
- **Values**: Binary (0 and 1)
  - 1 = Wildland fuels that can generate embers
  - 0 = Non-fuel or areas that don't generate embers
- **Projection**: Any projected coordinate system (UTM recommended)
- **Resolution**: Depends on analysis scale (typically 30m - 250m)

### Area of Interest (Optional)
- **Format**: Shapefile (.shp), GeoPackage (.gpkg), or GeoJSON (.geojson)
- **Geometry**: Polygon or Point
- **Projection**: Should match or be compatible with hazard raster
- **Note**: For shapefiles, upload the .shp file (other files .shx, .dbf, .prj should be in the same directory)

## How It Works

The app uses the fireexposuR package to:

1. **Calculate Exposure** (`fire_exp()`):
   - Uses a focal window analysis with an annulus shape
   - Computes exposure as the proportion of hazard cells within the transmission distance
   - Returns values from 0 (no exposure) to 1 (maximum exposure)

2. **Directional Assessment** (`fire_exp_dir()`):
   - Creates radial transects around the area of interest
   - Classifies each direction as "viable" or "not viable" based on intersection with high-exposure patches
   - Useful for understanding which directions pose the greatest threat

3. **Visualization** (`fire_exp_map()`, `fire_exp_dir_plot()`):
   - Creates publication-ready maps and plots
   - Supports continuous and classified color scales
   - Integrates with standard R plotting

## Limitations

- **File size**: Large rasters (>1GB) may be slow to process or cause memory issues
- **Processing time**: Directional analysis can take several minutes for high-resolution data
- **Shapefile upload**: Only .shp file needs to be selected (but .shx, .dbf, .prj must be present)

## Troubleshooting

For detailed troubleshooting information, see **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)**.

Common issues include:
- **OpenGL/rgl errors** - Install XQuartz (macOS) or use NULL device option
- **File upload issues** - Ensure all shapefile components are present
- **Memory problems** - Reduce raster resolution or use smaller files
- **Long processing times** - Reduce transmission distance or simplify data

## References

This app implements methods from:

- Beverly, J.L., et al. (2010). "Assessing the exposure of the built environment to potential ignition sources generated from vegetative fuel." International Journal of Wildland Fire. doi:10.1071/WF09071

- Beverly, J.L., et al. (2021). "Time since prior wildfire affects subsequent fire containment in black spruce." International Journal of Wildland Fire. doi:10.1007/s10980-020-01173-8

- Beverly, J.L., & Forbes, A. (2023). "Burn probability simulation and subsequent wildland fire activity in Alberta, Canada." Natural Hazards. doi:10.1007/s11069-023-05885-3

## License

This app is provided as-is for exploration and educational purposes. The fireexposuR package is licensed under GPL (>= 3).

## Support

For issues with:
- **This app**: Open an issue in this repository
- **fireexposuR package**: See https://github.com/ropensci/fireexposuR/issues
- **General questions**: Refer to fireexposuR documentation and vignettes

## Author

Created as a basic functional mockup for exploring fireexposuR capabilities.

---

**Powered by [fireexposuR](https://docs.ropensci.org/fireexposuR/) - An rOpenSci reviewed package**
