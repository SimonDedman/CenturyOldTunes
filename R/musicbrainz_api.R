# MusicBrainz API integration for Century Old Tunes

library(httr)
library(jsonlite)

# MusicBrainz API functions
search_musicbrainz <- function(year, limit = 100, offset = 0) {
  base_url <- "https://musicbrainz.org/ws/2/release"
  
  # MusicBrainz requires User-Agent and rate limiting (1 request/second)
  headers <- add_headers(
    "User-Agent" = "CenturyOldTunes/1.0 ( simon@example.com )"
  )
  
  # Search for releases from specific year
  query <- paste0("date:", year)
  
  params <- list(
    query = query,
    fmt = "json",
    limit = limit,
    offset = offset
  )
  
  # Rate limiting - MusicBrainz allows 1 request per second
  Sys.sleep(1)
  
  response <- GET(base_url, query = params, headers)
  
  if (status_code(response) == 200) {
    data <- fromJSON(content(response, "text"), flatten = TRUE)
    return(data$releases)
  } else {
    warning("MusicBrainz API request failed with status:", status_code(response))
    return(NULL)
  }
}

# Parse MusicBrainz response into standardized format
parse_musicbrainz_result <- function(mb_data) {
  if (is.null(mb_data) || nrow(mb_data) == 0) {
    return(data.frame())
  }
  
  # Extract artist names from artist-credit
  get_artist_name <- function(artist_credit) {
    if (is.null(artist_credit) || length(artist_credit) == 0) return("Unknown Artist")
    
    tryCatch({
      if (is.list(artist_credit)) {
        names <- sapply(artist_credit, function(x) {
          if (is.list(x) && "artist" %in% names(x)) {
            return(x$artist$name %||% x$name %||% "Unknown")
          } else if (is.list(x) && "name" %in% names(x)) {
            return(x$name %||% "Unknown")
          } else {
            return(as.character(x) %||% "Unknown")
          }
        })
        result <- paste(names[!is.na(names) & names != ""], collapse = ", ")
        return(ifelse(result == "", "Unknown Artist", result))
      }
      return(as.character(artist_credit))
    }, error = function(e) {
      return("Unknown Artist")
    })
  }
  
  # Clean data helper function
  clean_text <- function(x, default = "Unknown") {
    if (is.null(x) || length(x) == 0 || is.na(x) || x == "") {
      return(default)
    }
    return(as.character(x))
  }
  
  parsed <- data.frame(
    title = sapply(mb_data$title, function(x) clean_text(x, "Unknown Title")),
    artist = sapply(mb_data$`artist-credit`, get_artist_name),
    year = as.numeric(substr(mb_data$date %||% "1925", 1, 4)),
    country = sapply(mb_data$country, function(x) clean_text(x, "")),
    genre = "",  # MusicBrainz doesn't always have genre in release data
    label = sapply(mb_data$`label-info`, function(x) {
      if (!is.null(x) && is.data.frame(x) && nrow(x) > 0 && "label" %in% names(x)) {
        return(clean_text(x$label$name[1], ""))
      } else {
        return("")
      }
    }),
    source_api = "musicbrainz",
    source_id = sapply(mb_data$id, function(x) clean_text(x, "")),
    stringsAsFactors = FALSE
  )
  
  return(parsed)
}

# Get additional metadata for a release (including genres)
get_musicbrainz_release_details <- function(release_id) {
  url <- paste0("https://musicbrainz.org/ws/2/release/", release_id)
  params <- list(fmt = "json", inc = "genres+tags+artist-credits+labels")
  
  headers <- add_headers(
    "User-Agent" = "CenturyOldTunes/1.0 ( simon@example.com )"
  )
  
  Sys.sleep(1)  # Rate limiting
  
  response <- GET(url, query = params, headers)
  
  if (status_code(response) == 200) {
    return(fromJSON(content(response, "text"), flatten = TRUE))
  }
  
  return(NULL)
}