"""
Matn dastlabki ishlov berish (preprocessing):
- Ortiqcha belgilarni tozalash
- Whitespace normalizatsiya
- Lotin/Kirill transliteratsiya (UZ uchun)
- Stop-words filtri (ixtiyoriy)
"""
import re
import unicodedata

# UZ Kirill → Lotin jadval
CYRILLIC_TO_LATIN = {
    'а': 'a', 'б': 'b', 'в': 'v', 'г': 'g', 'д': 'd', 'е': 'ye', 'ё': 'yo',
    'ж': 'j', 'з': 'z', 'и': 'i', 'й': 'y', 'к': 'k', 'л': 'l', 'м': 'm',
    'н': 'n', 'о': 'o', 'п': 'p', 'р': 'r', 'с': 's', 'т': 't', 'у': 'u',
    'ф': 'f', 'х': 'x', 'ц': 'ts', 'ч': 'ch', 'ш': 'sh', 'щ': 'shch',
    'ъ': "'", 'ы': 'i', 'ь': "'", 'э': 'e', 'ю': 'yu', 'я': 'ya',
    'ў': "o'", 'қ': 'q', 'ғ': "g'", 'ҳ': 'h', 'ё': 'yo',
}


def transliterate_uz_cyrillic(text: str) -> str:
    """UZ Kirill → Lotin."""
    result = []
    for char in text:
        lower = char.lower()
        if lower in CYRILLIC_TO_LATIN:
            translit = CYRILLIC_TO_LATIN[lower]
            if char.isupper():
                translit = translit.capitalize()
            result.append(translit)
        else:
            result.append(char)
    return "".join(result)


def clean_text(text: str) -> str:
    """Asosiy tozalash."""
    if not text:
        return ""
    # Unicode normalizatsiya
    text = unicodedata.normalize("NFC", text)
    # HTML teglarni olib tashlash
    text = re.sub(r'<[^>]+>', ' ', text)
    # Bir nechta bo'sh joylarni bitta bo'sh joy bilan almashtirish
    text = re.sub(r'[ \t]+', ' ', text)
    # Bir nechta yangi qatorlarni ikkita bilan almashtirish
    text = re.sub(r'\n{3,}', '\n\n', text)
    # Boshidagi va oxiridagi bo'sh joylarni olib tashlash
    return text.strip()


def normalize_whitespace(text: str) -> str:
    """Whitespace normalizatsiya."""
    return re.sub(r'\s+', ' ', text).strip()


def preprocess_for_detection(text: str, mode: str = "auto") -> str:
    """
    Til aniqlash uchun matnni tayyorlash.
    mode: 'auto' — har xil yozuv, 'latin-only' — kirill → lotin
    """
    text = clean_text(text)
    if mode == "latin-only":
        text = transliterate_uz_cyrillic(text)
    text = normalize_whitespace(text)
    return text


def extract_sentences(text: str) -> list[str]:
    """Gaplarni ajratish."""
    sentences = re.split(r'(?<=[.!?])\s+', text.strip())
    return [s.strip() for s in sentences if len(s.strip()) > 10]
