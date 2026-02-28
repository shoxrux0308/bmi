from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.core.database import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.models.history import History
from app.models.feedback import Feedback
from app.schemas.schemas import FeedbackCreate

router = APIRouter(prefix="/api/feedback", tags=["Feedback"])


@router.post("/")
async def submit_feedback(
    data: FeedbackCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    # Tarixni tekshirish
    result = await db.execute(
        select(History).where(History.id == data.history_id, History.user_id == current_user.id)
    )
    history_item = result.scalar_one_or_none()
    if not history_item:
        raise HTTPException(status_code=404, detail="Tarix elementi topilmadi")

    feedback = Feedback(
        history_id=data.history_id,
        user_id=current_user.id,
        comment=data.comment,
        correct_lang=data.correct_lang,
        is_reviewed="pending",
    )
    db.add(feedback)
    await db.commit()
    return {"message": "Fikr-mulohaza qabul qilindi, rahmat!"}
