from sqlalchemy import Column, Integer, String, Text, JSON, Boolean, DateTime, ForeignKey, Float
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from database import Base

class Module(Base):
    __tablename__ = "modules"
    
    module_id = Column(Integer, primary_key=True)
    title = Column(String(100))
    description = Column(Text)
    player_min = Column(Integer, default=3)
    player_max = Column(Integer, default=5)
    duration_hours = Column(Integer, default=8)
    difficulty = Column(String(20), default='medium')
    theme = Column(String(100))
    create_time = Column(DateTime(timezone=True), server_default=func.now())
    cover_image_url = Column(String(255))

    # 关系
    characters = relationship("Character", back_populates="module")
    professions = relationship("Profession", back_populates="module")
    game_phases = relationship("GamePhase", back_populates="module")
    secrets = relationship("Secret", back_populates="module")
    ending_conditions = relationship("EndingCondition", back_populates="module")
    game_sessions = relationship("GameSession", back_populates="module")
    game_actions = relationship("GameAction", back_populates="module")

class Character(Base):
    __tablename__ = "characters"
    
    character_id = Column(Integer, primary_key=True)
    module_id = Column(Integer, ForeignKey('modules.module_id'))
    name = Column(String(100))
    position = Column(String(50))
    faction = Column(String(50))
    avatar_url = Column(String(255))
    background = Column(Text)
    personality = Column(Text)
    initial_attitude = Column(Integer, default=50)
    secret_level = Column(Integer)
    chat_prompt = Column(Text)

    # 关系
    module = relationship("Module", back_populates="characters")
    secrets = relationship("Secret", back_populates="character")
    dialogues = relationship("DialogueHistory", back_populates="character")

class Profession(Base):
    __tablename__ = "professions"
    
    profession_id = Column(Integer, primary_key=True)
    module_id = Column(Integer, ForeignKey('modules.module_id'))
    name = Column(String(50))
    description = Column(Text)
    initial_skills = Column(JSON)
    special_abilities = Column(Text)
    starting_items = Column(JSON)

    # 关系
    module = relationship("Module", back_populates="professions")
    game_sessions = relationship("GameSession", back_populates="profession")

class GamePhase(Base):
    __tablename__ = "game_phases"
    
    phase_id = Column(Integer, primary_key=True)
    module_id = Column(Integer, ForeignKey('modules.module_id'))
    phase_name = Column(String(100))
    phase_order = Column(Integer)
    description = Column(Text)
    required_progress = Column(Integer)
    unlock_conditions = Column(JSON)
    available_actions = Column(JSON)

    # 关系
    module = relationship("Module", back_populates="game_phases")
    game_sessions = relationship("GameSession", back_populates="current_phase")

class Secret(Base):
    __tablename__ = "secrets"
    
    secret_id = Column(Integer, primary_key=True)
    module_id = Column(Integer, ForeignKey('modules.module_id'))
    related_character_id = Column(Integer, ForeignKey('characters.character_id'))
    secret_type = Column(String(50))
    content = Column(Text)
    sanity_loss = Column(Integer)
    alienation_increase = Column(Integer)
    discovery_difficulty = Column(Integer)
    keywords = Column(JSON)
    unlock_conditions = Column(JSON)

    # 关系
    module = relationship("Module", back_populates="secrets")
    character = relationship("Character", back_populates="secrets")

class EndingCondition(Base):
    __tablename__ = "ending_conditions"
    
    ending_id = Column(Integer, primary_key=True)
    module_id = Column(Integer, ForeignKey('modules.module_id'))
    ending_name = Column(String(100))
    ending_description = Column(Text)
    required_sanity_range = Column(JSON)
    required_alienation_range = Column(JSON)
    required_faction_influence = Column(JSON)
    required_secrets = Column(JSON)
    required_actions = Column(JSON)
    ending_script = Column(Text)

    # 关系
    module = relationship("Module", back_populates="ending_conditions")

class GameSession(Base):
    __tablename__ = "game_sessions"
    
    session_id = Column(Integer, primary_key=True)
    module_id = Column(Integer, ForeignKey('modules.module_id'))
    player_id = Column(Integer)
    profession_id = Column(Integer, ForeignKey('professions.profession_id'))
    current_phase_id = Column(Integer, ForeignKey('game_phases.phase_id'))
    sanity_value = Column(Integer, default=100)
    alienation_value = Column(Integer, default=0)
    chen_influence = Column(Integer, default=50)
    liu_influence = Column(Integer, default=50)
    discovered_secrets = Column(JSON)
    completed_actions = Column(JSON)
    session_status = Column(String(20))
    start_time = Column(DateTime(timezone=True), server_default=func.now())
    last_save_time = Column(DateTime(timezone=True), onupdate=func.now())

    # 关系
    module = relationship("Module", back_populates="game_sessions")
    profession = relationship("Profession", back_populates="game_sessions")
    current_phase = relationship("GamePhase", back_populates="game_sessions")
    monitoring_events = relationship("MonitoringEvent", back_populates="session")
    dialogues = relationship("DialogueHistory", back_populates="session")

class GameAction(Base):
    __tablename__ = "game_actions"
    
    action_id = Column(Integer, primary_key=True)
    module_id = Column(Integer, ForeignKey('modules.module_id'))
    action_name = Column(String(100))
    action_type = Column(String(50))
    description = Column(Text)
    risk_level = Column(Integer)
    detection_chance = Column(Integer)
    sanity_effect = Column(Integer)
    alienation_effect = Column(Integer)
    influence_effects = Column(JSON)
    required_skills = Column(JSON)
    success_outcome = Column(Text)
    failure_outcome = Column(Text)

    # 关系
    module = relationship("Module", back_populates="game_actions")
    monitoring_events = relationship("MonitoringEvent", back_populates="action")

class MonitoringEvent(Base):
    __tablename__ = "monitoring_events"
    
    event_id = Column(Integer, primary_key=True)
    session_id = Column(Integer, ForeignKey('game_sessions.session_id'))
    action_id = Column(Integer, ForeignKey('game_actions.action_id'))
    detection_roll = Column(Integer)
    was_detected = Column(Boolean)
    consequence_type = Column(String(50))
    consequence_description = Column(Text)
    event_time = Column(DateTime(timezone=True), server_default=func.now())

    # 关系
    session = relationship("GameSession", back_populates="monitoring_events")
    action = relationship("GameAction", back_populates="monitoring_events")

class DialogueHistory(Base):
    __tablename__ = "dialogue_history"
    
    dialogue_id = Column(Integer, primary_key=True)
    session_id = Column(Integer, ForeignKey('game_sessions.session_id'))
    character_id = Column(Integer, ForeignKey('characters.character_id'))
    dialogue_content = Column(Text)
    player_response = Column(Text)
    discovered_secrets = Column(JSON)
    influence_changes = Column(JSON)
    dialogue_time = Column(DateTime(timezone=True), server_default=func.now())

    # 关系
    session = relationship("GameSession", back_populates="dialogues")
    character = relationship("Character", back_populates="dialogues") 