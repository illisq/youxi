CREATE TABLE IF NOT EXISTS player_status (
    player_character_id INTEGER PRIMARY KEY REFERENCES player_characters(player_character_id),
    sanity_value INTEGER DEFAULT 100,
    alienation_value INTEGER DEFAULT 0,
    chen_influence INTEGER DEFAULT 0,
    liu_influence INTEGER DEFAULT 0,
    discovered_secrets TEXT[] DEFAULT ARRAY[]::TEXT[],
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
); 