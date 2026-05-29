-- Converted for SQLite
PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS events (
	event_id INTEGER PRIMARY KEY AUTOINCREMENT,
	start_datetime TEXT NOT NULL,
	end_datetime TEXT NOT NULL,
	lat REAL NOT NULL,
	lon REAL NOT NULL,
	title TEXT,
	tag TEXT,
	description TEXT,
	category TEXT,
	author TEXT
);


