"""
NLP Service — Matn tahlili:
- Extractive Summarization (TF-IDF asosida top gaplar)
- Keyword extraction (RAKE + TF-IDF)
- Kategoriya classificatsiyasi (rule-based + ML)
"""
import re
import math
from collections import Counter
from typing import Optional
from textblob import TextBlob
from googletrans import Translator
from app.services.text_preprocessor import extract_sentences, normalize_whitespace, clean_text

# Kategoriya kalit so'zlari
CATEGORY_KEYWORDS = {
    "Ta'lim": ["talaba", "o'qituvchi", "maktab", "universitet", "ta'lim", "kurs", "dars",
                "студент", "учитель", "школа", "образование", "курс",
                "student", "teacher", "school", "university", "education", "course"],
    "Texnika": ["dastur", "kompyuter", "internet", "texnologiya", "sistema", "kod", "server",
                "программа", "компьютер", "технология", "система",
                "software", "computer", "technology", "system", "code", "server", "data"],
    "Yangilik": ["yangilik", "xabar", "voqea", "siyosat", "iqtisod", "hukumat", "prezident",
                 "новость", "событие", "политика", "правительство",
                 "news", "event", "politics", "government", "report"],
    "Huquq": ["qonun", "huquq", "sud", "jinoyat", "shartnoma", "fuqaro",
               "закон", "право", "суд", "договор", "гражданин",
               "law", "legal", "court", "contract", "citizen", "rights"],
    "Tibbiyot": ["kasallik", "davolash", "shifoxona", "tabib", "dori", "sog'liq",
                  "болезнь", "лечение", "больница", "врач", "лекарство", "здоровье",
                  "disease", "treatment", "hospital", "doctor", "medicine", "health"],
    "Iqtisod": ["iqtisod", "pul", "soliq", "savdo", "biznes", "bank", "investitsiya",
                 "экономика", "деньги", "налог", "торговля", "бизнес", "банк",
                 "economy", "money", "tax", "trade", "business", "bank", "investment"],
    "Sport": ["futbol", "basketbol", "chempionat", "sport", "o'yinchi", "musobaqa",
               "футбол", "баскетбол", "чемпионат", "спорт", "игрок",
               "football", "basketball", "championship", "sport", "player", "match"],
    "Boshqa": [],
}


def tfidf_sentence_scores(sentences: list[str]) -> dict[int, float]:
    """TF-IDF asosida gap ahamiyatini hisoblash."""
    if not sentences:
        return {}

    # So'zlarni tokenize qilish
    word_counts_per_sentence = []
    all_words = Counter()
    for sent in sentences:
        words = re.findall(r'\b\w+\b', sent.lower())
        wc = Counter(words)
        word_counts_per_sentence.append(wc)
        all_words.update(set(words))

    n = len(sentences)
    scores = {}
    for i, wc in enumerate(word_counts_per_sentence):
        score = 0.0
        total_words = sum(wc.values()) or 1
        for word, count in wc.items():
            tf = count / total_words
            idf = math.log((n + 1) / (all_words[word] + 1)) + 1
            score += tf * idf
        scores[i] = score
    return scores


def extractive_summary(text: str, num_sentences: int = 3) -> str:
    """Eng muhim 3 gapni qaytarish."""
    sentences = extract_sentences(text)
    if not sentences:
        return text[:300] + "..." if len(text) > 300 else text
    if len(sentences) <= num_sentences:
        return " ".join(sentences)

    scores = tfidf_sentence_scores(sentences)
    top_indices = sorted(scores, key=scores.get, reverse=True)[:num_sentences]
    top_indices_sorted = sorted(top_indices)
    summary_sentences = [sentences[i] for i in top_indices_sorted]
    return " ".join(summary_sentences)


def extract_keywords(text: str, top_n: int = 10) -> list[str]:
    """TF-IDF asosida top kalit so'zlar."""
    words = re.findall(r'\b[a-zA-ZА-Яа-яёЁO\'o\'ʻʼ]{3,}\b', text.lower())
    if not words:
        return []

    # Stop words (minimal)
    stop_words = {
        "the", "and", "for", "this", "that", "with", "are", "was", "were",
        "have", "has", "been", "dari", "bilan", "uchun", "ham", "va", "bir",
        "для", "это", "что", "как", "при", "не", "на", "по", "из", "или",
        "dan", "bir", "bu", "ular", "men", "sen", "biz", "edi", "deb"
    }
    filtered = [w for w in words if w not in stop_words and len(w) > 3]
    freq = Counter(filtered)
    return [word for word, _ in freq.most_common(top_n)]


def classify_category(text: str) -> str:
    """Matnni kategoriyaga ajratish (rule-based)."""
    text_lower = text.lower()
    category_scores = {}
    for category, keywords in CATEGORY_KEYWORDS.items():
        if category == "Boshqa":
            continue
        score = sum(1 for kw in keywords if kw.lower() in text_lower)
        if score > 0:
            category_scores[category] = score

    if not category_scores:
        return "Boshqa"
    return max(category_scores, key=category_scores.get)


def extract_sentiment(text: str) -> dict:
    """Hissiyot tahlili: TextBlob orqali polarity (-1 to 1) va turini aniqlash."""
    try:
        blob = TextBlob(text)
        # Ingliz tilidan foydalanib tahlil qilish imkoniyati balandroq aniqlikka olib keladi
        # Shuning uchun agar matn UZ/RU bo'lsa Translator bilan ishlatgan yaxshiroq (biz tarjimani translate_text funksiyasidan olamiz)
        polarity = blob.sentiment.polarity
        
        if polarity > 0.1:
            label = "Positive (Ijobiy)"
            emoji = "😊"
        elif polarity < -0.1:
            label = "Negative (Salbiy)"
            emoji = "😞"
        else:
            label = "Neutral (Neytral)"
            emoji = "😐"
            
        return {
            "score": round(polarity, 2),
            "label": label,
            "emoji": emoji
        }
    except Exception as e:
        return {"score": 0.0, "label": "Neutral (Neytral)", "emoji": "😐"}

def extract_ner(text: str) -> list[str]:
    """Ismlar va joy nomlarini topish (eng yirik harfli so'zlardan oddiy heuristic variant)."""
    # Katta harf bilan boshlangan, lekin gapning boshi bo'lmagan so'zlarni yoki birikmalarni izlash.
    matches = re.findall(r'(?<!^)(?<!\.\s)[A-ZА-ЯЁ][a-zа-яёO\'o\'ʻʼ]+(?:\s[A-ZА-ЯЁ][a-zа-яёO\'o\'ʻʼ]+)*', text)
    # Noyob ismlarni olish va qisqalarini tashlash
    entities = list(set([m.strip() for m in matches if len(m.strip()) > 3]))
    return entities[:15] # Ko'pi bilan 15 ta

def translate_text(text: str, dest_lang: str = 'uz') -> str:
    """Matnni ko'rsatilgan tilga tarjima qilish."""
    try:
        translator = Translator()
        # Matn uzundan so'ng 3000 belgidan ortig'ini tarjima qilmaymiz (API limiti uchun)
        truncated_text = text[:3000] if len(text) > 3000 else text
        translated = translator.translate(truncated_text, dest=dest_lang)
        return translated.text
    except Exception as e:
        return f"Tarjima xatosi: {str(e)}"

def analyze_text(text: str, target_translation='uz') -> dict:
    """
    To'liq matn tahlili:
    - Extractive summary
    - Top-10 keywords
    - Kategoriya
    - Sentiment (Hissiyot)
    - Entities (NER)
    - Translation
    """
    cleaned = clean_text(text)
    
    # 1. Asosiy NLP xususiyatlar
    summary = extractive_summary(cleaned, num_sentences=3)
    keywords = extract_keywords(cleaned, top_n=10)
    category = classify_category(cleaned)
    sentiment = extract_sentiment(cleaned)
    entities = extract_ner(text)  # Asl text orqali (Katta harflarni yo'qotmaslik uchun)
    
    # 2. Tarjima qilish (Faqat xulosa va asosiy qism)
    translated_summary = translate_text(summary, dest_lang=target_translation)
    
    return {
        "summary": summary,
        "translated_summary": translated_summary,
        "sentiment": sentiment,
        "entities": entities,
        "keywords": keywords,
        "category": category,
        "word_count": len(re.findall(r'\b\w+\b', cleaned)),
        "sentence_count": len(extract_sentences(cleaned)),
    }
