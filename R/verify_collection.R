# Comprehensive verification script for Century Old Tunes data collection

library(RSQLite)
library(DBI)

verify_data_collection <- function(db_path = "db/century_old_tunes.sqlite") {
  cat("=== CENTURY OLD TUNES COLLECTION VERIFICATION ===\n")
  cat("Timestamp:", Sys.time(), "\n\n")
  
  # Check if database file exists
  if (!file.exists(db_path)) {
    cat("❌ CRITICAL: Database file does not exist at:", db_path, "\n")
    return(FALSE)
  }
  
  file_info <- file.info(db_path)
  cat("✅ Database file exists\n")
  cat("   File size:", round(file_info$size / 1024, 2), "KB\n")
  cat("   Last modified:", file_info$mtime, "\n\n")
  
  # Connect to database
  con <- dbConnect(SQLite(), db_path)
  on.exit(dbDisconnect(con))
  
  # Check table structure
  cat("--- DATABASE STRUCTURE ---\n")
  tables <- dbListTables(con)
  cat("Tables found:", paste(tables, collapse = ", "), "\n")
  
  if (!"recordings" %in% tables) {
    cat("❌ CRITICAL: 'recordings' table missing\n")
    return(FALSE)
  }
  
  cat("✅ Recordings table exists\n")
  
  # Check table schema
  schema <- dbGetQuery(con, "PRAGMA table_info(recordings)")
  cat("   Columns:", paste(schema$name, collapse = ", "), "\n\n")
  
  # Data quality checks
  cat("--- DATA QUALITY ANALYSIS ---\n")
  
  total_records <- dbGetQuery(con, "SELECT COUNT(*) as count FROM recordings")$count
  cat("Total records:", total_records, "\n")
  
  if (total_records == 0) {
    cat("❌ CRITICAL: No records found in database\n")
    cat("   This suggests the data collection failed\n")
    return(FALSE)
  }
  
  cat("✅ Database contains records\n\n")
  
  # Year distribution
  year_stats <- dbGetQuery(con, "
    SELECT 
      year,
      COUNT(*) as count,
      ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM recordings), 1) as percentage
    FROM recordings 
    GROUP BY year 
    ORDER BY count DESC
  ")
  
  cat("--- YEAR DISTRIBUTION ---\n")
  print(year_stats)
  
  target_year <- as.numeric(format(Sys.Date(), "%Y")) - 100
  target_year_count <- year_stats[year_stats$year == target_year, "count"]
  if (length(target_year_count) > 0 && target_year_count > 0) {
    cat("✅ Found", target_year_count, "records from target year", target_year, "\n")
  } else {
    cat("⚠️  WARNING: No records from target year", target_year, "\n")
  }
  
  cat("\n")
  
  # Country distribution
  cat("--- COUNTRY DISTRIBUTION ---\n")
  country_stats <- dbGetQuery(con, "
    SELECT 
      COALESCE(country, 'Unknown') as country,
      COUNT(*) as count,
      ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM recordings), 1) as percentage
    FROM recordings 
    GROUP BY country 
    ORDER BY count DESC
    LIMIT 10
  ")
  print(country_stats)
  
  us_count <- sum(country_stats[grepl("US|United States", country_stats$country, ignore.case = TRUE), "count"], na.rm = TRUE)
  if (us_count > 0) {
    cat("✅ Found", us_count, "US records\n")
  } else {
    cat("⚠️  WARNING: No US records found\n")
  }
  
  cat("\n")
  
  # Genre distribution
  cat("--- GENRE DISTRIBUTION ---\n")
  genre_stats <- dbGetQuery(con, "
    SELECT 
      COALESCE(genre, 'Unknown') as genre,
      COUNT(*) as count,
      ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM recordings), 1) as percentage
    FROM recordings 
    GROUP BY genre 
    ORDER BY count DESC
    LIMIT 10
  ")
  print(genre_stats)
  
  folk_count <- sum(genre_stats[grepl("folk", genre_stats$genre, ignore.case = TRUE), "count"], na.rm = TRUE)
  if (folk_count > 0) {
    cat("✅ Found", folk_count, "folk records\n")
  } else {
    cat("⚠️  WARNING: No folk records found\n")
  }
  
  cat("\n")
  
  # API source distribution
  cat("--- DATA SOURCE DISTRIBUTION ---\n")
  source_stats <- dbGetQuery(con, "
    SELECT 
      COALESCE(source_api, 'Unknown') as source,
      COUNT(*) as count,
      ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM recordings), 1) as percentage
    FROM recordings 
    GROUP BY source_api 
    ORDER BY count DESC
  ")
  print(source_stats)
  
  if (nrow(source_stats[source_stats$source == "discogs", ]) > 0) {
    cat("✅ Discogs data collected\n")
  } else {
    cat("⚠️  WARNING: No Discogs data found\n")
  }
  
  if (nrow(source_stats[source_stats$source == "musicbrainz", ]) > 0) {
    cat("✅ MusicBrainz data collected\n")
  } else {
    cat("⚠️  WARNING: No MusicBrainz data found\n")
  }
  
  cat("\n")
  
  # Data completeness check
  cat("--- DATA COMPLETENESS ---\n")
  completeness <- dbGetQuery(con, "
    SELECT 
      'Title' as field,
      COUNT(*) - COUNT(NULLIF(title, '')) as complete,
      COUNT(NULLIF(title, '')) as missing,
      ROUND((COUNT(*) - COUNT(NULLIF(title, ''))) * 100.0 / COUNT(*), 1) as completeness_pct
    FROM recordings
    UNION ALL
    SELECT 
      'Artist' as field,
      COUNT(*) - COUNT(NULLIF(artist, '')) as complete,
      COUNT(NULLIF(artist, '')) as missing,
      ROUND((COUNT(*) - COUNT(NULLIF(artist, ''))) * 100.0 / COUNT(*), 1) as completeness_pct
    FROM recordings
    UNION ALL
    SELECT 
      'Country' as field,
      COUNT(*) - COUNT(NULLIF(country, '')) as complete,
      COUNT(NULLIF(country, '')) as missing,
      ROUND((COUNT(*) - COUNT(NULLIF(country, ''))) * 100.0 / COUNT(*), 1) as completeness_pct
    FROM recordings
    UNION ALL
    SELECT 
      'Genre' as field,
      COUNT(*) - COUNT(NULLIF(genre, '')) as complete,
      COUNT(NULLIF(genre, '')) as missing,
      ROUND((COUNT(*) - COUNT(NULLIF(genre, ''))) * 100.0 / COUNT(*), 1) as completeness_pct
    FROM recordings
  ")
  print(completeness)
  
  # Sample records
  cat("\n--- SAMPLE RECORDS ---\n")
  cat("First 5 records:\n")
  sample_records <- dbGetQuery(con, "SELECT title, artist, year, country, genre, source_api FROM recordings LIMIT 5")
  print(sample_records)
  
  # Specific test: US Folk from target year
  cat("\n--- SPECIFIC TEST: US Folk from", target_year, "---\n")
  us_folk_query <- paste0("
    SELECT title, artist, year, country, genre 
    FROM recordings 
    WHERE year = ", target_year, "
    AND (country LIKE '%US%' OR country LIKE '%United States%')
    AND (genre LIKE '%folk%' OR genre LIKE '%Folk%')
    LIMIT 10
  ")
  
  us_folk_results <- dbGetQuery(con, us_folk_query)
  if (nrow(us_folk_results) > 0) {
    cat("✅ Found", nrow(us_folk_results), "US Folk records from", target_year, ":\n")
    print(us_folk_results)
  } else {
    cat("❌ No US Folk records found from", target_year, "\n")
    cat("   This explains why the web interface shows no results\n")
  }
  
  # Overall assessment
  cat("\n=== OVERALL ASSESSMENT ===\n")
  
  issues <- c()
  if (total_records == 0) issues <- c(issues, "No data collected")
  if (us_count == 0) issues <- c(issues, "No US records")
  if (folk_count == 0) issues <- c(issues, "No folk records")
  if (nrow(us_folk_results) == 0) issues <- c(issues, "No US folk records from target year")
  
  if (length(issues) == 0) {
    cat("🎉 SUCCESS: Data collection appears to be working correctly\n")
    return(TRUE)
  } else {
    cat("⚠️  ISSUES FOUND:\n")
    for (issue in issues) {
      cat("   -", issue, "\n")
    }
    cat("\nRecommendations:\n")
    cat("1. Check API connections with: source('R/test_apis.R')\n")
    cat("2. Review collection logs for errors\n")
    cat("3. Consider expanding search parameters or trying different genres\n")
    return(FALSE)
  }
}

# Run verification
verify_data_collection()