from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey, Float, func
from sqlalchemy.orm import relationship
from app.core.database import Base


class History(Base):
    __tablename__ = "history"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    filename = Column(String(255), nullable=False)
    file_path = Column(String(500), nullable=True)
    file_type = Column(String(20), nullable=False)   # image | pdf
    detected_lang = Column(String(10), nullable=True)
    lang_confidence = Column(Float, nullable=True)
    ocr_text = Column(Text, nullable=True)
    summary = Column(Text, nullable=True)
    translated_summary = Column(Text, nullable=True)
    sentiment = Column(String(255), nullable=True) # JSON or string
    entities = Column(Text, nullable=True)         # JSON list
    keywords = Column(Text, nullable=True)           # JSON string
    category = Column(String(100), nullable=True)
    word_count = Column(Integer, default=0)
    sentence_count = Column(Integer, default=0)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", backref="history")
    feedback = relationship("Feedback", back_populates="history_item", uselist=False)
