from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime


class UserCreate(BaseModel):
    full_name: str
    email: EmailStr
    password: str


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class UserOut(BaseModel):
    id: int
    full_name: str
    email: str
    role: str
    created_at: datetime

    class Config:
        from_attributes = True


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserOut


class HistoryOut(BaseModel):
    id: int
    filename: str
    file_type: str
    detected_lang: Optional[str]
    lang_confidence: Optional[float]
    ocr_text: Optional[str]
    summary: Optional[str]
    translated_summary: Optional[str] = None
    sentiment: Optional[str] = None
    entities: Optional[str] = None
    keywords: Optional[str]
    category: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True


class AnalyzeRequest(BaseModel):
    text: str
    mode: str = "auto"   # auto | latin-only


class AnalyzeResponse(BaseModel):
    lang: str
    confidence: float
    summary: str
    translated_summary: Optional[str] = None
    sentiment: Optional[dict] = None
    entities: Optional[list[str]] = None
    keywords: list[str]
    category: str


class FeedbackCreate(BaseModel):
    history_id: int
    comment: Optional[str] = None
    correct_lang: Optional[str] = None


class StatsOut(BaseModel):
    total_users: int
    total_analyses: int
    lang_distribution: dict
    daily_analyses: list[dict]
