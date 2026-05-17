from datetime import datetime, timezone

from beanie import Document
from pydantic import Field


class OTPRequest(Document):
    """طلبات OTP للتحقق من الهاتف مع انتهاء صلاحية وتجزئة الكود (مطابق لـ backend_farah)."""

    phone: str
    code_hash: str
    expires_at: datetime
    attempts: int = 0
    verified_at: datetime | None = None
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

    class Settings:
        name = "otp_requests"
