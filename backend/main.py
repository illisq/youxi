from dotenv import load_dotenv
load_dotenv()  # 加载 .env 文件中的环境变量
from fastapi import FastAPI, Depends, HTTPException, status, UploadFile, File, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from typing import List, Optional
from pydantic import BaseModel
from sqlalchemy.orm import Session
from database import get_db_connection, SessionLocal, engine
import schemas
from models import (
    Module, 
    Character, 
    Profession, 
    EndingCondition, 
    GameSession,
    PlayerCharacter,
    PlayerStatus
)
import json
import os
import shutil
from datetime import datetime
from services.ai_service import AIService
from services.ending_service import EndingService
import random
from schemas import EndingSchema
from sqlalchemy import text

app = FastAPI(
    title="TRPG API",
    description="TRPG game backend API",
    version="1.0.0"
)

# 配置CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 依赖项
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@app.post("/users/", response_model=schemas.User)
def create_user(user: schemas.UserCreate, db: Session = Depends(get_db)):
    db_user = models.User(
        username=user.username,
        email=user.email,
        password=user.password  # 注意：实际应用中应该对密码进行哈希处理
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

@app.get("/users/", response_model=List[schemas.User])
def read_users(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    users = db.query(models.User).offset(skip).limit(limit).all()
    return users

@app.get("/users/{user_id}", response_model=schemas.User)
def read_user(user_id: int, db: Session = Depends(get_db)):
    db_user = db.query(models.User).filter(models.User.id == user_id).first()
    if db_user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return db_user 

@app.get("/")
async def root():
    return {
        "message": "Welcome to TRPG API",
        "version": "1.0.0",
        "endpoints": {
            "users": "/users/",
            "docs": "/docs",
            "redoc": "/redoc"
        }
    }

# 添加错误处理
@app.exception_handler(HTTPException)
async def http_exception_handler(request, exc):
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": exc.detail}
    ) 

# 添加新的 Pydantic 模型
class ProfessionCreate(BaseModel):
    name: str
    description: str
    initial_skills: Optional[str] = None

class CharacterCreate(BaseModel):
    name: str
    position: Optional[str] = None
    faction: Optional[str] = None
    background: Optional[str] = None
    personality: Optional[str] = None
    initial_attitude: Optional[int] = 0
    secret_level: Optional[int] = 0
    chat_prompt: Optional[str] = None

class EndingCreate(BaseModel):
    ending_name: str
    ending_description: str

class ModuleCreate(BaseModel):
    title: str
    description: str
    player_min: int = 3
    player_max: int = 5
    duration_hours: int = 8
    difficulty: str = 'medium'
    professions: List[ProfessionCreate] = []
    npcs: List[CharacterCreate] = []     # 保持字段名为 npcs 以兼容前端
    endings: List[EndingCreate] = []

class PlayerBase(BaseModel):
    username: str
    email: str
    bio: Optional[str] = None
    profile_image_url: Optional[str] = None

class PlayerCreate(PlayerBase):
    password: str

class PlayerResponse(PlayerBase):
    player_id: int
    total_play_time: int = 0
    created_at: Optional[str] = None
    last_login: Optional[str] = None
    achievements: Optional[dict] = {}

class PlayerCharacterBase(BaseModel):
    module_id: int
    profession_id: int
    current_sanity: Optional[int] = 100
    current_alienation: Optional[int] = 0
    inventory: Optional[dict] = {}
    completed_phases: Optional[dict] = {}
    current_status: Optional[str] = "active"

class PlayerCharacterCreate(PlayerCharacterBase):
    player_id: int

class PlayerCharacterResponse(PlayerCharacterBase):
    player_character_id: int
    creation_time: str

class SimpleCharacterCreate(BaseModel):
    module_id: int
    profession_id: int

# 添加新的 Pydantic 模型用于类型检查
class EndingResponse(BaseModel):
    ending_id: int
    name: str
    description: str

class PlayerStatusResponse(BaseModel):
    sanity: float
    alienation: float
    chen_influence: float
    liu_influence: float
    discovered_secrets: List[str]

class CheckEndingResponse(BaseModel):
    has_ending: bool
    endings: List[EndingResponse]
    current_status: PlayerStatusResponse

# 模组相关路由
@app.get("/modules/", response_model=List[dict])
async def get_modules():
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("""
            SELECT module_id, title, description, player_min, player_max, 
                   duration_hours, difficulty, create_time 
            FROM modules
            ORDER BY module_id
        """)
        modules = cursor.fetchall()
        return [{
            "module_id": row[0],
            "title": row[1],
            "description": row[2],
            "player_min": row[3],
            "player_max": row[4],
            "duration_hours": row[5],
            "difficulty": row[6],
            "create_time": row[7]
        } for row in modules]
    except Exception as e:
        print(f"Error fetching modules: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        cursor.close()
        conn.close()

@app.get("/modules/{module_id}", response_model=dict)
async def get_module_detail(module_id: int):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        # 获取模组基本信息
        cursor.execute("""
            SELECT module_id, title, description, player_min, player_max,
                   duration_hours, difficulty, theme, cover_image_url
            FROM modules
            WHERE module_id = %s
        """, (module_id,))
        
        module = cursor.fetchone()
        if not module:
            raise HTTPException(status_code=404, detail="Module not found")
        
        # 获取角色信息
        cursor.execute("""
            SELECT character_id, name, faction, position, avatar_url
            FROM characters
            WHERE module_id = %s
        """, (module_id,))
        characters = cursor.fetchall()
        
        # 获取职业信息
        cursor.execute("""
            SELECT profession_id, name, description, initial_skills
            FROM professions
            WHERE module_id = %s
        """, (module_id,))
        professions = cursor.fetchall()
        
        return {
            "module_id": module[0],
            "title": module[1],
            "description": module[2],
            "player_min": module[3],
            "player_max": module[4],
            "duration_hours": module[5],
            "difficulty": module[6],
            "theme": module[7],
            "cover_image_url": module[8],
            "characters": [
                {
                    "character_id": c[0],
                    "name": c[1],
                    "faction": c[2],
                    "position": c[3],
                    "avatar_url": c[4]
                } for c in characters
            ],
            "professions": [
                {
                    "profession_id": p[0],
                    "name": p[1],
                    "description": p[2],
                    "initial_skills": p[3]
                } for p in professions
            ]
        }
    except Exception as e:
        print(f"Error fetching module detail: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        cursor.close()
        conn.close()

@app.post("/modules/")
async def create_module(module: ModuleCreate):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        # 获取最大的 module_id
        cursor.execute("SELECT COALESCE(MAX(module_id), 0) FROM modules")
        max_id = cursor.fetchone()[0]
        new_id = max_id + 1

        # 插入模组基本信息
        cursor.execute("""
            INSERT INTO modules (module_id, title, description, player_min, player_max, 
                               duration_hours, difficulty, create_time)
            VALUES (%s, %s, %s, %s, %s, %s, %s, CURRENT_TIMESTAMP)
            RETURNING module_id, title, description
        """, (new_id, module.title, module.description, module.player_min,
              module.player_max, module.duration_hours, module.difficulty))
        
        new_module = cursor.fetchone()
        
        # 处理职业信息
        cursor.execute("SELECT COALESCE(MAX(profession_id), 0) FROM professions")
        max_prof_id = cursor.fetchone()[0]
        professions_data = []
        for idx, profession in enumerate(module.professions, 1):
            prof_id = max_prof_id + idx
            cursor.execute("""
                INSERT INTO professions (profession_id, module_id, name, description, initial_skills)
                VALUES (%s, %s, %s, %s, %s)
                RETURNING profession_id, name, description
            """, (prof_id, new_id, profession.name, profession.description, profession.initial_skills))
            prof_data = cursor.fetchone()
            professions_data.append({
                "profession_id": prof_data[0],
                "name": prof_data[1],
                "description": prof_data[2],
                "initial_skills": profession.initial_skills
            })

        # 处理角色信息（原 NPC）
        cursor.execute("SELECT COALESCE(MAX(character_id), 0) FROM characters")
        max_char_id = cursor.fetchone()[0]
        characters_data = []
        for idx, npc in enumerate(module.npcs, 1):
            char_id = max_char_id + idx
            cursor.execute("""
                INSERT INTO characters (
                    character_id, module_id, name, position, faction, 
                    background, personality, initial_attitude, 
                    secret_level, chat_prompt
                )
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                RETURNING character_id, name, position, faction, background, 
                          personality, initial_attitude, secret_level, chat_prompt
            """, (
                char_id, new_id, npc.name, npc.position, npc.faction,
                npc.background, npc.personality, npc.initial_attitude,
                npc.secret_level, npc.chat_prompt
            ))
            char_data = cursor.fetchone()
            characters_data.append({
                "character_id": char_data[0],
                "name": char_data[1],
                "position": char_data[2],
                "faction": char_data[3],
                "background": char_data[4],
                "personality": char_data[5],
                "initial_attitude": char_data[6],
                "secret_level": char_data[7],
                "chat_prompt": char_data[8]
            })

        # 处理结局信息
        cursor.execute("SELECT COALESCE(MAX(ending_id), 0) FROM ending_conditions")
        max_ending_id = cursor.fetchone()[0]
        endings_data = []
        for idx, ending in enumerate(module.endings, 1):
            ending_id = max_ending_id + idx
            cursor.execute("""
                INSERT INTO ending_conditions (ending_id, module_id, ending_name, ending_description)
                VALUES (%s, %s, %s, %s)
                RETURNING ending_id, ending_name, ending_description
            """, (ending_id, new_id, ending.ending_name, ending.ending_description))
            ending_data = cursor.fetchone()
            endings_data.append({
                "ending_id": ending_data[0],
                "ending_name": ending_data[1],
                "ending_description": ending_data[2]
            })
        
        # 提交事务
        conn.commit()
        
        return {
            "module_id": new_module[0],
            "title": new_module[1],
            "description": new_module[2],
            "professions": professions_data,
            "npcs": characters_data,      # 返回时仍使用 npcs 键名以兼容前端
            "endings": endings_data
        }
    except Exception as e:
        conn.rollback()
        print(f"Error creating module: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        cursor.close()
        conn.close()

@app.delete("/modules/{module_id}")
async def delete_module(module_id: int, db: Session = Depends(get_db)):
    try:
        # 按顺序删除所有相关数据
        # 1. 删除结局条件
        db.query(EndingCondition).filter(EndingCondition.module_id == module_id).delete()
        
        # 2. 删除角色
        db.query(Character).filter(Character.module_id == module_id).delete()
        
        # 3. 删除职业
        db.query(Profession).filter(Profession.module_id == module_id).delete()
        
        # 4. 最后删除模组
        module = db.query(Module).filter(Module.module_id == module_id).first()
        if not module:
            raise HTTPException(status_code=404, detail="模组不存在")
            
        db.delete(module)
        db.commit()
        return {"message": "模组删除成功"}
        
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"删除模组失败: {str(e)}")

# 角色相关路由
@app.get("/characters/", response_model=List[dict])
async def get_characters():
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("SELECT character_id, name, faction FROM characters")
        characters = cursor.fetchall()
        return [
            {
                "character_id": c[0],
                "name": c[1],
                "faction": c[2]
            } for c in characters
        ]
    finally:
        cursor.close()
        conn.close()

# 职业相关路由
@app.get("/professions/", response_model=List[dict])
async def get_professions():
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("SELECT profession_id, name, initial_skills FROM professions")
        professions = cursor.fetchall()
        return [
            {
                "profession_id": p[0],
                "name": p[1],
                "initial_skills": p[2]
            } for p in professions
        ]
    finally:
        cursor.close()
        conn.close()

# 游戏阶段相关路由
@app.get("/game-phases/", response_model=List[dict])
def get_game_phases(db: Session = Depends(get_db)):
    phases = db.query(models.GamePhase).all()
    return [{"phase_id": p.phase_id, "phase_name": p.phase_name, "phase_order": p.phase_order} for p in phases]

# 数据库状态检查路由
@app.get("/db-status/")
def check_db_status(db: Session = Depends(get_db)):
    try:
        return {
            "status": "connected",
            "tables": {
                "modules": db.query(models.Module).count(),
                "characters": db.query(models.Character).count(),
                "professions": db.query(models.Profession).count(),
                "game_phases": db.query(models.GamePhase).count(),
                "secrets": db.query(models.Secret).count(),
                "ending_conditions": db.query(models.EndingCondition).count(),
                "game_actions": db.query(models.GameAction).count()
            }
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e)) 

# Players 相关路由
@app.post("/players/", response_model=PlayerResponse)
async def create_player(player: PlayerCreate):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        # 检查用户名是否已存在
        cursor.execute("SELECT 1 FROM players WHERE username = %s", (player.username,))
        if cursor.fetchone():
            raise HTTPException(status_code=400, detail="Username already registered")
        
        # 检查邮箱是否已存在
        cursor.execute("SELECT 1 FROM players WHERE email = %s", (player.email,))
        if cursor.fetchone():
            raise HTTPException(status_code=400, detail="Email already registered")
        
        # TODO: 在实际应用中应该对密码进行哈希处理
        cursor.execute("""
            INSERT INTO players (username, email, password_hash, bio, profile_image_url)
            VALUES (%s, %s, %s, %s, %s)
            RETURNING player_id, username, email, created_at, bio, profile_image_url, total_play_time, achievements
        """, (player.username, player.email, player.password, player.bio, player.profile_image_url))
        
        new_player = cursor.fetchone()
        conn.commit()
        
        return {
            "player_id": new_player[0],
            "username": new_player[1],
            "email": new_player[2],
            "created_at": new_player[3].isoformat() if new_player[3] else None,
            "bio": new_player[4],
            "profile_image_url": new_player[5],
            "total_play_time": new_player[6],
            "achievements": new_player[7]
        }
    finally:
        cursor.close()
        conn.close()

@app.get("/players/{player_id}", response_model=PlayerResponse)
async def get_player(player_id: int):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("""
            SELECT player_id, username, email, created_at, last_login, 
                   profile_image_url, bio, total_play_time, achievements
            FROM players
            WHERE player_id = %s
        """, (player_id,))
        
        player = cursor.fetchone()
        if not player:
            raise HTTPException(status_code=404, detail="Player not found")
            
        return {
            "player_id": player[0],
            "username": player[1],
            "email": player[2],
            "created_at": player[3].isoformat() if player[3] else None,
            "last_login": player[4].isoformat() if player[4] else None,
            "profile_image_url": player[5],
            "bio": player[6],
            "total_play_time": player[7],
            "achievements": player[8]
        }
    finally:
        cursor.close()
        conn.close()

# Player Characters 相关路由
@app.post("/player-characters/", response_model=PlayerCharacterResponse)
async def create_player_character(character: PlayerCharacterCreate):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("""
            INSERT INTO player_characters (
                player_id, module_id, profession_id, current_sanity,
                current_alienation, inventory, completed_phases, current_status
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING player_character_id, creation_time
        """, (
            character.player_id, character.module_id, character.profession_id,
            character.current_sanity, character.current_alienation,
            json.dumps(character.inventory), json.dumps(character.completed_phases),
            character.current_status
        ))
        
        new_character = cursor.fetchone()
        conn.commit()
        
        return {
            **character.dict(),
            "player_character_id": new_character[0],
            "creation_time": new_character[1].isoformat()
        }
    finally:
        cursor.close()
        conn.close()

@app.get("/players/{player_id}/characters", response_model=List[PlayerCharacterResponse])
async def get_player_characters(player_id: int):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("""
            SELECT player_character_id, module_id, profession_id, creation_time,
                   current_sanity, current_alienation, inventory, completed_phases,
                   current_status
            FROM player_characters
            WHERE player_id = %s
        """, (player_id,))
        
        characters = cursor.fetchall()
        return [{
            "player_character_id": c[0],
            "module_id": c[1],
            "profession_id": c[2],
            "creation_time": c[3].isoformat(),
            "current_sanity": c[4],
            "current_alienation": c[5],
            "inventory": c[6],
            "completed_phases": c[7],
            "current_status": c[8]
        } for c in characters]
    finally:
        cursor.close()
        conn.close() 

@app.post("/create-game-character/")
async def create_game_character(character_data: SimpleCharacterCreate, db: Session = Depends(get_db)):
    try:
        # 1. 创建新的游戏会话
        game_session = GameSession(
            module_id=character_data.module_id,
            player_id=1,  # 暂时固定为1
            profession_id=character_data.profession_id,
            current_phase_id=1,  # 设置初始阶段为1
            sanity_value=100,
            alienation_value=0,
            chen_influence=50,
            liu_influence=50,
            discovered_secrets=[],  # SQLAlchemy 会自动处理 JSON 序列化
            completed_actions=[],   
            session_status='active',
            start_time=datetime.utcnow(),
            last_save_time=datetime.utcnow()
        )
        db.add(game_session)
        db.flush()  # 获取自动生成的session_id
        
        # 2. 创建玩家角色
        player_character = PlayerCharacter(
            module_id=character_data.module_id,
            profession_id=character_data.profession_id,
            player_id=1,  # 暂时固定为1
            current_sanity=100,
            current_alienation=0,
            current_status="active",
            inventory={},        # SQLAlchemy 会自动处理 JSON 序列化
            completed_phases={},
            session_id=game_session.session_id
        )
        db.add(player_character)
        db.flush()  # 获取自动生成的player_character_id

        # 3. 初始化玩家状态
        player_status = PlayerStatus(
            player_character_id=player_character.player_character_id,
            session_id=game_session.session_id,
            sanity_value=100,
            alienation_value=0,
            chen_influence=0,
            liu_influence=0,
            discovered_secrets=[],  # PostgreSQL 会自动处理数组类型
        )
        db.add(player_status)
        db.commit()

        return {
            "player_character_id": player_character.player_character_id,
            "game_session_id": game_session.session_id,
            "message": "角色创建成功"
        }

    except Exception as e:
        db.rollback()
        print(f"Error creating character: {str(e)}")
        raise HTTPException(
            status_code=500, 
            detail=f"创建角色失败: {str(e)}"
        )

@app.get("/player-characters/{character_id}")
async def get_player_character(character_id: int):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        # 获取角色信息和职业名称
        cursor.execute("""
            SELECT pc.player_character_id, 
                   pc.module_id,
                   pc.profession_id,
                   pc.creation_time,
                   pc.current_sanity,
                   pc.current_alienation,
                   pc.inventory,
                   pc.completed_phases,
                   pc.current_status,
                   p.name as profession_name
            FROM player_characters pc
            JOIN professions p ON pc.profession_id = p.profession_id
            WHERE pc.player_character_id = %s
        """, (character_id,))
        
        character = cursor.fetchone()
        if not character:
            raise HTTPException(status_code=404, detail="Character not found")
            
        return {
            "player_character_id": character[0],
            "module_id": character[1],
            "profession_id": character[2],
            "creation_time": character[3].isoformat(),
            "current_sanity": character[4] or 60,  # 默认值为60
            "current_alienation": character[5] or 0,  # 默认值为0
            "inventory": character[6] if character[6] else {},
            "completed_phases": character[7] if character[7] else {},
            "current_status": character[8],
            "name": character[9]  # 使用职业名称作为角色名称
        }
    finally:
        cursor.close()
        conn.close() 

@app.post("/upload-avatar/{character_id}")
async def upload_avatar(character_id: int, file: UploadFile = File(...)):
    try:
        # 创建保存目录（如果不存在）
        save_dir = "frontend/public/avatars/players"
        os.makedirs(save_dir, exist_ok=True)
        
        # 生成文件名
        file_extension = os.path.splitext(file.filename)[1]
        new_filename = f"character_{character_id}{file_extension}"
        file_path = os.path.join(save_dir, new_filename)
        
        # 保存文件
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        
        # 更新数据库中的头像URL
        avatar_url = f"/avatars/players/{new_filename}"
        conn = get_db_connection()
        cursor = conn.cursor()
        try:
            cursor.execute("""
                UPDATE player_characters 
                SET avatar_url = %s 
                WHERE player_character_id = %s
            """, (avatar_url, character_id))
            conn.commit()
        finally:
            cursor.close()
            conn.close()
            
        return {"avatar_url": avatar_url}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e)) 

@app.post("/chat/{player_character_id}/{npc_name}")
async def chat_with_npc(
    player_character_id: int, 
    npc_name: str, 
    message: dict,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    try:
        print(f"Starting chat with NPC. Session ID: {player_character_id}, NPC: {npc_name}, Message: {message}")
        db = SessionLocal()
        
        # 初始化 AIService，使用环境变量中的配置
        ai_service = AIService(
            base_url='https://xiaoai.plus/v1',
            api_key=os.getenv('OPENAI_API_KEY')
        )
        
        try:
            # 获取 NPC 的背景信息和角色设定
            print("Fetching NPC info...")
            result = db.execute(
                text("""
                    SELECT c.name, c.position, c.background, c.personality, 
                           c.chat_prompt, c.faction
                    FROM characters c
                    JOIN modules m ON c.module_id = m.module_id
                    WHERE c.name = :npc_name
                """),
                {"npc_name": npc_name}
            )
            
            npc_info = result.fetchone()
            if not npc_info:
                print(f"NPC not found: {npc_name}")
                raise HTTPException(status_code=404, detail=f"NPC not found: {npc_name}")
            
            # 构建系统提示
            system_prompt = f"""
            你现在扮演一个名为 {npc_info[0]} 的NPC角色。
            
            角色信息：
            - 职位：{npc_info[1]}
            - 背景：{npc_info[2]}
            - 性格：{npc_info[3]}
            - 阵营：{npc_info[5] or '未知'}
            
            额外设定：{npc_info[4]}
            
            请以这个角色的身份回应用户的对话。除了回复内容，你还需要分析这次对话对玩家的影响。
            
            你必须严格按照以下JSON格式返回，不要添加任何其他内容：
            {{
                "response": "NPC的回复内容",
                "effects": {{
                    "sanity": 数值(-10到+10),
                    "alienation": 数值(-10到+10),
                    "chen_influence": 数值(-10到+10),
                    "liu_influence": 数值(-10到+10),
                    "discovered_secrets": ["secret_key1", "secret_key2"]
                }}
            }}
            
            可能的秘密关键词：
            - chen_fraud: 陈总诈骗
            - liu_cult: 刘总监邪教
            - layoff_list: 裁员名单
            """
            
            # 获取AI响应
            response_data = await ai_service.get_npc_response(
                system_prompt=system_prompt,
                user_message=message["message"]
            )
            
            # 添加详细的日志输出
            print("\n=== AI Response Debug ===")
            print(f"User Message: {message['message']}")
            print(f"Raw AI Response: {response_data}")
            print(f"Response Content: {response_data.get('response', 'No response content')}")
            print(f"Effects: {response_data.get('effects', 'No effects')}")
            print("========================\n")
            
            # 更新玩家状态
            try:
                current_status = db.execute(
                    text("""
                        SELECT sanity_value, alienation_value, 
                               chen_influence, liu_influence, discovered_secrets
                        FROM player_status
                        WHERE player_character_id = :player_character_id
                    """),
                    {"player_character_id": player_character_id}
                ).fetchone()
                
                if current_status:
                    # 计算新的状态值
                    new_sanity = max(0, min(100, current_status[0] + response_data['effects']['sanity']))
                    new_alienation = max(0, min(100, current_status[1] + response_data['effects']['alienation']))
                    new_chen = max(0, min(100, current_status[2] + response_data['effects']['chen_influence']))
                    new_liu = max(0, min(100, current_status[3] + response_data['effects']['liu_influence']))
                    
                    # 合并发现的秘密
                    current_secrets = current_status[4] if current_status[4] else []
                    new_secrets = list(set(current_secrets + response_data['effects']['discovered_secrets']))
                    
                    # 更新数据库
                    db.execute(
                        text("""
                            UPDATE player_status
                            SET sanity_value = :sanity,
                                alienation_value = :alienation,
                                chen_influence = :chen,
                                liu_influence = :liu,
                                discovered_secrets = :secrets
                            WHERE player_character_id = :player_character_id
                        """),
                        {
                            "player_character_id": player_character_id,
                            "sanity": new_sanity,
                            "alienation": new_alienation,
                            "chen": new_chen,
                            "liu": new_liu,
                            "secrets": new_secrets
                        }
                    )
                    
                    print("\n=== Status Update ===")
                    print(f"Sanity: {current_status[0]} -> {new_sanity}")
                    print(f"Alienation: {current_status[1]} -> {new_alienation}")
                    print(f"Chen Influence: {current_status[2]} -> {new_chen}")
                    print(f"Liu Influence: {current_status[3]} -> {new_liu}")
                    print(f"New Secrets: {new_secrets}")
                    print("=====================\n")
                else:
                    print(f"Warning: No player status found for session {player_character_id}")
            except Exception as e:
                print(f"Error updating player status: {e}")
                # 继续执行，不要因为状态更新失败而中断整个请求
            
            # 保存用户消息和 NPC 响应到数据库
            try:
                # 保存用户消息
                db.execute(
                    text("""
                        INSERT INTO chat_messages 
                        (session_id, npc_name, content, is_npc, timestamp)
                        VALUES (:session_id, :npc_name, :content, :is_npc, CURRENT_TIMESTAMP)
                    """),
                    {
                        "session_id": player_character_id,
                        "npc_name": npc_name,
                        "content": message["message"],
                        "is_npc": False
                    }
                )
                
                # 保存NPC响应
                db.execute(
                    text("""
                        INSERT INTO chat_messages 
                        (session_id, npc_name, content, is_npc, timestamp)
                        VALUES (:session_id, :npc_name, :content, :is_npc, CURRENT_TIMESTAMP)
                    """),
                    {
                        "session_id": player_character_id,
                        "npc_name": npc_name,
                        "content": response_data["response"],
                        "is_npc": True
                    }
                )
                
                db.commit()
                
            except Exception as e:
                db.rollback()
                print(f"Error saving chat messages: {e}")
                raise
            
            # 在对话结束后检查结局状态
            ending_result = await check_ending(player_character_id, db)
            
            # 构造响应
            response = {
                "content": response_data["response"],
                "effects": response_data["effects"],
                "type": "npc",
                "time": datetime.now().isoformat()
            }
            
            # 如果有结局，添加到响应中
            if ending_result.has_ending:
                response["ending"] = ending_result.endings[0].dict()
                response["current_status"] = ending_result.current_status.dict()
            
            return response
            
        except Exception as e:
            db.rollback()
            print(f"Error in chat endpoint (inner): {str(e)}")
            raise HTTPException(status_code=500, detail=str(e))
        finally:
            db.close()
            
    except Exception as e:
        print(f"Error in chat endpoint (outer): {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/chat_history/{player_character_id}/{npc_name}")
async def get_chat_history(player_character_id: int, npc_name: str):
    try:
        db = SessionLocal()
        try:
            # 添加日志以便调试
            print(f"Fetching chat history for player_character_id {player_character_id} and NPC {npc_name}")
            
            result = db.execute(
                text("""
                    SELECT content, is_npc, timestamp
                    FROM chat_messages
                    WHERE session_id = :session_id 
                    AND npc_name = :npc_name
                    ORDER BY timestamp ASC
                """),
                {
                    "session_id": player_character_id,  # 使用 player_character_id 作为 session_id
                    "npc_name": npc_name
                }
            )
            
            messages = result.fetchall()
            
            # 添加日志以便调试
            print(f"Found {len(messages)} messages")
            
            return [{
                "content": msg[0],
                "is_npc": msg[1],
                "timestamp": msg[2].isoformat(),
                "sender": npc_name if msg[1] else "player"
            } for msg in messages]
            
        finally:
            db.close()
            
    except Exception as e:
        print(f"Error fetching chat history: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/advance_day/{session_id}")
async def advance_day(session_id: str):
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # 更新游戏会话的天数
        cursor.execute("""
            UPDATE game_sessions 
            SET current_day = current_day + 1
            WHERE session_id = %s
            RETURNING current_day
        """, (session_id,))
        
        updated_day = cursor.fetchone()[0]
        conn.commit()
        
        return {"day": updated_day}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        cursor.close()
        conn.close()

@app.get("/api/game/check-ending/{player_character_id}", response_model=CheckEndingResponse)
async def check_ending(player_character_id: int, db: Session = Depends(get_db)):
    try:
        print(f"\n=== 开始检查玩家 {player_character_id} 的结局状态 ===")
        
        # 获取玩家当前状态
        result = db.execute(
            text("""
                SELECT sanity_value, alienation_value, 
                       chen_influence, liu_influence, discovered_secrets
                FROM player_status
                WHERE player_character_id = :player_character_id
            """),
            {"player_character_id": player_character_id}
        ).fetchone()
        
        if not result:
            raise HTTPException(status_code=404, detail="Player status not found")
            
        # 获取玩家状态
        player_status = PlayerStatusResponse(
            sanity=float(result[0] or 0),  # 确保数值类型正确
            alienation=float(result[1] or 0),
            chen_influence=float(result[2] or 0),
            liu_influence=float(result[3] or 0),
            discovered_secrets=result[4] if result[4] else []
        )
        
        # 从数据库获取所有可能的结局
        endings = db.execute(
            text("""
                SELECT ending_id, ending_name, ending_description,
                       required_sanity_range, required_alienation_range,
                       required_faction_influence, required_secrets
                FROM ending_conditions
                WHERE module_id = 1
            """)
        ).fetchall()
        
        available_endings: List[EndingResponse] = []
        
        # 检查每个结局的条件
        for ending in endings:
            try:
                # 安全地解析 JSON 字符串
                def safe_json_loads(value):
                    if isinstance(value, str):
                        try:
                            return json.loads(value)
                        except json.JSONDecodeError:
                            return None
                    return value
                
                sanity_range = safe_json_loads(ending[3]) or {"min": 0, "max": 100}
                alienation_range = safe_json_loads(ending[4]) or {"min": 0, "max": 100}
                
                # 检查条件是否满足
                if (sanity_range["min"] <= player_status.sanity <= sanity_range["max"] and
                    alienation_range["min"] <= player_status.alienation <= alienation_range["max"]):
                    
                    available_endings.append(EndingResponse(
                        ending_id=ending[0],
                        name=ending[1],
                        description=ending[2]
                    ))
                    print(f"\n触发结局：{ending[1]}")
                
            except Exception as e:
                print(f"检查结局 {ending[1]} 时出错: {str(e)}")
                continue
        
        response = CheckEndingResponse(
            has_ending=len(available_endings) > 0,
            endings=available_endings,
            current_status=player_status
        )
        
        print("结局检查结果:", response.dict())
        return response
        
    except Exception as e:
        print(f"结局检查出错: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/game/end-session/{session_id}")
def end_game_session(
    session_id: int, 
    ending_data: EndingSchema,
    db: Session = Depends(get_db)
):
    # 更新游戏会话状态为已结束
    session = db.query(GameSession).filter_by(session_id=session_id).first()
    session.session_status = "completed"
    session.ending_id = ending_data.ending_id
    db.commit()
    return {"message": "Game session ended successfully"} 

@app.post("/api/game/investigate/{session_id}")
def investigate(
    session_id: int,
    action_data: dict,
    db: Session = Depends(get_db)
):
    ai_service = AIService(db)
    
    # 记录调查事件
    ai_service.record_event(
        session_id=session_id,
        event_type="investigation",
        event_data=action_data
    )
    
    # 根据调查行动更新玩家状态
    status = db.query(PlayerStatus).filter_by(session_id=session_id).first()
    
    # 根据不同的调查行动更新状态
    if action_data.get("type") == "computer_access":
        if random.random() < 0.3:  # 30%概率被发现
            ai_service.record_event(
                session_id=session_id,
                event_type="investigation",
                event_data={"action": "illegal_access", "detected": True}
            )
    
    db.commit()
    return {"message": "Investigation recorded successfully"} 

@app.get("/player-status/{player_character_id}", response_model=PlayerStatusResponse)
async def get_player_status(player_character_id: int, db: Session = Depends(get_db)):
    try:
        result = db.execute(
            text("""
                SELECT sanity_value, alienation_value, 
                       chen_influence, liu_influence, discovered_secrets
                FROM player_status
                WHERE player_character_id = :player_character_id
            """),
            {"player_character_id": player_character_id}
        ).fetchone()
        
        if not result:
            # 创建新的状态记录
            db.execute(
                text("""
                    INSERT INTO player_status (
                        player_character_id,
                        sanity_value,
                        alienation_value,
                        chen_influence,
                        liu_influence,
                        discovered_secrets
                    ) VALUES (:player_character_id, 100, 0, 0, 0, ARRAY[]::TEXT[])
                """),
                {"player_character_id": player_character_id}
            )
            db.commit()
            
            return PlayerStatusResponse(
                sanity=100,
                alienation=0,
                chen_influence=0,
                liu_influence=0,
                discovered_secrets=[]
            )
        
        return PlayerStatusResponse(
            sanity=result[0],
            alienation=result[1],
            chen_influence=result[2],
            liu_influence=result[3],
            discovered_secrets=result[4] if result[4] else []
        )
    except Exception as e:
        print(f"Error in get_player_status: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e)) 