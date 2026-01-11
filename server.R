# Server Logic
# Main server function connecting modular components

server <- function(input, output, session) {

  # Initialize sidebar module (handles analysis)
  sidebar_return <- mod_sidebar_server("sidebar")

  # Initialize results module (handles display)
  # Pass reactive values and classify method from sidebar
  mod_results_server(
    "results",
    rv = sidebar_return$rv,
    classify_method = sidebar_return$classify_method
  )
}
