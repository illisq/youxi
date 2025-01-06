from pydantic import BaseModel, EmailStr
from datetime import datetime
from typing import Optional

class UserBase(BaseModel):
    username: str
    email: EmailStr

class UserCreate(UserBase):
    password: str

class User(UserBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True 

class EndingSchema(BaseModel):
    ending_id: int
    ending_name: str | None = None
    ending_description: str | None = None 

class SimpleCharacterCreate(BaseModel):
    module_id: int
    profession_id: int 