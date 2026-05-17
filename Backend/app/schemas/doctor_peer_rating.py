"""مخططات تقييمات الأطباء."""

from datetime import datetime

from pydantic import BaseModel, Field, field_validator


class DoctorPeerRatingSubmitIn(BaseModel):
    stars: int = Field(..., ge=1, le=5)
    comment: str = Field(default="", max_length=200)

    @field_validator("comment", mode="before")
    @classmethod
    def strip_comment(cls, v):
        if v is None:
            return ""
        if isinstance(v, str):
            return v.strip()
        return v


class DoctorPeerRatingOut(BaseModel):
    id: str
    stars: int
    comment: str
    rater_user_id: str
    rater_name: str | None = None
    rater_image_url: str | None = None
    created_at: datetime


class DoctorPeerRatingsListOut(BaseModel):
    ratings: list[DoctorPeerRatingOut] = Field(default_factory=list)
    average_stars: float | None = None
    total_count: int = 0
    current_user_has_rated: bool = False
    current_user_rating: DoctorPeerRatingOut | None = None
    """عدد التقييمات التي أرسلها المستخدم الحالي لأطباء آخرين."""
    ratings_given_count: int = 0
