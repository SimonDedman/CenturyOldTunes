-- Century Old Tunes Database Schema
-- SQLite database for storing historical music recordings

-- Main recordings table
CREATE TABLE IF NOT EXISTS recordings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    artist TEXT NOT NULL,
    year INTEGER NOT NULL,
    release_date DATE,
    country TEXT,
    region TEXT,
    label TEXT,
    catalog_number TEXT,
    source_api TEXT NOT NULL,
    source_id TEXT,
    external_url TEXT,
    popularity_score REAL DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Genres table (many-to-many relationship)
CREATE TABLE IF NOT EXISTS genres (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    normalized_name TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Recording-Genre junction table
CREATE TABLE IF NOT EXISTS recording_genres (
    recording_id INTEGER,
    genre_id INTEGER,
    PRIMARY KEY (recording_id, genre_id),
    FOREIGN KEY (recording_id) REFERENCES recordings(id) ON DELETE CASCADE,
    FOREIGN KEY (genre_id) REFERENCES genres(id) ON DELETE CASCADE
);

-- Artists table (for normalized artist data)
CREATE TABLE IF NOT EXISTS artists (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    normalized_name TEXT,
    birth_year INTEGER,
    death_year INTEGER,
    country TEXT,
    wikidata_id TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Recording-Artist junction table (handles collaborations)
CREATE TABLE IF NOT EXISTS recording_artists (
    recording_id INTEGER,
    artist_id INTEGER,
    role TEXT DEFAULT 'performer',
    PRIMARY KEY (recording_id, artist_id, role),
    FOREIGN KEY (recording_id) REFERENCES recordings(id) ON DELETE CASCADE,
    FOREIGN KEY (artist_id) REFERENCES artists(id) ON DELETE CASCADE
);

-- Labels table
CREATE TABLE IF NOT EXISTS labels (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    country TEXT,
    founded_year INTEGER,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Update recordings table to reference labels
ALTER TABLE recordings ADD COLUMN label_id INTEGER REFERENCES labels(id);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_recordings_year ON recordings(year);
CREATE INDEX IF NOT EXISTS idx_recordings_country ON recordings(country);
CREATE INDEX IF NOT EXISTS idx_recordings_source ON recordings(source_api, source_id);
CREATE INDEX IF NOT EXISTS idx_recordings_artist ON recordings(artist);
CREATE INDEX IF NOT EXISTS idx_genres_normalized ON genres(normalized_name);
CREATE INDEX IF NOT EXISTS idx_artists_normalized ON artists(normalized_name);

-- Views for common queries
CREATE VIEW IF NOT EXISTS recordings_with_genres AS
SELECT 
    r.*,
    GROUP_CONCAT(g.name, ', ') as genres
FROM recordings r
LEFT JOIN recording_genres rg ON r.id = rg.recording_id
LEFT JOIN genres g ON rg.genre_id = g.id
GROUP BY r.id;

CREATE VIEW IF NOT EXISTS year_summary AS
SELECT 
    year,
    COUNT(*) as total_recordings,
    COUNT(DISTINCT country) as countries,
    COUNT(DISTINCT artist) as artists,
    AVG(popularity_score) as avg_popularity
FROM recordings 
GROUP BY year
ORDER BY year;

-- Sample data insert for testing
INSERT OR IGNORE INTO genres (name, normalized_name) VALUES 
    ('Jazz', 'jazz'),
    ('Blues', 'blues'),
    ('Classical', 'classical'),
    ('Folk', 'folk'),
    ('Popular', 'popular'),
    ('Ragtime', 'ragtime'),
    ('Dance', 'dance');

-- Sample labels for 1925 era
INSERT OR IGNORE INTO labels (name, country, founded_year) VALUES
    ('Victor Talking Machine Company', 'US', 1901),
    ('Columbia Records', 'US', 1887),
    ('Okeh Records', 'US', 1918),
    ('Brunswick Records', 'US', 1916),
    ('Gennett Records', 'US', 1917),
    ('Paramount Records', 'US', 1917);