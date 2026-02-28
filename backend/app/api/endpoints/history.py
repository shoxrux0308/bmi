import json
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc, func
from app.core.database import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.models.history import History
from app.schemas.schemas import HistoryOut

router = APIRouter(prefix="/api/history", tags=["History"])


@router.get("/", response_model=list[HistoryOut])
async def get_history(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, le=100),
    lang: str = Query(None),
    search: str = Query(None),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Foydalanuvchi tarixini olish — filtrlash va qidiruv bilan."""
    query = select(History).where(History.user_id == current_user.id)
    if lang:
        query = query.where(History.detected_lang == lang.upper())
    if search:
        query = query.where(
            History.filename.ilike(f"%{search}%") |
            History.ocr_text.ilike(f"%{search}%") |
            History.summary.ilike(f"%{search}%")
        )
    query = query.order_by(desc(History.created_at)).offset(skip).limit(limit)
    result = await db.execute(query)
    return result.scalars().all()


@router.get("/{history_id}", response_model=HistoryOut)
async def get_history_item(
    history_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(History).where(History.id == history_id, History.user_id == current_user.id)
    )
    item = result.scalar_one_or_none()
    if not item:
        raise HTTPException(status_code=404, detail="Tarix elementi topilmadi")
    return item


@router.delete("/{history_id}")
async def delete_history_item(
    history_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(History).where(History.id == history_id, History.user_id == current_user.id)
    )
    item = result.scalar_one_or_none()
    if not item:
        raise HTTPException(status_code=404, detail="Topilmadi")
    await db.delete(item)
    await db.commit()
    return {"message": "O'chirildi"}
