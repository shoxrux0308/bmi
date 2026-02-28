"""
Pytest tests — Backend API testlari
"""
import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from main import app


@pytest_asyncio.fixture
async def client():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as c:
        yield c


@pytest.mark.asyncio
async def test_root(client):
    response = await client.get("/")
    assert response.status_code == 200
    assert response.json()["app"] == "BMI OCR+NLP"


@pytest.mark.asyncio
async def test_health(client):
    response = await client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


@pytest.mark.asyncio
async def test_register_and_login(client):
    # Ro'yxatdan o'tish
    reg_resp = await client.post("/api/auth/register", json={
        "full_name": "Test Foydalanuvchi",
        "email": "test@example.com",
        "password": "TestPass123"
    })
    assert reg_resp.status_code in (201, 400)  # 400 agar allaqachon mavjud bo'lsa

    # Kirish
    login_resp = await client.post("/api/auth/login", json={
        "email": "test@example.com",
        "password": "TestPass123"
    })
    assert login_resp.status_code == 200
    data = login_resp.json()
    assert "access_token" in data


@pytest.mark.asyncio
async def test_language_detection_service():
    """ML servisni to'g'ridan-to'g'ri test qilish."""
    from app.services.language_detector import get_detector
    detector = get_detector()

    result = detector.detect("This is a simple English text for testing.")
    assert result["lang"] == "EN"
    assert result["confidence"] > 0.0

    result_ru = detector.detect("Это простой русский текст для тестирования системы.")
    assert result_ru["lang"] == "RU"


@pytest.mark.asyncio
async def test_nlp_service():
    """NLP tahlil servisini test qilish."""
    from app.services.nlp_service import analyze_text
    text = """
    Artificial intelligence is transforming the world of technology.
    Machine learning algorithms are being used in many applications.
    This is a test text to verify the NLP analysis system works correctly.
    """
    result = analyze_text(text)
    assert "summary" in result
    assert "keywords" in result
    assert "category" in result
    assert len(result["keywords"]) > 0
    assert result["word_count"] > 0
