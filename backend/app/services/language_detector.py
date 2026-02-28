"""
ML Language Detector — TF-IDF + Naive Bayes
Tillar: UZ (o'zbek), RU (rus), EN (ingliz), QQ (qoraqalpoq)

Agar model mavjud bo'lsa, ishlatadi.
Aks holda — heuristic fallback ishlatiladi.
"""
import os
import re
import json
import joblib
import numpy as np
from pathlib import Path

MODEL_PATH = Path(__file__).parent.parent.parent / "ml" / "models" / "lang_model.joblib"
VECTORIZER_PATH = Path(__file__).parent.parent.parent / "ml" / "models" / "tfidf_vectorizer.joblib"

# Heuristic patterns: til aniqlash harf statistikasiga asoslangan
LANG_PATTERNS = {
    "UZ": re.compile(r"[o'ʻgʻqhO'ʻGʻQH]|sh|ch|ng|ov|lar|lik|dan|ga|ni|bilan|va|ham|bo|qil|mas|yoq", re.IGNORECASE),
    "RU": re.compile(r"[ёЁыЫъЪьЬэЭ]|что|для|это|как|при|не|на|по|из|или|также|только", re.IGNORECASE),
    "EN": re.compile(r"\bthe\b|\band\b|\bof\b|\bto\b|\ba\b|\bis\b|\bin\b|\bthat\b|\bit\b|\bfor\b", re.IGNORECASE),
    "QQ": re.compile(r"болады|деп|бул|менен|ушын|қарай|барды|айтты|турады|қоям", re.IGNORECASE),
}

CYRILLIC = re.compile(r'[а-яёА-ЯЁ]')
LATIN = re.compile(r'[a-zA-Z]')
UZ_SPECIFIC = re.compile(r"[o'ʻO'ʻ]|sh|ch|ov|lar|lik|dan|ga|ni", re.IGNORECASE)
RU_SPECIFIC = re.compile(r'[ыЫъЪьЬэЭёЁ]|для|что|это', re.IGNORECASE)


class LanguageDetector:
    def __init__(self):
        self.model = None
        self.vectorizer = None
        self._load_model()

    def _load_model(self):
        """Saqlangan modelni yuklash."""
        try:
            if MODEL_PATH.exists() and VECTORIZER_PATH.exists():
                self.model = joblib.load(MODEL_PATH)
                self.vectorizer = joblib.load(VECTORIZER_PATH)
        except Exception:
            self.model = None
            self.vectorizer = None

    def _heuristic_detect(self, text: str) -> tuple[str, float]:
        """
        Heuristic til aniqlash — ML model mavjud bo'lmaganda.
        Kirill/Lotin nisbati va xarakterli so'zlarga asoslangan.
        """
        text_sample = text[:500]
        cyrillic_count = len(CYRILLIC.findall(text_sample))
        latin_count = len(LATIN.findall(text_sample))
        total = cyrillic_count + latin_count or 1

        scores = {}
        for lang, pattern in LANG_PATTERNS.items():
            scores[lang] = len(pattern.findall(text)) * 10

        if cyrillic_count / total > 0.6:
            ru_specific = len(RU_SPECIFIC.findall(text_sample))
            if ru_specific > 3:
                scores["RU"] = scores.get("RU", 0) + 30
            else:
                scores["UZ"] = scores.get("UZ", 0) + 20
                scores["QQ"] = scores.get("QQ", 0) + 10
        elif latin_count / total > 0.6:
            uz_feature = len(UZ_SPECIFIC.findall(text_sample))
            if uz_feature > 2:
                scores["UZ"] = scores.get("UZ", 0) + 30
            else:
                scores["EN"] = scores.get("EN", 0) + 25

        if not scores or max(scores.values()) == 0:
            return "EN", 0.50

        best_lang = max(scores, key=scores.get)
        total_score = sum(scores.values()) or 1
        confidence = round(min(scores[best_lang] / total_score, 1.0), 4)
        return best_lang, max(confidence, 0.55)

    def detect(self, text: str, mode: str = "auto") -> dict:
        """
        Til aniqlash:
        - mode='auto': har xil yozuv (kirill/lotin aralash)
        - mode='latin-only': oldin transliteratsiya, keyin aniqlash
        """
        from app.services.text_preprocessor import preprocess_for_detection
        processed = preprocess_for_detection(text, mode=mode)

        if self.model is not None and self.vectorizer is not None:
            try:
                vec = self.vectorizer.transform([processed])
                proba = self.model.predict_proba(vec)[0]
                classes = self.model.classes_
                best_idx = np.argmax(proba)
                return {
                    "lang": classes[best_idx],
                    "confidence": round(float(proba[best_idx]), 4),
                    "all_scores": {cls: round(float(p), 4) for cls, p in zip(classes, proba)},
                    "method": "ml"
                }
            except Exception:
                pass

        # Fallback: heuristic
        lang, conf = self._heuristic_detect(text)
        return {
            "lang": lang,
            "confidence": conf,
            "all_scores": {},
            "method": "heuristic"
        }


# Singleton
_detector = None

def get_detector() -> LanguageDetector:
    global _detector
    if _detector is None:
        _detector = LanguageDetector()
    return _detector
