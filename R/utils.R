# Utility Functions
# Shared helper functions used across the app

#' Validate numeric parameter
#'
#' @param value Input value to validate
#' @param param_name Parameter name for error messages
#' @param min_val Minimum allowed value (inclusive)
#' @param max_val Maximum allowed value (inclusive)
#' @return Numeric value if valid, NULL if invalid
validate_numeric_param <- function(value, param_name, min_val = NULL, max_val = NULL) {
  num_val <- as.numeric(value)

  if (is.na(num_val)) {
    return(list(valid = FALSE, message = paste(param_name, "must be a valid number")))
  }

  if (!is.null(min_val) && num_val < min_val) {
    return(list(valid = FALSE, message = paste(param_name, "must be at least", min_val)))
  }

  if (!is.null(max_val) && num_val > max_val) {
    return(list(valid = FALSE, message = paste(param_name, "must be at most", max_val)))
  }

  return(list(valid = TRUE, value = num_val))
}

#' Load vector file (handles multiple formats)
#'
#' @param file_path Path to the file
#' @param file_name Original filename
#' @return terra SpatVector object
load_vector_file <- function(file_path, file_name) {
  file_ext <- tools::file_ext(file_name)

  if (file_ext == "shp") {
    # For shapefiles, copy to temp directory with proper naming
    temp_dir <- tempdir()
    temp_path <- file.path(temp_dir, file_name)
    file.copy(file_path, temp_path, overwrite = TRUE)
    vect_data <- terra::vect(temp_path)
  } else {
    # For other formats (gpkg, geojson, etc.)
    vect_data <- terra::vect(file_path)
  }

  return(vect_data)
}

#' Validate parameters before analysis
#'
#' @param t_dist Transmission distance
#' @param thresh_exp Exposure threshold
#' @return List with valid flag and message
validate_analysis_params <- function(t_dist, thresh_exp) {
  # Validate transmission distance
  t_dist_check <- validate_numeric_param(t_dist, "Transmission distance", min_val = 0)
  if (!t_dist_check$valid) {
    return(t_dist_check)
  }

  # Validate exposure threshold
  thresh_check <- validate_numeric_param(thresh_exp, "Exposure threshold", min_val = 0, max_val = 1)
  if (!thresh_check$valid) {
    return(thresh_check)
  }

  return(list(
    valid = TRUE,
    t_dist = t_dist_check$value,
    thresh_exp = thresh_check$value
  ))
}
