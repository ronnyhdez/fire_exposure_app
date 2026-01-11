# UI Definition
# Main UI layout using modular components

ui <- page_sidebar(
  title = "Fire Exposure Assessment Tool",
  theme = bs_theme(bootswatch = "flatly"),

  # Sidebar with file uploads and parameters
  mod_sidebar_ui("sidebar"),

  # Main panel with results
  mod_results_ui("results")
)
