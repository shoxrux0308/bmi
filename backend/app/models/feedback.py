from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey, func
from sqlalchemy.orm import relationship
from app.core.database import Base


class Feedback(Base):
    __tablename__ = "feedback"

    id = Column(Integer, primary_key=True, index=True)
    history_id = Column(Integer, ForeignKey("history.id", ondelete="CASCADE"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    comment = Column(Text, nullable=True)
    correct_lang = Column(String(10), nullable=True)
    is_reviewed = Column(String(10), default="pending")  # pending | reviewed
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    history_item = relationship("History", back_populates="feedback")
