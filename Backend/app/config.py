from functools import lru_cache
import os
from typing import List

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """إعدادات التطبيق (نفس أسماء المتغيرات المستخدمة في backend_farah لـ OTPIQ و JWT و Mongo)."""

    APP_NAME: str = "dental_gate_api"
    APP_ENV: str = "dev"
    APP_DEBUG: bool = True

    MONGODB_URI: str = "mongodb://localhost:27017/dental_gate_db"

    JWT_SECRET: str = "dental_gate_change_me_in_production"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30

    CORS_ORIGINS: str | None = None

    OTPIQ_API_KEY: str | None = None
    OTPIQ_BASE_URL: str | None = None
    OTP_TTL_SECONDS: int = 120

    # رفع صور بروفايل الطبيب (مسار نسبي من جذر تشغيل التطبيق)
    UPLOAD_DIR: str = "uploads"
    UPLOAD_MAX_BYTES: int = 5 * 1024 * 1024  # 5 MB

    # مفتاح لمسار إنشاء «أشعارات التطبيق» من لوحة التحكم (رأس X-Internal-Notifications-Key)
    INTERNAL_NOTIFICATIONS_KEY: str | None = None

    # مسار ملف JSON لمفتاح حساب الخدمة (Firebase Console → Project settings → Service accounts)
    # مثال: C:/secrets/dental-gate-notif-firebase-adminsdk.json
    FIREBASE_SERVICE_ACCOUNT_JSON: str | None = None

    class Config:
        env_file = ".env"
        case_sensitive = False

    @property
    def cors_origins(self) -> List[str]:
        raw = self.CORS_ORIGINS or os.getenv("CORS_ORIGINS", "") or ""
        return [o.strip() for o in raw.split(",") if o.strip()]


@lru_cache()
def get_settings() -> Settings:
    return Settings()
