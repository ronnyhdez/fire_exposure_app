# Fire Exposure Assessment Shiny App
# Main entry point for the application
#
# This is a modular Shiny app with the following structure:
# - global.R: Package loading and global configuration
# - ui.R: User interface definition
# - server.R: Server logic
# - R/: Directory containing modules and utility functions
#   - mod_sidebar.R: Sidebar module (file uploads, parameters)
#   - mod_results.R: Results module (maps, tables, plots)
#   - utils.R: Utility functions

# Run the application
shinyApp(ui = ui, server = server)
