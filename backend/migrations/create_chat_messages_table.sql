CREATE TABLE IF NOT EXISTS chat_messages (
    message_id SERIAL PRIMARY KEY,
    session_id INTEGER NOT NULL,
    npc_name VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    is_npc BOOLEAN NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_chat_session_npc ON chat_messages(session_id, npc_name); 