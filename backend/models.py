from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey, Boolean, JSON
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
from datetime import datetime

Base = declarative_base()

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True)
    email = Column(String, unique=True, index=True)
    password = Column(String)
    created_at = Column(DateTime, default=datetime.utcnow)

class GameSession(Base):
    __tablename__ = "game_sessions"
    
    id = Column(Integer, primary_key=True, index=True)
    module_id = Column(Integer, ForeignKey("modules.module_id"))
    created_at = Column(DateTime, default=datetime.utcnow)
    status = Column(String)
    current_phase = Column(String)
    
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
    
    def get_npc_response(self, npc_name: str, user_message: str, db_session) -> dict:
        return {
            "content": user_message,
            "timestamp": datetime.utcnow(),
            "is_npc": False
        }
    
    def get_npc_chat_history(self, npc_name: str) -> list:
        return []

class Module(Base):
    __tablename__ = "modules"
    
    module_id = Column(Integer, primary_key=True, index=True)
    title = Column(String)
    description = Column(Text)
    player_min = Column(Integer)
    player_max = Column(Integer)
    duration_hours = Column(Integer)
    difficulty = Column(String)
    create_time = Column(DateTime, default=datetime.utcnow)

class Character(Base):
    __tablename__ = "characters"
    
    character_id = Column(Integer, primary_key=True, index=True)
    module_id = Column(Integer, ForeignKey("modules.module_id"))
    name = Column(String)
    position = Column(String)
    faction = Column(String)
    background = Column(Text)
    personality = Column(Text)
    initial_attitude = Column(Integer)
    secret_level = Column(Integer)
    chat_prompt = Column(Text)

class Profession(Base):
    __tablename__ = "professions"
    
    profession_id = Column(Integer, primary_key=True, index=True)
    module_id = Column(Integer, ForeignKey("modules.module_id"))
    name = Column(String)
    description = Column(Text)
    initial_skills = Column(JSON)

class PlayerCharacter(Base):
    __tablename__ = "player_characters"
    
    player_character_id = Column(Integer, primary_key=True, index=True)
    player_id = Column(Integer, ForeignKey("users.id"))
    module_id = Column(Integer, ForeignKey("modules.module_id"))
    profession_id = Column(Integer, ForeignKey("professions.profession_id"))
    current_sanity = Column(Integer, default=100)
    current_alienation = Column(Integer, default=0)
    inventory = Column(JSON, default={})
    completed_phases = Column(JSON, default={})
    current_status = Column(String, default="active")
    creation_time = Column(DateTime, default=datetime.utcnow)
    avatar_url = Column(String)

class ChatMessage(Base):
    __tablename__ = "chat_messages"
    
    message_id = Column(Integer, primary_key=True, index=True)
    session_id = Column(Integer, nullable=False)
    npc_name = Column(String, nullable=False)
    content = Column(Text, nullable=False)
    is_npc = Column(Boolean, nullable=False)
    timestamp = Column(DateTime, default=datetime.utcnow) 

class PlayerStatus(Base):
    __tablename__ = "player_status"
    
    status_id = Column(Integer, primary_key=True)
    session_id = Column(Integer, ForeignKey("game_sessions.session_id"))
    sanity_value = Column(Integer, default=100)
    alienation_value = Column(Integer, default=0)
    chen_influence = Column(Integer, default=50)
    liu_influence = Column(Integer, default=50)
    discovered_secrets = Column(JSON, default=list)
    completed_actions = Column(JSON, default=list)
    last_update = Column(DateTime, default=datetime.utcnow)

class GameEvent(Base):
    __tablename__ = "game_events"
    
    event_id = Column(Integer, primary_key=True)
    session_id = Column(Integer, ForeignKey("game_sessions.session_id"))
    event_type = Column(String(50))  # investigation, dialogue, ritual_participation 等
    event_data = Column(JSON)
    created_at = Column(DateTime, default=datetime.utcnow) 