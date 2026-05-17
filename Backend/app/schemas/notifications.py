from datetime import datetime, timezone
from enum import Enum

from pydantic import BaseModel, ConfigDict, Field, field_serializer

from app.models.notification import InAppNotificationType


class NotificationCategoryQuery(str, Enum):
    """فلتر مطابق لتبويبات التطبيق."""

    all = "all"
    job_posting_application = "job_posting_application"
    my_application_status = "my_application_status"
    app_announcement = "app_announcement"


class UserNotificationOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    type: InAppNotificationType
    title: str
    body: str
    read: bool
    created_at: datetime
    job_id: str | None = None
    job_title: str | None = None
    actor_name: str | None = None
    application_status: str | None = None

    @field_serializer("created_at")
    def _created_at_utc_z(self, dt: datetime) -> str:
        """يضمن ISO8601 بـ Z حتى لا يفسر Flutter التاريخ كوقت محلي."""
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        else:
            dt = dt.astimezone(timezone.utc)
        return dt.isoformat().replace("+00:00", "Z")


class AppAnnouncementCreateIn(BaseModel):
    """إنشاء إشعار تطبيق من لوحة التحكم (مع مفتاح داخلي)."""

    title: str = Field(..., min_length=1)
    body: str = Field(..., min_length=1)
    recipient_user_ids: list[str] = Field(
        ...,
        min_length=1,
        description="قائمة معرفات المستخدمين (نفس sub في JWT)",
    )


class UnreadCountOut(BaseModel):
    total: int
    by_category: dict[str, int]
