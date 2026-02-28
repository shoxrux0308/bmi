"""
OCR Service — Rasm va PDF fayllardan matn ajratib olish.
Engines: EasyOCR (asosiy), Tesseract (fallback)
"""
import os
import io
from pathlib import Path
from typing import Optional
import cv2
import numpy as np
from PIL import Image, ImageEnhance


def enhance_image(image_path: str) -> np.ndarray:
    """Rasm sifatini yaxshilash: kontrast, sharpness."""
    img = cv2.imread(image_path)
    # Grayscale
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    # Kontrast va sharpness (CLAHE)
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
    enhanced = clahe.apply(gray)
    # Biroz o'tkir qilish
    kernel = np.array([[0, -1, 0], [-1, 5, -1], [0, -1, 0]])
    sharpened = cv2.filter2D(enhanced, -1, kernel)
    return sharpened


def ocr_image_easyocr(image_path: str, langs: list = None) -> str:
    """EasyOCR orqali matn olish — ko'p tilni qo'llab-quvvatlaydi."""
    try:
        import easyocr
        if langs is None:
            langs = ["en", "ru"]  # UZ lotin uchun 'en' ishlatiladi
        reader = easyocr.Reader(langs, gpu=False)
        result = reader.readtext(image_path, detail=0, paragraph=True)
        return "\n".join(result)
    except Exception as e:
        return ocr_image_tesseract(image_path)


def ocr_image_tesseract(image_path: str) -> str:
    """Tesseract fallback."""
    try:
        import pytesseract
        enhanced = enhance_image(image_path)
        pil_img = Image.fromarray(enhanced)
        text = pytesseract.image_to_string(pil_img, lang="eng+rus")
        return text.strip()
    except Exception as e:
        return f"OCR xatosi: {str(e)}"


def ocr_pdf(pdf_path: str) -> str:
    """PDF fayldan matn olish (PyMuPDF)."""
    try:
        import fitz  # PyMuPDF
        doc = fitz.open(pdf_path)
        texts = []
        for page_num in range(len(doc)):
            page = doc.load_page(page_num)
            text = page.get_text("text")
            if text.strip():
                texts.append(f"--- Sahifa {page_num + 1} ---\n{text.strip()}")
            else:
                # Rasm sahifadan OCR
                pix = page.get_pixmap(dpi=200)
                img_path = f"/tmp/page_{page_num}.png"
                pix.save(img_path)
                ocr_text = ocr_image_easyocr(img_path)
                texts.append(f"--- Sahifa {page_num + 1} (OCR) ---\n{ocr_text}")
                os.remove(img_path)
        doc.close()
        return "\n\n".join(texts)
    except Exception as e:
        return f"PDF o'qish xatosi: {str(e)}"


def extract_text(file_path: str, file_type: str, enhance: bool = False) -> str:
    """Universal matn ajratish funksiyasi."""
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"Fayl topilmadi: {file_path}")

    if file_type == "pdf":
        return ocr_pdf(file_path)
    elif file_type in ("image", "jpg", "jpeg", "png"):
        if enhance:
            enhanced = enhance_image(file_path)
            tmp = "/tmp/enhanced_ocr.png"
            cv2.imwrite(tmp, enhanced)
            text = ocr_image_easyocr(tmp)
            os.remove(tmp)
            return text
        return ocr_image_easyocr(file_path)
    else:
        raise ValueError(f"Qo'llab-quvvatlanmaydigan fayl turi: {file_type}")
