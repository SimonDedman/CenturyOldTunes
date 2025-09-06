# Discogs API integration for Century Old Tunes

library(httr)
library(jsonlite)

# Discogs API functions
search_discogs <- function(year, page = 1, per_page = 100) {
  base_url <- "https://api.discogs.com/database/search"
  
  # Add required headers including authentication token
  headers <- add_headers(
    "User-Agent" = "CenturyOldTunes/1.0 +https://github.com/SimonDedman/CenturyOldTunes",
    "Authorization" = "Discogs token=mCSmKbIxbBHPsMeGdnDoLhehLyhwoJLcasuUENEN"
  )
  
  params <- list(
    year = year,
    type = "release",
    page = page,
    per_page = per_page
  )
  
  response <- GET(base_url, query = params, headers)
  
  if (status_code(response) == 200) {
    data <- fromJSON(content(response, "text"), flatten = TRUE)
    return(data$results)
  } else {
    warning("Discogs API request failed with status:", status_code(response))
    return(NULL)
  }
}

# Parse Discogs response into standardized format
parse_discogs_result <- function(discogs_data) {
  if (is.null(discogs_data) || nrow(discogs_data) == 0) {
    return(data.frame())
  }
  
  # Clean and validate data to prevent NULL constraint errors
  clean_text <- function(x, default = "Unknown") {
    if (is.null(x) || length(x) == 0) {
      return(default)
    }
    # Handle vectors
    result <- ifelse(is.na(x) | x == "", default, as.character(x))
    return(result)
  }
  
  clean_list <- function(x, default = "Unknown") {
    if (is.null(x) || length(x) == 0) {
      return(default)
    }
    result <- paste(x, collapse = ", ")
    return(ifelse(result == "" || is.na(result), default, result))
  }
  
  # Get the number of records and ensure all fields match this length
  n_records <- nrow(discogs_data)
  
  # Helper function to ensure consistent length
  ensure_length <- function(field, n, default_val = "") {
    if (is.null(field) || length(field) == 0) {
      return(rep(default_val, n))
    } else if (length(field) < n) {
      return(c(field, rep(default_val, n - length(field))))
    } else if (length(field) > n) {
      return(field[1:n])
    } else {
      return(field)
    }
  }
  
  # Process each field safely
  titles <- ensure_length(discogs_data$title, n_records, "Unknown Title")
  artists <- ensure_length(discogs_data$artist, n_records, "Unknown Artist")
  years <- ensure_length(discogs_data$year, n_records, 1925)
  countries <- ensure_length(discogs_data$country, n_records, "")
  
  # Handle list fields (genre, label) specially
  genres <- if (!is.null(discogs_data$genre)) {
    sapply(1:n_records, function(i) {
      if (i <= length(discogs_data$genre) && !is.null(discogs_data$genre[[i]])) {
        paste(discogs_data$genre[[i]], collapse = ", ")
      } else {
        ""
      }
    })
  } else {
    rep("", n_records)
  }
  
  labels <- if (!is.null(discogs_data$label)) {
    sapply(1:n_records, function(i) {
      if (i <= length(discogs_data$label) && !is.null(discogs_data$label[[i]])) {
        paste(discogs_data$label[[i]], collapse = ", ")
      } else {
        ""
      }
    })
  } else {
    rep("", n_records)
  }
  
  ids <- ensure_length(discogs_data$id, n_records, "")
  
  parsed <- data.frame(
    title = clean_text(titles, "Unknown Title"),
    artist = clean_text(artists, "Unknown Artist"),
    year = as.numeric(years),
    country = clean_text(countries, ""),
    genre = clean_text(genres, ""),
    label = clean_text(labels, ""),
    source_api = rep("discogs", n_records),
    source_id = clean_text(ids, ""),
    stringsAsFactors = FALSE
  )
  
  return(parsed)
}

# Null coalescing operator
`%||%` <- function(a, b) if (is.null(a) || length(a) == 0) b else a