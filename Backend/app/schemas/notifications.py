from datetime import datetime, timezone
from enum import Enum

from pydantic import BaseModel, ConfigDict, Field, field_serializer, model_validator

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
    send_to_all: bool = Field(
        default=False,
        description="إن كانت true يتم الإرسال لكل مستخدمي التطبيق (dentist)",
    )
    recipient_user_ids: list[str] | None = Field(
        default=None,
        description="قائمة معرفات المستخدمين (نفس sub في JWT)",
    )

    @model_validator(mode="after")
    def _validate_targets(self) -> "AppAnnouncementCreateIn":
        if self.send_to_all:
            return self
        if not self.recipient_user_ids or len(self.recipient_user_ids) == 0:
            raise ValueError("recipient_user_ids is required when send_to_all is false")
        return self


class UnreadCountOut(BaseModel):
    total: int
    by_category: dict[str, int]
