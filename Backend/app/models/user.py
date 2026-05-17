from datetime import datetime, timezone

from beanie import Document, Indexed
from pydantic import Field

from app.constants import Role


class User(Document):
    """طبيب أسنان في التطبيق — تسجيل الدخول عبر رقم الهاتف + OTP فقط."""

    name: str | None = None
    phone: Indexed(str, unique=True)
    email: Indexed(str, unique=True)
    role: Role = Role.DENTIST
    gender: str | None = None  # "male" | "female"
    age: int | None = None
    imageUrl: str | None = None

    fcm_token: str | None = None
    fcm_token_updated_at: datetime | None = None

    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    updated_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

    class Settings:
        name = "users"
