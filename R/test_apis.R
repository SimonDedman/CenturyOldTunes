# API Connection Testing Script for Century Old Tunes

library(httr)
library(jsonlite)

# Source API scripts
source("R/discogs_api.R")
source("R/musicbrainz_api.R")

test_api_connections <- function() {
  cat("=== API CONNECTION TESTING ===\n")
  cat("Timestamp:", Sys.time(), "\n\n")
  
  # Test Discogs API
  cat("--- DISCOGS API TEST ---\n")
  
  tryCatch({
    # Test basic connection
    cat("Testing Discogs API authentication...\n")
    test_response <- GET(
      "https://api.discogs.com/oauth/identity",
      add_headers(
        "User-Agent" = "CenturyOldTunes/1.0 +https://github.com/SimonDedman/CenturyOldTunes",
        "Authorization" = "Discogs token=mCSmKbIxbBHPsMeGdnDoLhehLyhwoJLcasuUENEN"
      )
    )
    
    if (status_code(test_response) == 200) {
      user_info <- fromJSON(content(test_response, "text"))
      cat("✅ Discogs authentication successful\n")
      cat("   User:", user_info$username, "\n")
      cat("   Rate limit remaining:", headers(test_response)$`x-discogs-ratelimit-remaining` %||% "Unknown", "\n")
    } else {
      cat("❌ Discogs authentication failed\n")
      cat("   Status code:", status_code(test_response), "\n")
      cat("   Response:", content(test_response, "text"), "\n")
    }
    
    # Test search functionality
    cat("\nTesting Discogs search for 1925...\n")
    search_results <- search_discogs(1925, per_page = 3)
    
    if (!is.null(search_results) && length(search_results) > 0) {
      cat("✅ Discogs search working\n")
      cat("   Found", length(search_results), "sample results\n")
      
      # Test parsing
      parsed_results <- parse_discogs_result(search_results)
      cat("   Parsed", nrow(parsed_results), "records successfully\n")
      
      if (nrow(parsed_results) > 0) {
        cat("   Sample record:\n")
        sample <- parsed_results[1, ]
        cat("     Title:", sample$title %||% "Unknown", "\n")
        cat("     Artist:", sample$artist %||% "Unknown", "\n")
        cat("     Country:", sample$country %||% "Unknown", "\n")
        cat("     Genre:", sample$genre %||% "Unknown", "\n")
      }
    } else {
      cat("❌ Discogs search failed or returned no results\n")
    }
    
  }, error = function(e) {
    cat("❌ Discogs API error:", e$message, "\n")
  })
  
  cat("\n")
  
  # Test MusicBrainz API
  cat("--- MUSICBRAINZ API TEST ---\n")
  
  tryCatch({
    # Test basic connection
    cat("Testing MusicBrainz API connection...\n")
    test_response <- GET(
      "https://musicbrainz.org/ws/2/artist/5b11f4ce-a62d-471e-81fc-a69a8278c7da",
      query = list(fmt = "json"),
      add_headers("User-Agent" = "CenturyOldTunes/1.0 ( simon@example.com )")
    )
    
    if (status_code(test_response) == 200) {
      cat("✅ MusicBrainz API accessible\n")
      rate_limit <- headers(test_response)$`x-ratelimit-remaining`
      if (!is.null(rate_limit)) {
        cat("   Rate limit remaining:", rate_limit, "\n")
      }
    } else {
      cat("❌ MusicBrainz API connection failed\n")
      cat("   Status code:", status_code(test_response), "\n")
    }
    
    # Test search functionality
    cat("\nTesting MusicBrainz search for 1925...\n")
    mb_results <- search_musicbrainz(1925, limit = 3)
    
    if (!is.null(mb_results) && nrow(mb_results) > 0) {
      cat("✅ MusicBrainz search working\n")
      cat("   Found", nrow(mb_results), "sample results\n")
      
      # Test parsing
      parsed_mb <- parse_musicbrainz_result(mb_results)
      cat("   Parsed", nrow(parsed_mb), "records successfully\n")
      
      if (nrow(parsed_mb) > 0) {
        cat("   Sample record:\n")
        sample <- parsed_mb[1, ]
        cat("     Title:", sample$title %||% "Unknown", "\n")
        cat("     Artist:", sample$artist %||% "Unknown", "\n")
        cat("     Country:", sample$country %||% "Unknown", "\n")
      }
    } else {
      cat("❌ MusicBrainz search failed or returned no results\n")
    }
    
  }, error = function(e) {
    cat("❌ MusicBrainz API error:", e$message, "\n")
  })
  
  # Test specific searches for folk music
  cat("\n--- FOLK MUSIC SPECIFIC TESTS ---\n")
  
  # Test Discogs folk search
  tryCatch({
    cat("Testing Discogs search for 1925 folk music...\n")
    folk_search <- GET(
      "https://api.discogs.com/database/search",
      query = list(
        year = 1925,
        type = "release",
        genre = "Folk",
        per_page = 5
      ),
      add_headers(
        "User-Agent" = "CenturyOldTunes/1.0 +https://github.com/SimonDedman/CenturyOldTunes",
        "Authorization" = "Discogs token=mCSmKbIxbBHPsMeGdnDoLhehLyhwoJLcasuUENEN"
      )
    )
    
    if (status_code(folk_search) == 200) {
      folk_data <- fromJSON(content(folk_search, "text"))
      cat("   Found", folk_data$pagination$items %||% 0, "folk records from 1925\n")
      
      if ((folk_data$pagination$items %||% 0) > 0) {
        cat("✅ Folk music data available from Discogs\n")
        if (length(folk_data$results) > 0) {
          sample_folk <- folk_data$results[1, ]
          cat("   Sample: '", sample_folk$title %||% "Unknown", "' by ", sample_folk$artist %||% "Unknown", "\n")
        }
      } else {
        cat("⚠️  No specific folk genre records found for 1925\n")
        cat("   (This might explain the frontend issue)\n")
      }
    }
    
  }, error = function(e) {
    cat("❌ Folk music search error:", e$message, "\n")
  })
  
  cat("\n=== API TEST SUMMARY ===\n")
  cat("If APIs are working but no folk records found, consider:\n")
  cat("1. Searching broader genres (Country, Blues, Traditional)\n")
  cat("2. Different search terms (hillbilly, old-time, ballad)\n")
  cat("3. Checking if 1925 had limited commercial folk recordings\n")
  cat("4. Expanding to adjacent years (1924-1926)\n")
}

# Null coalescing operator
`%||%` <- function(a, b) if (is.null(a) || length(a) == 0 || is.na(a)) b else a

# Run tests
test_api_connections()