# Century Old Tunes - R Scripts

## Main Scripts

### `runscript.R` - **Main Execution Script**
The primary script to run for data collection. Execute with:
```r
source("R/runscript.R")
```
Or in non-interactive mode:
```bash
Rscript R/runscript.R
```

**What it does:**
- Installs required packages
- Sets up database schema
- Collects data from Discogs and MusicBrainz APIs
- Stores data in SQLite database
- Runs verification automatically

## API Modules

### `discogs_api.R`
- Discogs API integration with authentication
- Search and parse Discogs releases from 1925
- Handles data cleaning and validation

### `musicbrainz_api.R`  
- MusicBrainz API integration with rate limiting
- Search and parse MusicBrainz releases from 1925
- Error handling for missing fields

## Verification & Testing Scripts

### `verify_collection.R`
Comprehensive verification of data collection results:
- Database structure analysis
- Data quality checks
- Country/genre/source breakdowns
- Frontend compatibility testing

### `test_apis.R`
API connection testing:
- Authentication verification
- Rate limit checking
- Sample data retrieval
- Folk music availability testing

### `validate_database.R`
Database integrity validation:
- File integrity checks
- Constraint validation
- Duplicate detection
- Statistical analysis

### `check_database.R`
Simple database content checker:
- Record counts
- Sample data display
- Basic breakdowns by field

## Usage Workflow

1. **Basic collection:** `source("R/runscript.R")`
2. **Verify results:** `source("R/verify_collection.R")`  
3. **Test APIs:** `source("R/test_apis.R")` (if issues)
4. **Deep validation:** `source("R/validate_database.R")` (if needed)

## Configuration

- **Target Year:** Automatically calculated as current year - 100
- **API Credentials:** Discogs token in `discogs_api.R`
- **Database:** SQLite file at `db/century_old_tunes.sqlite`
- **Rate Limits:** 1 req/sec for MusicBrainz, standard for Discogs