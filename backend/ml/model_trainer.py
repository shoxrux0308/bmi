"""
ML Model Trainer — Til aniqlash modeli
Tillar: UZ, RU, EN, QQ
Dataset: Wikipedia korpus + ixtiyoriy matn namunalari
Baholash: Precision, Recall, F1

Ishlatish:
  python ml/model_trainer.py --train    # Modelni o'rgatish
  python ml/model_trainer.py --evaluate # Modelni baholash
"""
import argparse
import json
import os
import re
from pathlib import Path
import numpy as np
import joblib
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.naive_bayes import MultinomialNB
from sklearn.pipeline import Pipeline
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, confusion_matrix

MODEL_DIR = Path(__file__).parent / "models"
MODEL_DIR.mkdir(exist_ok=True)

# Namuna datasetlar (haqiqiy loyihada katta korpus ishlatiladi)
SAMPLE_DATA = {
    "UZ": [
        "Bu kitob o'zbek tilida yozilgan va juda foydali hisoblanadi.",
        "O'zbekiston Respublikasi Markaziy Osiyoda joylashgan mustaqil davlat.",
        "Toshkent shahrida ko'plab tarixiy yodgorliklar mavjud.",
        "O'zbek xalqi qadimiy madaniyatga va boy tarixga ega.",
        "Maktabda o'quvchilar matematika, fizika va kimyo fanlarini o'rganadi.",
        "Iqtisodiyot sohasida ko'plab yangi imkoniyatlar paydo bo'lmoqda.",
        "Sog'liqni saqlash tizimini rivojlantirish davlatning asosiy vazifasidir.",
        "Yoshlar ta'lim olish uchun universitetlarga qabul qilinadi.",
        "Dehqonlar dalani haydab, urug' ekdilar va hosil yig'dilar.",
        "Kompyuter texnologiyalari kundalik hayotimizni tubdan o'zgartirdi.",
        "Milliy bayramlarimiz xalqimizni birlashtiradi va madaniyatimizni asraydi.",
        "Bolalar bog'chasida kichkintoylar o'ynab, rivojlanib boradilar.",
        "Sportchilarimiz xalqaro musobaqalarda oltin medallar qozondi.",
        "Yangi qonunlar iqtisodiy erkinlikni kengaytirishga qaratilgan.",
        "Tabiat go'zalligini asrash har bir insonning burchiga kiradi.",
    ],
    "RU": [
        "Россия является крупнейшей страной в мире по площади территории.",
        "Москва — столица Российской Федерации и крупнейший город страны.",
        "Образование является основным приоритетом государственной политики.",
        "Экономика страны демонстрирует устойчивый рост в последние годы.",
        "Научные исследования в области медицины достигли значительных результатов.",
        "Культурное наследие народов России отличается богатством и разнообразием.",
        "Технологии искусственного интеллекта внедряются во все сферы жизни.",
        "Правительство принимает меры по улучшению качества жизни граждан.",
        "Спортсмены страны успешно выступают на международных соревнованиях.",
        "Природные ресурсы требуют бережного отношения и рационального использования.",
        "Студенты университетов активно участвуют в научной деятельности.",
        "Развитие цифровой экономики является стратегическим приоритетом.",
        "Международное сотрудничество способствует развитию торговых отношений.",
        "Здравоохранение нуждается в постоянном совершенствовании и финансировании.",
        "История нашего народа насчитывает тысячелетия богатой культуры.",
    ],
    "EN": [
        "The United States of America is a federal republic consisting of 50 states.",
        "Artificial intelligence is transforming industries across the globe rapidly.",
        "Education is the cornerstone of a prosperous and democratic society.",
        "Technology companies are investing heavily in machine learning research.",
        "Climate change poses significant challenges to global sustainability efforts.",
        "The economy showed strong growth in the last quarter of the year.",
        "Scientific research has led to remarkable breakthroughs in medicine.",
        "International cooperation is essential for addressing global challenges.",
        "Students should develop critical thinking and problem-solving skills.",
        "The government introduced new policies to boost economic development.",
        "Sports play an important role in promoting health and social unity.",
        "Digital transformation is reshaping how businesses operate worldwide.",
        "Environmental protection requires coordinated action from all nations.",
        "Innovation and creativity drive progress in modern knowledge economy.",
        "Cultural diversity enriches societies and promotes mutual understanding.",
    ],
    "QQ": [
        "Qaraqalpaqstan Respublikasi O'zbekiston Respublikasının g'arbında jaylasqan.",
        "Nukus — Qaraqalpaqstanın paytaxti hám en úlken qalası.",
        "Qaraqalpaq xalqı bay tariyxqa hám mádeniyatqa iye.",
        "Bilim alıw - jaslar ushın en úlken mümkinshilik.",
        "Ekonomika tarawında jan'a mümkinshilikler payda bolmaqta.",
        "Meditsina xızmeti xalqtıń sáwlemetligin qorġaw ushın áhmiyet kasb etedi.",
        "Awıl xojalıġı elimizdińen tiykarġı tarawlarınan biri bolıp taboratıladi.",
        "Sport háreket insannıń densawlıġın bekkemlew ushın kerek.",
        "Mekteplerde oqıwshılar matematika, fizika hám tIL fánlerin úyrenedi.",
        "Texnologiyalar rawajlanıwı el turması sıpatın artırıwġa járdem beredi.",
    ],
}


def build_dataset():
    texts, labels = [], []
    for lang, samples in SAMPLE_DATA.items():
        texts.extend(samples)
        labels.extend([lang] * len(samples))
    return texts, labels


def train_model():
    print("📚 Dataset tayyorlanmoqda...")
    texts, labels = build_dataset()

    X_train, X_test, y_train, y_test = train_test_split(
        texts, labels, test_size=0.2, random_state=42, stratify=labels
    )

    print("🔧 TF-IDF + Naive Bayes o'rgatilmoqda...")
    vectorizer = TfidfVectorizer(
        analyzer="char_wb",
        ngram_range=(2, 4),
        max_features=50000,
        sublinear_tf=True,
        min_df=1,
    )
    model = MultinomialNB(alpha=0.1)

    X_train_vec = vectorizer.fit_transform(X_train)
    model.fit(X_train_vec, y_train)

    # Baholash
    X_test_vec = vectorizer.transform(X_test)
    y_pred = model.predict(X_test_vec)
    print("\n📊 Baholash natijalari:")
    print(classification_report(y_test, y_pred, target_names=model.classes_))

    # Saqlash
    joblib.dump(model, MODEL_DIR / "lang_model.joblib")
    joblib.dump(vectorizer, MODEL_DIR / "tfidf_vectorizer.joblib")
    print(f"\n✅ Model saqlandi: {MODEL_DIR}")

    # Metrikalari JSON formatda
    from sklearn.metrics import precision_recall_fscore_support
    p, r, f1, _ = precision_recall_fscore_support(y_test, y_pred, average="weighted")
    metrics = {"precision": round(p, 4), "recall": round(r, 4), "f1_score": round(f1, 4)}
    with open(MODEL_DIR / "metrics.json", "w") as fp:
        json.dump(metrics, fp, indent=2)
    print(f"Metrikalari: {metrics}")


def evaluate_model():
    if not (MODEL_DIR / "lang_model.joblib").exists():
        print("❌ Model topilmadi. Avval --train bajaring.")
        return
    model = joblib.load(MODEL_DIR / "lang_model.joblib")
    vectorizer = joblib.load(MODEL_DIR / "tfidf_vectorizer.joblib")

    test_cases = [
        ("Salom, bu o'zbek tilida yozilgan matn.", "UZ"),
        ("Привет, это текст на русском языке.", "RU"),
        ("Hello, this is text written in English.", "EN"),
        ("Sálem, bul mátinQaraqalpaq tilinde jazılġan.", "QQ"),
    ]

    print("🧪 Test natijalari:")
    correct = 0
    for text, expected in test_cases:
        vec = vectorizer.transform([text])
        pred = model.predict(vec)[0]
        proba = model.predict_proba(vec)[0]
        conf = max(proba)
        status = "✅" if pred == expected else "❌"
        print(f"  {status} Kutilgan: {expected}, Aniqlangan: {pred} ({conf:.2%})")
        if pred == expected:
            correct += 1
    print(f"\nAniqlik: {correct}/{len(test_cases)} = {correct/len(test_cases):.0%}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Til aniqlash modeli")
    parser.add_argument("--train", action="store_true", help="Modelni o'rgatish")
    parser.add_argument("--evaluate", action="store_true", help="Modelni baholash")
    args = parser.parse_args()

    if args.train:
        train_model()
    elif args.evaluate:
        evaluate_model()
    else:
        print("Foydalanish: python model_trainer.py --train | --evaluate")
