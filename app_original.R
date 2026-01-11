# Fire Exposure Assessment Shiny App
# A basic interface for the fireexposuR package

# Suppress rgl warnings/errors if OpenGL is not available
options(rgl.useNULL = TRUE)

library(shiny)
library(fireexposuR)
library(terra)
library(bslib)

# UI
ui <- page_sidebar(
  title = "Fire Exposure Assessment Tool",
  theme = bs_theme(bootswatch = "flatly"),

  sidebar = sidebar(
    width = 350,

    h4("1. Upload Data"),
    fileInput(
      "hazard_file",
      "Upload Hazard GeoTIFF",
      accept = c(".tif", ".tiff", ".TIF", ".TIFF")
    ),
    helpText("Upload a binary raster where 1 = wildland fuels that can generate embers"),

    hr(),

    fileInput(
      "aoi_file",
      "Upload Area of Interest (Optional)",
      accept = c(".shp", ".gpkg", ".geojson")
    ),
    helpText("Upload a shapefile, GeoPackage, or GeoJSON. If .shp, upload all related files (.shx, .dbf, .prj)"),

    hr(),

    h4("2. Set Parameters"),
    numericInput(
      "t_dist",
      "Transmission Distance (meters)",
      value = 500,
      min = 100,
      max = 2000,
      step = 50
    ),
    helpText("Distance embers can travel from source"),

    numericInput(
      "thresh_exp",
      "Exposure Threshold (for directional analysis)",
      value = 0.75,
      min = 0,
      max = 1,
      step = 0.05
    ),
    helpText("Minimum exposure value to consider 'high exposure'"),

    selectInput(
      "classify_method",
      "Classification Method (for visualization)",
      choices = c("Continuous" = "none", "Local" = "local", "Landscape" = "landscape"),
      selected = "local"
    ),

    hr(),

    h4("3. Run Analysis"),
    actionButton(
      "run_analysis",
      "Calculate Exposure",
      class = "btn-primary btn-lg",
      width = "100%"
    ),

    hr(),

    conditionalPanel(
      condition = "output.results_ready",
      h4("4. Download Results"),
      downloadButton("download_exposure", "Download Exposure Raster", class = "btn-success", style = "width: 100%; margin-bottom: 10px;"),
      conditionalPanel(
        condition = "output.has_directional",
        downloadButton("download_directional", "Download Directional Data", class = "btn-success", style = "width: 100%;")
      )
    )
  ),

  # Main panel
  card(
    card_header("Analysis Results"),

    conditionalPanel(
      condition = "!output.results_ready",
      div(
        style = "text-align: center; padding: 50px;",
        icon("fire", style = "font-size: 72px; color: #e74c3c;"),
        h3("Welcome to Fire Exposure Assessment"),
        p("Upload your hazard data and configure parameters to get started."),
        tags$ul(
          style = "text-align: left; display: inline-block;",
          tags$li("Upload a binary hazard raster (GeoTIFF format)"),
          tags$li("Optionally upload an area of interest polygon"),
          tags$li("Set your transmission distance and thresholds"),
          tags$li("Click 'Calculate Exposure' to run the analysis")
        )
      )
    ),

    conditionalPanel(
      condition = "output.results_ready",
      tabsetPanel(
        id = "results_tabs",

        tabPanel(
          "Exposure Map",
          icon = icon("map"),
          br(),
          plotOutput("exposure_map", height = "600px")
        ),

        tabPanel(
          "Summary Statistics",
          icon = icon("table"),
          br(),
          conditionalPanel(
            condition = "output.has_summary",
            h4("Exposure Summary"),
            tableOutput("summary_table")
          ),
          conditionalPanel(
            condition = "!output.has_summary",
            div(
              style = "text-align: center; padding: 50px;",
              p("Summary statistics require classified data. Select 'Local' or 'Landscape' classification method.")
            )
          )
        ),

        tabPanel(
          "Directional Analysis",
          icon = icon("compass"),
          br(),
          conditionalPanel(
            condition = "output.has_directional",
            fluidRow(
              column(6, plotOutput("directional_map", height = "500px")),
              column(6, plotOutput("directional_plot", height = "500px"))
            )
          ),
          conditionalPanel(
            condition = "!output.has_directional",
            div(
              style = "text-align: center; padding: 50px;",
              icon("info-circle", style = "font-size: 48px; color: #3498db;"),
              h4("Directional analysis requires an Area of Interest"),
              p("Upload a polygon shapefile to enable directional vulnerability assessment.")
            )
          )
        ),

        tabPanel(
          "Info",
          icon = icon("info-circle"),
          br(),
          h4("About This Tool"),
          p("This application provides an interactive interface for the fireexposuR R package."),
          h5("What does it do?"),
          p("This tool calculates wildfire exposure based on hazard data (typically wildland fuels) and a transmission distance representing how far embers can travel."),
          h5("Outputs:"),
          tags$ul(
            tags$li(strong("Exposure Map:"), " Visual representation of exposure values across your study area"),
            tags$li(strong("Summary Statistics:"), " Tabular breakdown of exposure by class"),
            tags$li(strong("Directional Analysis:"), " Assessment of directional vulnerability toward your area of interest")
          ),
          h5("References:"),
          tags$ul(
            tags$li("Beverly, J.L., et al. (2010). doi:10.1071/WF09071"),
            tags$li("Beverly, J.L., et al. (2021). doi:10.1007/s10980-020-01173-8"),
            tags$li("Beverly, J.L., & Forbes, A. (2023). doi:10.1007/s11069-023-05885-3")
          ),
          hr(),
          p(em("Powered by fireexposuR"), style = "text-align: center;")
        )
      )
    )
  )
)

# Server
server <- function(input, output, session) {

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
        # Validate and convert parameters
        t_dist <- as.numeric(input$t_dist)
        thresh_exp <- as.numeric(input$thresh_exp)

        # Validate parameter values
        if (is.na(t_dist) || t_dist <= 0) {
          showNotification("Invalid transmission distance", type = "error")
          return()
        }
        if (is.na(thresh_exp) || thresh_exp < 0 || thresh_exp > 1) {
          showNotification("Exposure threshold must be between 0 and 1", type = "error")
          return()
        }

        # Load hazard raster
        incProgress(0.2, detail = "Loading hazard data")
        hazard <- terra::rast(input$hazard_file$datapath)

        # Calculate exposure
        incProgress(0.3, detail = "Computing exposure metric")
        rv$exposure <- fire_exp(hazard, t_dist = t_dist)

        # Load AOI if provided
        if (!is.null(input$aoi_file)) {
          incProgress(0.6, detail = "Loading area of interest")

          # Handle different file types
          file_ext <- tools::file_ext(input$aoi_file$name)

          if (file_ext == "shp") {
            # For shapefiles, we need to handle multiple files
            # Copy to temp directory with proper naming
            temp_dir <- tempdir()
            file.copy(input$aoi_file$datapath, file.path(temp_dir, input$aoi_file$name))
            rv$aoi <- terra::vect(file.path(temp_dir, input$aoi_file$name))
          } else {
            rv$aoi <- terra::vect(input$aoi_file$datapath)
          }

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

  # Output: has summary flag
  output$has_summary <- reactive({
    !is.null(rv$exposure) && input$classify_method != "none"
  })
  outputOptions(output, "has_summary", suspendWhenHidden = FALSE)

  # Render exposure map
  output$exposure_map <- renderPlot({
    req(rv$exposure)

    if (input$classify_method == "none") {
      # Continuous scale
      if (!is.null(rv$aoi)) {
        fire_exp_map(rv$exposure, rv$aoi)
      } else {
        fire_exp_map(rv$exposure)
      }
    } else {
      # Classified
      if (!is.null(rv$aoi)) {
        fire_exp_map(rv$exposure, rv$aoi, classify = input$classify_method)
      } else {
        fire_exp_map(rv$exposure, classify = input$classify_method)
      }
    }
  })

  # Render summary table
  output$summary_table <- renderTable({
    req(rv$exposure)
    req(input$classify_method != "none")

    if (!is.null(rv$aoi)) {
      fire_exp_summary(rv$exposure, rv$aoi, classify = input$classify_method)
    } else {
      fire_exp_summary(rv$exposure, classify = input$classify_method)
    }
  })

  # Render directional map
  output$directional_map <- renderPlot({
    req(rv$dir_exposure)
    req(rv$aoi)

    fire_exp_dir_map(rv$dir_exposure, rv$aoi)
  })

  # Render directional plot
  output$directional_plot <- renderPlot({
    req(rv$dir_exposure)

    fire_exp_dir_plot(rv$dir_exposure)
  })

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
}

# Run the app
shinyApp(ui = ui, server = server)
