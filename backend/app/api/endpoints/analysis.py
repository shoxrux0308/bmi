import os
import uuid
import json
import aiofiles
from pathlib import Path
from fastapi import APIRouter, Depends, File, UploadFile, HTTPException, Form
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc
from app.core.database import get_db
from app.core.security import get_current_user
from app.core.config import get_settings
from app.models.user import User
from app.models.history import History
from app.services.ocr_service import extract_text
from app.services.language_detector import get_detector
from app.services.nlp_service import analyze_text
from app.schemas.schemas import HistoryOut, AnalyzeResponse

router = APIRouter(prefix="/api", tags=["Analysis"])
settings = get_settings()

ALLOWED_TYPES = {
    "image/jpeg": ("image", "jpg"),
    "image/png": ("image", "png"),
    "application/pdf": ("pdf", "pdf"),
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document": ("docx", "docx"),
}


@router.post("/upload", response_model=HistoryOut)
async def upload_and_analyze(
    file: UploadFile = File(...),
    enhance: bool = Form(False),
    mode: str = Form("auto"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    # Fayl turi tekshirish
    if file.content_type not in ALLOWED_TYPES:
        raise HTTPException(status_code=400, detail="Faqat JPG, PNG, yoki PDF ruxsat berilgan")

    file_type, ext = ALLOWED_TYPES[file.content_type]

    # Fayl hajmi tekshirish
    contents = await file.read()
    if len(contents) > settings.max_file_size_mb * 1024 * 1024:
        raise HTTPException(status_code=413, detail=f"Fayl hajmi {settings.max_file_size_mb}MB dan oshmasligi kerak")

    # Saqlash
    upload_dir = Path(settings.upload_dir) / str(current_user.id)
    upload_dir.mkdir(parents=True, exist_ok=True)
    filename = f"{uuid.uuid4()}.{ext}"
    file_path = upload_dir / filename

    async with aiofiles.open(file_path, "wb") as f:
        await f.write(contents)

    # OCR
    try:
        ocr_text = extract_text(str(file_path), file_type, enhance=enhance)
    except Exception as e:
        ocr_text = f"OCR xatosi: {str(e)}"

    # Til aniqlash + NLP
    detector = get_detector()
    lang_result = detector.detect(ocr_text, mode=mode)
    
    # NLP xulosasi tarjimasi foydalanuvchi interfeysi tili asosida yoki O'zbek tiliga
    target_lang = 'uz' if lang_result["lang"] in ['EN', 'RU'] else 'en'
    nlp_result = analyze_text(ocr_text, target_translation=target_lang)

    # DB ga saqlash
    history = History(
        user_id=current_user.id,
        filename=file.filename,
        file_path=str(file_path),
        file_type=file_type,
        detected_lang=lang_result["lang"],
        lang_confidence=lang_result["confidence"],
        ocr_text=ocr_text,
        summary=nlp_result["summary"],
        translated_summary=nlp_result["translated_summary"],
        sentiment=json.dumps(nlp_result["sentiment"], ensure_ascii=False),
        entities=json.dumps(nlp_result["entities"], ensure_ascii=False),
        keywords=json.dumps(nlp_result["keywords"], ensure_ascii=False),
        category=nlp_result["category"],
        word_count=nlp_result["word_count"],
        sentence_count=nlp_result["sentence_count"],
    )
    db.add(history)
    await db.commit()
    await db.refresh(history)
    return history


@router.post("/ocr")
async def ocr_only(
    file: UploadFile = File(...),
    enhance: bool = Form(False),
    current_user: User = Depends(get_current_user),
):
    """Faqat OCR — matn ajratib berish."""
    if file.content_type not in ALLOWED_TYPES:
        raise HTTPException(status_code=400, detail="Faqat JPG, PNG, yoki PDF ruxsat berilgan")

    file_type, ext = ALLOWED_TYPES[file.content_type]
    contents = await file.read()
    tmp_path = f"/tmp/ocr_{uuid.uuid4()}.{ext}"

    async with aiofiles.open(tmp_path, "wb") as f:
        await f.write(contents)

    try:
        text = extract_text(tmp_path, file_type, enhance=enhance)
    finally:
        if os.path.exists(tmp_path):
            os.remove(tmp_path)

    return {"ocr_text": text, "char_count": len(text)}


@router.post("/detect-language")
async def detect_language(
    text: str = Form(...),
    mode: str = Form("auto"),
    current_user: User = Depends(get_current_user),
):
    """Faqat til aniqlash."""
    if len(text) < 5:
        raise HTTPException(status_code=400, detail="Matn juda qisqa")
    detector = get_detector()
    result = detector.detect(text, mode=mode)
    return result


@router.post("/analyze", response_model=AnalyzeResponse)
async def analyze(
    text: str = Form(...),
    mode: str = Form("auto"),
    current_user: User = Depends(get_current_user),
):
    """Matn tahlili: til, xulosa, kalit so'zlar, kategoriya."""
    if len(text) < 10:
        raise HTTPException(status_code=400, detail="Matn juda qisqa")
    detector = get_detector()
    lang_result = detector.detect(text, mode=mode)
    
    target_lang = 'uz' if lang_result["lang"] in ['EN', 'RU'] else 'en'
    nlp_result = analyze_text(text, target_translation=target_lang)
    
    return {**lang_result, **nlp_result}
