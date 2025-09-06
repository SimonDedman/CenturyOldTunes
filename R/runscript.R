# Century Old Tunes - Main Execution Script
# Run this script to collect and verify 1925 music data

cat("=== CENTURY OLD TUNES DATA COLLECTION ===\n")
cat("Timestamp:", as.character(Sys.time()), "\n\n")

# Check and install required packages
required_packages <- c("httr", "jsonlite", "dplyr", "RSQLite", "DBI")

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    cat("Installing required package:", pkg, "\n")
    install.packages(pkg)
  }
}

# Load required libraries
library(httr)
library(jsonlite)
library(dplyr)
library(RSQLite)
library(DBI)

cat("✅ All required packages loaded\n\n")

# Source API functions in correct order
cat("--- LOADING API MODULES ---\n")

source("R/discogs_api.R")
cat("✅ Discogs API module loaded\n")

source("R/musicbrainz_api.R")
cat("✅ MusicBrainz API module loaded\n")

# Configuration
current_year <- as.numeric(format(Sys.Date(), "%Y"))
target_year <- current_year - 100
cat("Target collection year:", target_year, "\n\n")

# Main collection functions
cat("--- INITIALIZING DATABASE ---\n")

# Database setup function
setup_database <- function(db_path = "db/century_old_tunes.sqlite") {
  if (!dir.exists("db")) {
    dir.create("db")
    cat("Created db directory\n")
  }
  
  con <- dbConnect(SQLite(), db_path)
  
  # Create recordings table
  dbExecute(con, "
    CREATE TABLE IF NOT EXISTS recordings (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      artist TEXT NOT NULL,
      year INTEGER NOT NULL,
      country TEXT,
      genre TEXT,
      label TEXT,
      popularity_score REAL DEFAULT 0,
      source_api TEXT,
      source_id TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
  ")
  
  if (dbExistsTable(con, "recordings")) {
    cat("✅ Database and recordings table ready\n")
  } else {
    cat("❌ Failed to create recordings table\n")
  }
  
  dbDisconnect(con)
}

# Data collection function
collect_music_data <- function(year = target_year) {
  cat("\n--- COLLECTING MUSIC DATA FROM", year, "---\n")
  
  all_recordings <- data.frame()
  
  # Collect from Discogs
  tryCatch({
    cat("Fetching from Discogs API...\n")
    discogs_results <- search_discogs(year, per_page = 50)
    
    if (!is.null(discogs_results) && length(discogs_results) > 0) {
      discogs_data <- parse_discogs_result(discogs_results)
      cat("✅ Collected", nrow(discogs_data), "records from Discogs\n")
      all_recordings <- rbind(all_recordings, discogs_data)
    } else {
      cat("⚠️  No results from Discogs\n")
    }
  }, error = function(e) {
    cat("❌ Discogs error:", e$message, "\n")
  })
  
  # Collect from MusicBrainz
  tryCatch({
    cat("Fetching from MusicBrainz API...\n")
    mb_results <- search_musicbrainz(year, limit = 50)
    
    if (!is.null(mb_results) && nrow(mb_results) > 0) {
      mb_data <- parse_musicbrainz_result(mb_results)
      cat("✅ Collected", nrow(mb_data), "records from MusicBrainz\n")
      all_recordings <- rbind(all_recordings, mb_data)
    } else {
      cat("⚠️  No results from MusicBrainz\n")
    }
  }, error = function(e) {
    cat("❌ MusicBrainz error:", e$message, "\n")
  })
  
  # Remove duplicates
  if (nrow(all_recordings) > 0) {
    all_recordings <- all_recordings[!duplicated(paste(all_recordings$title, all_recordings$artist)), ]
    cat("✅ Total unique recordings:", nrow(all_recordings), "\n")
  } else {
    cat("❌ No data collected from any source\n")
  }
  
  return(all_recordings)
}

# Store data function
store_music_data <- function(data, db_path = "db/century_old_tunes.sqlite") {
  if (nrow(data) == 0) {
    cat("⚠️  No data to store\n")
    return(FALSE)
  }
  
  con <- dbConnect(SQLite(), db_path)
  
  tryCatch({
    # Clear existing data for clean run (optional)
    # dbExecute(con, "DELETE FROM recordings WHERE source_api IN ('discogs', 'musicbrainz')")
    
    dbWriteTable(con, "recordings", data, append = TRUE, row.names = FALSE)
    cat("✅ Stored", nrow(data), "recordings in database\n")
    dbDisconnect(con)
    return(TRUE)
  }, error = function(e) {
    cat("❌ Database storage error:", e$message, "\n")
    dbDisconnect(con)
    return(FALSE)
  })
}

# Main execution workflow
main_workflow <- function() {
  cat("=== STARTING MAIN WORKFLOW ===\n")
  
  # Step 1: Setup
  setup_database()
  
  # Step 2: Collect
  data <- collect_music_data()
  
  # Step 3: Store
  success <- store_music_data(data)
  
  # Step 4: Export to web
  if (success) {
    cat("\n--- EXPORTING TO WEB FRONTEND ---\n")
    tryCatch({
      source("R/export_to_web.R")
    }, error = function(e) {
      cat("Export script error:", e$message, "\n")
      cat("Run manually: source('R/export_to_web.R')\n")
    })
    
    cat("\n--- RUNNING VERIFICATION ---\n")
    tryCatch({
      source("R/verify_collection.R")
    }, error = function(e) {
      cat("Verification script error:", e$message, "\n")
      cat("Run manually: source('R/verify_collection.R')\n")
    })
  }
  
  cat("\n=== WORKFLOW COMPLETE ===\n")
  cat("Next steps:\n")
  cat("1. Check verification results above\n")
  cat("2. Visit your web frontend at docs/index.html\n")
  cat("3. Enable GitHub Pages to publish online\n")
}

# Execute main workflow when script is run
if (!interactive()) {
  main_workflow()
} else {
  cat("Interactive mode detected. Run main_workflow() to start collection.\n")
}