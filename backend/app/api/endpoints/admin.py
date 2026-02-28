from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, desc
from app.core.database import get_db
from app.core.security import get_current_admin
from app.models.user import User
from app.models.history import History
from app.models.feedback import Feedback

router = APIRouter(prefix="/api/admin", tags=["Admin"])


@router.get("/stats")
async def get_stats(
    current_admin=Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """Admin statistikasi."""
    total_users = await db.scalar(select(func.count(User.id)))
    total_analyses = await db.scalar(select(func.count(History.id)))

    # Til taqsimoti
    lang_result = await db.execute(
        select(History.detected_lang, func.count(History.id))
        .group_by(History.detected_lang)
        .order_by(desc(func.count(History.id)))
    )
    lang_distribution = {row[0] or "N/A": row[1] for row in lang_result.all()}

    # Kunlik tahlillar (so'nggi 7 kun)
    daily_result = await db.execute(
        select(
            func.date(History.created_at).label("date"),
            func.count(History.id).label("count")
        )
        .group_by(func.date(History.created_at))
        .order_by(desc(func.date(History.created_at)))
        .limit(7)
    )
    daily_analyses = [{"date": str(row.date), "count": row.count} for row in daily_result.all()]

    # Kategoriya taqsimoti
    cat_result = await db.execute(
        select(History.category, func.count(History.id))
        .group_by(History.category)
        .order_by(desc(func.count(History.id)))
    )
    category_distribution = {row[0] or "N/A": row[1] for row in cat_result.all()}

    # So'nggi foydalanuvchilar
    users_result = await db.execute(
        select(User).order_by(desc(User.created_at)).limit(10)
    )
    recent_users = [
        {"id": u.id, "full_name": u.full_name, "email": u.email, "role": u.role}
        for u in users_result.scalars().all()
    ]

    return {
        "total_users": total_users,
        "total_analyses": total_analyses,
        "lang_distribution": lang_distribution,
        "daily_analyses": daily_analyses,
        "category_distribution": category_distribution,
        "recent_users": recent_users,
    }


@router.get("/feedbacks")
async def get_feedbacks(
    current_admin=Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Feedback).order_by(desc(Feedback.created_at)).limit(50)
    )
    feedbacks = result.scalars().all()
    return [
        {
            "id": f.id,
            "history_id": f.history_id,
            "comment": f.comment,
            "correct_lang": f.correct_lang,
            "is_reviewed": f.is_reviewed,
            "created_at": str(f.created_at),
        }
        for f in feedbacks
    ]


@router.patch("/feedbacks/{feedback_id}/review")
async def review_feedback(
    feedback_id: int,
    current_admin=Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Feedback).where(Feedback.id == feedback_id))
    fb = result.scalar_one_or_none()
    if not fb:
        raise HTTPException(status_code=404, detail="Topilmadi")
    fb.is_reviewed = "reviewed"
    await db.commit()
    return {"message": "Ko'rib chiqildi"}
