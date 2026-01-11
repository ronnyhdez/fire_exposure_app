# Sidebar Module
# Handles file uploads, parameter inputs, and analysis trigger

#' Sidebar UI
#'
#' @param id Module ID
#' @return Sidebar UI elements
mod_sidebar_ui <- function(id) {
  ns <- NS(id)

  sidebar(
    width = 350,

    h4("1. Upload Data"),
    fileInput(
      ns("hazard_file"),
      "Upload Hazard GeoTIFF",
      accept = c(".tif", ".tiff", ".TIF", ".TIFF")
    ),
    helpText("Upload a binary raster where 1 = wildland fuels that can generate embers"),

    hr(),

    fileInput(
      ns("aoi_file"),
      "Upload Area of Interest (Optional)",
      accept = c(".shp", ".gpkg", ".geojson")
    ),
    helpText("Upload a shapefile, GeoPackage, or GeoJSON. If .shp, upload all related files (.shx, .dbf, .prj)"),

    hr(),

    h4("2. Set Parameters"),
    numericInput(
      ns("t_dist"),
      "Transmission Distance (meters)",
      value = 500,
      min = 100,
      max = 2000,
      step = 50
    ),
    helpText("Distance embers can travel from source"),

    numericInput(
      ns("thresh_exp"),
      "Exposure Threshold (for directional analysis)",
      value = 0.75,
      min = 0,
      max = 1,
      step = 0.05
    ),
    helpText("Minimum exposure value to consider 'high exposure'"),

    selectInput(
      ns("classify_method"),
      "Classification Method (for visualization)",
      choices = c("Continuous" = "none", "Local" = "local", "Landscape" = "landscape"),
      selected = "local"
    ),

    hr(),

    h4("3. Run Analysis"),
    actionButton(
      ns("run_analysis"),
      "Calculate Exposure",
      class = "btn-primary btn-lg",
      width = "100%"
    ),

    hr(),

    conditionalPanel(
      condition = sprintf("output['%s']", ns("results_ready")),
      h4("4. Download Results"),
      downloadButton(
        ns("download_exposure"),
        "Download Exposure Raster",
        class = "btn-success",
        style = "width: 100%; margin-bottom: 10px;"
      ),
      conditionalPanel(
        condition = sprintf("output['%s']", ns("has_directional")),
        downloadButton(
          ns("download_directional"),
          "Download Directional Data",
          class = "btn-success",
          style = "width: 100%;"
        )
      )
    )
  )
}

#' Sidebar Server
#'
#' @param id Module ID
#' @return Reactive values with analysis results
mod_sidebar_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    # Reactive values to store results
    rv <- reactiveValues(
      exposure = NULL,
      dir_exposure = NULL,
      aoi = NULL,
      results_ready = FALSE
    )

    # Main analysis
    observeEvent(input$run_analysis, {
      req(input$hazard_file)
      req(input$t_dist)
      req(input$thresh_exp)

      # Show progress
      withProgress(message = 'Calculating exposure...', value = 0, {

        tryCatch({
          # Validate parameters
          validation <- validate_analysis_params(input$t_dist, input$thresh_exp)

          if (!validation$valid) {
            showNotification(validation$message, type = "error")
            return()
          }

          t_dist <- validation$t_dist
          thresh_exp <- validation$thresh_exp

          # Load hazard raster
          incProgress(0.2, detail = "Loading hazard data")
          hazard <- terra::rast(input$hazard_file$datapath)

          # Calculate exposure
          incProgress(0.3, detail = "Computing exposure metric")
          rv$exposure <- fire_exp(hazard, t_dist = t_dist)

          # Load AOI if provided
          if (!is.null(input$aoi_file)) {
            incProgress(0.6, detail = "Loading area of interest")

            rv$aoi <- load_vector_file(
              input$aoi_file$datapath,
              input$aoi_file$name
            )

            # Calculate directional exposure
            incProgress(0.8, detail = "Computing directional vulnerability")
            rv$dir_exposure <- fire_exp_dir(
              rv$exposure,
              rv$aoi,
              thresh_exp = thresh_exp
            )
          } else {
            rv$aoi <- NULL
            rv$dir_exposure <- NULL
          }

          incProgress(1, detail = "Complete!")
          rv$results_ready <- TRUE

          showNotification(
            "Analysis complete!",
            type = "message",
            duration = 3
          )

        }, error = function(e) {
          showNotification(
            paste("Error:", e$message),
            type = "error",
            duration = 10
          )
        })
      })
    })

    # Output: results ready flag
    output$results_ready <- reactive({
      rv$results_ready
    })
    outputOptions(output, "results_ready", suspendWhenHidden = FALSE)

    # Output: has directional flag
    output$has_directional <- reactive({
      !is.null(rv$dir_exposure)
    })
    outputOptions(output, "has_directional", suspendWhenHidden = FALSE)

    # Download exposure raster
    output$download_exposure <- downloadHandler(
      filename = function() {
        paste0("fire_exposure_", Sys.Date(), ".tif")
      },
      content = function(file) {
        terra::writeRaster(rv$exposure, file, overwrite = TRUE)
      }
    )

    # Download directional data
    output$download_directional <- downloadHandler(
      filename = function() {
        paste0("fire_directional_", Sys.Date(), ".gpkg")
      },
      content = function(file) {
        terra::writeVector(rv$dir_exposure, file, overwrite = TRUE)
      }
    )

    # Return reactive values and inputs as a list
    return(list(
      rv = rv,
      classify_method = reactive(input$classify_method)
    ))
  })
}
