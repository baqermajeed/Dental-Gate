from datetime import datetime, timezone
from enum import Enum

from beanie import Document, Indexed, PydanticObjectId
from pydantic import Field


class InAppNotificationType(str, Enum):
    """قيم حقل type متوافقة مع تطبيق Flutter / Firestore."""

    JOB_POSTING_APPLICATION = "job_posting_application"
    MY_APPLICATION_STATUS = "my_application_status"
    APP_ANNOUNCEMENT = "app_announcement"


class UserNotification(Document):
    """إشعار داخل التطبيق لمستخدم محدد (مصدر الحقيقة في MongoDB)."""

    recipient_id: Indexed(PydanticObjectId)
    type: InAppNotificationType

    title: str = ""
    body: str = ""
    read: bool = False

    job_id: PydanticObjectId | None = None
    job_title: str | None = None
    actor_name: str | None = None
    application_status: str | None = Field(
        default=None,
        description="accepted | rejected لنوع my_application_status",
    )
    related_application_id: PydanticObjectId | None = None

    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

    class Settings:
        name = "user_notifications"
