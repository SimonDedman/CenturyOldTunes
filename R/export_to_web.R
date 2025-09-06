# Export SQLite database data to JSON for web frontend

library(RSQLite)
library(DBI)
library(jsonlite)

export_database_to_web <- function(db_path = "db/century_old_tunes.sqlite", output_dir = "docs/data") {
  cat("=== EXPORTING DATABASE TO WEB FRONTEND ===\n")
  
  if (!file.exists(db_path)) {
    cat("❌ Database file not found:", db_path, "\n")
    return(FALSE)
  }
  
  # Create data directory if it doesn't exist
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
    cat("Created data directory:", output_dir, "\n")
  }
  
  con <- dbConnect(SQLite(), db_path)
  
  # Export all recordings (excluding test data)
  cat("Exporting recordings data...\n")
  recordings <- dbGetQuery(con, "
    SELECT 
      title,
      artist,
      year,
      country,
      genre,
      label,
      popularity_score,
      source_api,
      source_id
    FROM recordings 
    WHERE source_api != 'test'
    ORDER BY title, artist
  ")
  
  cat("Found", nrow(recordings), "recordings to export\n")
  
  # Clean and standardize data for frontend
  recordings_clean <- recordings
  recordings_clean$country[recordings_clean$country == ""] <- "Unknown"
  recordings_clean$genre[recordings_clean$genre == ""] <- "Unknown"
  recordings_clean$label[recordings_clean$label == ""] <- "Unknown"
  
  # Convert popularity_score to 0-1 range if needed
  if (max(recordings_clean$popularity_score, na.rm = TRUE) > 1) {
    recordings_clean$popularity_score <- recordings_clean$popularity_score / 100
  }
  
  # Export main recordings data
  writeLines(
    toJSON(recordings_clean, pretty = TRUE, na = "string"), 
    file.path(output_dir, "recordings.json")
  )
  cat("✅ Exported recordings to", file.path(output_dir, "recordings.json"), "\n")
  
  # Export summary statistics
  cat("Generating summary statistics...\n")
  
  total_recordings <- nrow(recordings_clean)
  unique_artists <- length(unique(recordings_clean$artist[recordings_clean$artist != "Unknown Artist"]))
  unique_countries <- length(unique(recordings_clean$country[recordings_clean$country != "Unknown"]))
  unique_genres <- length(unique(recordings_clean$genre[recordings_clean$genre != "Unknown"]))
  
  # Country breakdown
  country_stats <- dbGetQuery(con, "
    SELECT 
      CASE WHEN country = '' THEN 'Unknown' ELSE country END as country,
      COUNT(*) as count
    FROM recordings 
    WHERE source_api != 'test'
    GROUP BY country 
    ORDER BY count DESC
  ")
  
  # Genre breakdown
  genre_stats <- dbGetQuery(con, "
    SELECT 
      CASE WHEN genre = '' THEN 'Unknown' ELSE genre END as genre,
      COUNT(*) as count
    FROM recordings 
    WHERE source_api != 'test'
    GROUP BY genre 
    ORDER BY count DESC
  ")
  
  # Year breakdown (should mostly be target year)
  year_stats <- dbGetQuery(con, "
    SELECT 
      year,
      COUNT(*) as count
    FROM recordings 
    WHERE source_api != 'test'
    GROUP BY year 
    ORDER BY year DESC
  ")
  
  stats <- list(
    totalRecordings = total_recordings,
    totalArtists = unique_artists,
    totalCountries = unique_countries,
    totalGenres = unique_genres,
    countryBreakdown = country_stats,
    genreBreakdown = genre_stats,
    yearBreakdown = year_stats,
    lastUpdated = Sys.time()
  )
  
  writeLines(
    toJSON(stats, pretty = TRUE, na = "string"), 
    file.path(output_dir, "stats.json")
  )
  cat("✅ Exported statistics to", file.path(output_dir, "stats.json"), "\n")
  
  # Export filtered datasets for common searches
  cat("Creating filtered datasets...\n")
  
  # US Folk records (the problematic search case)
  us_folk <- recordings_clean[
    recordings_clean$country %in% c("US", "USA", "United States") &
    grepl("folk|Folk", recordings_clean$genre, ignore.case = TRUE), 
  ]
  
  writeLines(
    toJSON(us_folk, pretty = TRUE, na = "string"),
    file.path(output_dir, "us_folk.json")
  )
  cat("✅ Exported", nrow(us_folk), "US folk records to us_folk.json\n")
  
  # Popular genres
  top_genres <- c("Jazz", "Pop", "Folk", "Blues", "Classical")
  for (genre in top_genres) {
    genre_data <- recordings_clean[grepl(genre, recordings_clean$genre, ignore.case = TRUE), ]
    if (nrow(genre_data) > 0) {
      filename <- paste0(tolower(genre), "_records.json")
      writeLines(
        toJSON(genre_data, pretty = TRUE, na = "string"),
        file.path(output_dir, filename)
      )
      cat("✅ Exported", nrow(genre_data), genre, "records to", filename, "\n")
    }
  }
  
  dbDisconnect(con)
  
  cat("\n=== EXPORT COMPLETE ===\n")
  cat("Web data files created in:", output_dir, "\n")
  cat("Next: Update docs/app.js to load from these JSON files\n")
  
  return(TRUE)
}

# Run export
export_database_to_web()