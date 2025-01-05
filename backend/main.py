from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from typing import List, Optional
from pydantic import BaseModel
from sqlalchemy.orm import Session
from database import get_db_connection, SessionLocal, engine
import schemas
import models

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
async def delete_module(module_id: int):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("DELETE FROM modules WHERE module_id = %s", (module_id,))
        if cursor.rowcount == 0:
            raise HTTPException(status_code=404, detail="Module not found")
        conn.commit()
        return {"message": "Module deleted successfully"}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        cursor.close()
        conn.close()

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