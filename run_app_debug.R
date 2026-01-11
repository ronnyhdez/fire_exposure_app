# Debug version of run_app with more verbose error handling

options(rgl.useNULL = TRUE)
options(shiny.error = function() {
  cat("\n!!! SHINY ERROR OCCURRED !!!\n")
  traceback()
})

cat("Starting app with debug mode...\n")

# Try to run the app with error catching
tryCatch({
  shiny::runApp(
    appDir = ".",
    launch.browser = TRUE,
    quiet = FALSE
  )
}, error = function(e) {
  cat("\n!!! ERROR DURING APP STARTUP !!!\n")
  cat("Error message:", conditionMessage(e), "\n")
  cat("\nFull error:\n")
  print(e)
  cat("\nStack trace:\n")
  traceback()
})
