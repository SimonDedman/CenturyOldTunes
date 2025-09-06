# Serve the web frontend using R's built-in server
# Alternative to Python server

serve_web_frontend <- function(port = 8000) {
  if (!requireNamespace("servr", quietly = TRUE)) {
    cat("Installing servr package for web server...\n")
    install.packages("servr")
  }
  
  library(servr)
  
  cat("🎵 Century Old Tunes Web Server\n")
  cat("📁 Serving docs/ directory\n")
  cat("🌐 Open: http://localhost:", port, "\n")
  cat("⏹️  Press Ctrl+C or ESC to stop\n\n")
  
  # Change to project root and serve docs folder
  servr::httd(dir = "docs", port = port, browser = TRUE)
}

# Run the server
serve_web_frontend()