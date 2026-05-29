-- Converted for SQLite
PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS events (
	event_id INTEGER PRIMARY KEY AUTOINCREMENT,
	datetime TEXT NOT NULL,
	lat REAL NOT NULL,
	lon REAL NOT NULL,
	tag TEXT,
	category TEXT,
	author_id INTEGER
);


