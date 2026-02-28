#!/bin/bash
# BMI OCR+NLP — Backend Setup Skripti
# Diplom ishi: Shamsiddinova Muhabbat

set -e

echo "╔══════════════════════════════════════════╗"
echo "║     BMI OCR+NLP — Backend Setup          ║"
echo "║     Diplom ishi: Shamsiddinova Muhabbat  ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# Mavjud papkaga o'tish
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/backend"

echo "📦 1. Python paketlarini o'rnatish..."
python3 -m pip install --break-system-packages -r requirements.txt
echo "   ✅ Paketlar o'rnatildi"

echo ""
echo "📁 2. Kerakli papkalarni yaratish..."
mkdir -p uploads ml/models
echo "   ✅ Papkalar tayyor"

echo ""
echo "🤖 3. ML modelni o'rgatish (til aniqlash)..."
python3 ml/model_trainer.py --train
echo "   ✅ Model saqlandi"

echo ""
echo "🧪 4. ML modelni baholash..."
python3 ml/model_trainer.py --evaluate

echo ""
echo "⚙️  5. .env faylini tekshirish..."
if [ ! -f .env ]; then
  cp .env.example .env
  echo "   ⚠️  .env yaratildi — iltimos DATABASE_URL ni tahrirlang!"
  echo "      nano .env"
else
  echo "   ✅ .env mavjud"
fi

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║  ✅ Setup muvaffaqiyatli yakunlandi!     ║"
echo "╠══════════════════════════════════════════╣"
echo "║  Serverni ishga tushirish uchun:         ║"
echo "║  cd backend                              ║"
echo "║  uvicorn main:app --host 0.0.0.0 \\      ║"
echo "║         --port 8000 --reload             ║"
echo "║                                          ║"
echo "║  Swagger UI: http://localhost:8000/docs  ║"
echo "╚══════════════════════════════════════════╝"
