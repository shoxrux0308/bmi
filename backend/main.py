import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from contextlib import asynccontextmanager
from app.core.database import engine, Base
from app.core.config import get_settings
from app.api.endpoints import auth, analysis, history, admin, feedback
import app.models.user       # noqa — register models
import app.models.history    # noqa
import app.models.feedback   # noqa

settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Tablitsalarni yaratish
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    # Upload papkasini yaratish
    os.makedirs(settings.upload_dir, exist_ok=True)
    yield


app = FastAPI(
    title="BMI OCR+NLP API",
    description=(
        "Sun'iy intellekt yordamida rasm/matnlarni tahlil qiluvchi tizim.\n"
        "OCR + Til aniqlash + NLP (xulosa, kalit so'zlar, kategoriya).\n\n"
        "**Diplom ishi** — Shamsiddinova Muhabbat"
    ),
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
)

# CORS — Flutter lokali uchun
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Routerlarni qo'shish
app.include_router(auth.router)
app.include_router(analysis.router)
app.include_router(history.router)
app.include_router(admin.router)
app.include_router(feedback.router)


@app.get("/", tags=["Root"])
async def root():
    return {
        "app": "BMI OCR+NLP",
        "version": "1.0.0",
        "author": "Shamsiddinova Muhabbat",
        "docs": "/docs",
    }


@app.get("/health", tags=["Root"])
async def health():
    return {"status": "ok"}
