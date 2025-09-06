# Database Integrity Validation Script for Century Old Tunes

library(RSQLite)
library(DBI)

validate_database_integrity <- function(db_path = "db/century_old_tunes.sqlite") {
  cat("=== DATABASE INTEGRITY VALIDATION ===\n")
  cat("Timestamp:", Sys.time(), "\n\n")
  
  if (!file.exists(db_path)) {
    cat("❌ CRITICAL: Database file missing\n")
    return(FALSE)
  }
  
  con <- dbConnect(SQLite(), db_path)
  on.exit(dbDisconnect(con))
  
  # Check database file integrity
  cat("--- FILE INTEGRITY ---\n")
  integrity_check <- dbGetQuery(con, "PRAGMA integrity_check")
  if (integrity_check$integrity_check[1] == "ok") {
    cat("✅ Database file integrity: OK\n")
  } else {
    cat("❌ Database corruption detected:\n")
    print(integrity_check)
    return(FALSE)
  }
  
  # Check foreign key constraints
  cat("\n--- CONSTRAINT VALIDATION ---\n")
  fk_check <- dbGetQuery(con, "PRAGMA foreign_key_check")
  if (nrow(fk_check) == 0) {
    cat("✅ Foreign key constraints: OK\n")
  } else {
    cat("❌ Foreign key constraint violations:\n")
    print(fk_check)
  }
  
  # Validate data quality
  cat("\n--- DATA QUALITY VALIDATION ---\n")
  
  # Check for required fields
  null_checks <- list(
    "Empty titles" = "SELECT COUNT(*) as count FROM recordings WHERE title IS NULL OR title = ''",
    "Empty artists" = "SELECT COUNT(*) as count FROM recordings WHERE artist IS NULL OR artist = ''",
    "Invalid years" = "SELECT COUNT(*) as count FROM recordings WHERE year IS NULL OR year < 1900 OR year > 2025",
    "Missing source API" = "SELECT COUNT(*) as count FROM recordings WHERE source_api IS NULL OR source_api = ''"
  )
  
  for (check_name in names(null_checks)) {
    result <- dbGetQuery(con, null_checks[[check_name]])
    count <- result$count[1]
    if (count == 0) {
      cat("✅", check_name, ": None found\n")
    } else {
      cat("⚠️ ", check_name, ":", count, "records\n")
    }
  }
  
  # Check for duplicates
  cat("\n--- DUPLICATE DETECTION ---\n")
  
  duplicate_checks <- list(
    "Exact duplicates (all fields)" = "
      SELECT COUNT(*) as count FROM (
        SELECT title, artist, year, country, genre, COUNT(*) as dup_count 
        FROM recordings 
        GROUP BY title, artist, year, country, genre 
        HAVING COUNT(*) > 1
      )",
    "Title/Artist duplicates" = "
      SELECT COUNT(*) as count FROM (
        SELECT title, artist, COUNT(*) as dup_count 
        FROM recordings 
        GROUP BY title, artist 
        HAVING COUNT(*) > 1
      )",
    "Same source_id duplicates" = "
      SELECT COUNT(*) as count FROM (
        SELECT source_api, source_id, COUNT(*) as dup_count 
        FROM recordings 
        WHERE source_id IS NOT NULL AND source_id != ''
        GROUP BY source_api, source_id 
        HAVING COUNT(*) > 1
      )"
  )
  
  for (check_name in names(duplicate_checks)) {
    result <- dbGetQuery(con, duplicate_checks[[check_name]])
    count <- result$count[1]
    if (count == 0) {
      cat("✅", check_name, ": None found\n")
    } else {
      cat("⚠️ ", check_name, ":", count, "duplicate groups\n")
    }
  }
  
  # Statistical validation
  cat("\n--- STATISTICAL VALIDATION ---\n")
  
  # Year distribution analysis
  year_stats <- dbGetQuery(con, "
    SELECT 
      MIN(year) as min_year,
      MAX(year) as max_year,
      AVG(year) as avg_year,
      COUNT(DISTINCT year) as unique_years
    FROM recordings
  ")
  
  cat("Year range:", year_stats$min_year, "to", year_stats$max_year, "\n")
  cat("Average year:", round(year_stats$avg_year, 1), "\n")
  cat("Unique years:", year_stats$unique_years, "\n")
  
  target_year <- as.numeric(format(Sys.Date(), "%Y")) - 100
  if (year_stats$min_year <= target_year && year_stats$max_year >= target_year) {
    cat("✅ Target year", target_year, "within range\n")
  } else {
    cat("⚠️  Target year", target_year, "not in collected data range\n")
  }
  
  # Text field validation
  cat("\n--- TEXT FIELD VALIDATION ---\n")
  
  text_stats <- dbGetQuery(con, "
    SELECT 
      'Title' as field,
      MIN(LENGTH(title)) as min_length,
      MAX(LENGTH(title)) as max_length,
      AVG(LENGTH(title)) as avg_length
    FROM recordings WHERE title IS NOT NULL
    UNION ALL
    SELECT 
      'Artist' as field,
      MIN(LENGTH(artist)) as min_length,
      MAX(LENGTH(artist)) as max_length,
      AVG(LENGTH(artist)) as avg_length
    FROM recordings WHERE artist IS NOT NULL
  ")
  
  print(text_stats)
  
  # Check for suspicious patterns
  cat("\n--- SUSPICIOUS PATTERN DETECTION ---\n")
  
  suspicious_patterns <- list(
    "Very short titles" = "SELECT COUNT(*) as count FROM recordings WHERE LENGTH(title) < 2",
    "Very long titles" = "SELECT COUNT(*) as count FROM recordings WHERE LENGTH(title) > 200",
    "Single character artists" = "SELECT COUNT(*) as count FROM recordings WHERE LENGTH(artist) = 1",
    "Test data remnants" = "SELECT COUNT(*) as count FROM recordings WHERE title LIKE '%test%' OR artist LIKE '%test%'"
  )
  
  for (pattern_name in names(suspicious_patterns)) {
    result <- dbGetQuery(con, suspicious_patterns[[pattern_name]])
    count <- result$count[1]
    if (count == 0) {
      cat("✅", pattern_name, ": None found\n")
    } else {
      cat("⚠️ ", pattern_name, ":", count, "records\n")
    }
  }
  
  # Web frontend compatibility check
  cat("\n--- WEB FRONTEND COMPATIBILITY ---\n")
  
  # Check for records that would match common frontend filters
  frontend_tests <- list(
    "US records" = "SELECT COUNT(*) as count FROM recordings WHERE country IN ('US', 'United States')",
    "Folk records" = "SELECT COUNT(*) as count FROM recordings WHERE genre LIKE '%folk%' OR genre LIKE '%Folk%'",
    "Jazz records" = "SELECT COUNT(*) as count FROM recordings WHERE genre LIKE '%jazz%' OR genre LIKE '%Jazz%'",
    "Records with popularity scores" = "SELECT COUNT(*) as count FROM recordings WHERE popularity_score > 0"
  )
  
  for (test_name in names(frontend_tests)) {
    result <- dbGetQuery(con, frontend_tests[[test_name]])
    count <- result$count[1]
    cat(test_name, ":", count, "records\n")
  }
  
  # Final assessment
  cat("\n=== VALIDATION SUMMARY ===\n")
  
  total_records <- dbGetQuery(con, "SELECT COUNT(*) as count FROM recordings")$count
  
  if (total_records == 0) {
    cat("❌ CRITICAL: Database is empty\n")
    return(FALSE)
  } else if (total_records < 10) {
    cat("⚠️  WARNING: Very few records (", total_records, ") - collection may have failed\n")
  } else {
    cat("✅ Database contains", total_records, "records\n")
  }
  
  # Check if common search combinations would return results
  common_search <- dbGetQuery(con, paste0("
    SELECT COUNT(*) as count FROM recordings 
    WHERE year = ", target_year, "
    AND (country LIKE '%US%' OR country = 'US')
    AND genre IS NOT NULL
  "))
  
  if (common_search$count > 0) {
    cat("✅ Common searches should return results\n")
    return(TRUE)
  } else {
    cat("⚠️  Common searches may return no results\n")
    cat("   This explains frontend filtering issues\n")
    return(FALSE)
  }
}

# Run validation
validate_database_integrity()