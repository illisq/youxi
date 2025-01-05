-- 添加 player_character_id 列
ALTER TABLE game_sessions 
ADD COLUMN player_character_id INTEGER;

-- 添加外键约束
ALTER TABLE game_sessions
ADD CONSTRAINT fk_game_sessions_player_character
FOREIGN KEY (player_character_id)
REFERENCES player_characters (player_character_id);

-- 添加反向关系（如果需要的话）
ALTER TABLE player_characters
ADD COLUMN game_session_id INTEGER REFERENCES game_sessions(id); 