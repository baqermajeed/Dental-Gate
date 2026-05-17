from datetime import datetime, timezone

from beanie import Document, Indexed, PydanticObjectId
from pydantic import Field
from pymongo import IndexModel


class SavedJob(Document):
    user_id: Indexed(PydanticObjectId)
    job_id: Indexed(PydanticObjectId)
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    updated_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

    class Settings:
        name = "saved_jobs"
        indexes = [
            IndexModel([("user_id", 1), ("job_id", 1)], unique=True),
            IndexModel([("user_id", 1), ("created_at", -1)]),
        ]
