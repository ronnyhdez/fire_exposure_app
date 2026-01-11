# Results Module
# Handles display of exposure maps, statistics, and directional analysis

#' Results UI
#'
#' @param id Module ID
#' @return Results panel UI elements
mod_results_ui <- function(id) {
  ns <- NS(id)

  card(
    card_header("Analysis Results"),

    conditionalPanel(
      condition = sprintf("!output['%s']", ns("results_ready")),
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
      condition = sprintf("output['%s']", ns("results_ready")),
      tabsetPanel(
        id = ns("results_tabs"),

        tabPanel(
          "Exposure Map",
          icon = icon("map"),
          br(),
          plotOutput(ns("exposure_map"), height = "600px")
        ),

        tabPanel(
          "Summary Statistics",
          icon = icon("table"),
          br(),
          conditionalPanel(
            condition = sprintf("output['%s']", ns("has_summary")),
            h4("Exposure Summary"),
            tableOutput(ns("summary_table"))
          ),
          conditionalPanel(
            condition = sprintf("!output['%s']", ns("has_summary")),
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
            condition = sprintf("output['%s']", ns("has_directional")),
            fluidRow(
              column(6, plotOutput(ns("directional_map"), height = "500px")),
              column(6, plotOutput(ns("directional_plot"), height = "500px"))
            )
          ),
          conditionalPanel(
            condition = sprintf("!output['%s']", ns("has_directional")),
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
}

#' Results Server
#'
#' @param id Module ID
#' @param rv Reactive values from sidebar module
#' @param classify_method Reactive classification method input
mod_results_server <- function(id, rv, classify_method) {
  moduleServer(id, function(input, output, session) {

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
      !is.null(rv$exposure) && classify_method() != "none"
    })
    outputOptions(output, "has_summary", suspendWhenHidden = FALSE)

    # Render exposure map
    output$exposure_map <- renderPlot({
      req(rv$exposure)

      if (classify_method() == "none") {
        # Continuous scale
        if (!is.null(rv$aoi)) {
          fire_exp_map(rv$exposure, rv$aoi)
        } else {
          fire_exp_map(rv$exposure)
        }
      } else {
        # Classified
        if (!is.null(rv$aoi)) {
          fire_exp_map(rv$exposure, rv$aoi, classify = classify_method())
        } else {
          fire_exp_map(rv$exposure, classify = classify_method())
        }
      }
    })

    # Render summary table
    output$summary_table <- renderTable({
      req(rv$exposure)
      req(classify_method() != "none")

      if (!is.null(rv$aoi)) {
        fire_exp_summary(rv$exposure, rv$aoi, classify = classify_method())
      } else {
        fire_exp_summary(rv$exposure, classify = classify_method())
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
  })
}
