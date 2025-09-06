# Check what's actually in the SQLite database

library(RSQLite)
library(DBI)

# Connect to database
con <- dbConnect(SQLite(), "db/century_old_tunes.sqlite")

cat("=== DATABASE CONTENTS ===\n")

# Check if recordings table exists and has data
if (dbExistsTable(con, "recordings")) {
  total_records <- dbGetQuery(con, "SELECT COUNT(*) as count FROM recordings")
  cat("Total recordings in database:", total_records$count, "\n\n")
  
  if (total_records$count > 0) {
    # Show first few records
    cat("--- First 10 recordings ---\n")
    sample_records <- dbGetQuery(con, "SELECT * FROM recordings LIMIT 10")
    print(sample_records)
    
    # Show breakdown by country
    cat("\n--- Records by Country ---\n")
    country_breakdown <- dbGetQuery(con, "SELECT country, COUNT(*) as count FROM recordings GROUP BY country ORDER BY count DESC")
    print(country_breakdown)
    
    # Show breakdown by genre
    cat("\n--- Records by Genre ---\n")
    genre_breakdown <- dbGetQuery(con, "SELECT genre, COUNT(*) as count FROM recordings GROUP BY genre ORDER BY count DESC")
    print(genre_breakdown)
    
    # Show breakdown by source API
    cat("\n--- Records by Source API ---\n")
    source_breakdown <- dbGetQuery(con, "SELECT source_api, COUNT(*) as count FROM recordings GROUP BY source_api ORDER BY count DESC")
    print(source_breakdown)
    
    # Look specifically for US folk records
    cat("\n--- US Folk Records ---\n")
    us_folk <- dbGetQuery(con, "SELECT * FROM recordings WHERE country LIKE '%US%' AND genre LIKE '%folk%'")
    if (nrow(us_folk) > 0) {
      print(us_folk)
    } else {
      cat("No US folk records found in database\n")
      
      # Check what US records we have
      cat("\n--- All US Records (first 10) ---\n")
      us_records <- dbGetQuery(con, "SELECT title, artist, country, genre FROM recordings WHERE country LIKE '%US%' LIMIT 10")
      if (nrow(us_records) > 0) {
        print(us_records)
      } else {
        cat("No US records found at all\n")
      }
    }
    
  } else {
    cat("No records found in database\n")
  }
} else {
  cat("Recordings table does not exist\n")
}

# List all tables
cat("\n--- All Tables in Database ---\n")
tables <- dbListTables(con)
print(tables)

dbDisconnect(con)