"""تقييمات الأطباء لبعضهم — تقييم واحد لكل زوج (مُقيّم → مُقيَّم)."""

from datetime import datetime, timezone

from beanie import Document, Indexed
from pydantic import Field
from pymongo import IndexModel

from beanie import PydanticObjectId


class DoctorPeerRating(Document):
    """تقييم طبيب من طبيب آخر — يُعرض فوراً دون مراجعة إدارية."""

    target_user_id: Indexed(PydanticObjectId)
    rater_user_id: Indexed(PydanticObjectId)
    stars: int = Field(..., ge=1, le=5)
    comment: str = Field(default="", max_length=200)
    rater_name: str | None = None
    rater_image_url: str | None = None
    created_at: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc)
    )

    class Settings:
        name = "doctor_peer_ratings"
        indexes = [
            IndexModel(
                [("target_user_id", 1), ("rater_user_id", 1)],
                unique=True,
            ),
        ]
