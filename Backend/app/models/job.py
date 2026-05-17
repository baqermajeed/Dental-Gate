from datetime import datetime, timezone
from enum import Enum

from beanie import Document, Indexed, PydanticObjectId
from pydantic import Field


class JobRequestStatus(str, Enum):
    PENDING = "pending"
    ACCEPTED = "accepted"
    REJECTED = "rejected"


class JobEducation(str, Enum):
    DIPLOMA = "diploma"
    BACHELOR = "bachelor"
    MASTER = "master"
    DOCTORATE = "doctorate"


class JobLanguage(str, Enum):
    ARABIC = "arabic"
    ENGLISH = "english"


class JobPosting(Document):
    posted_by: Indexed(PydanticObjectId)

    workplace_name: str = Field(..., min_length=1)
    workplace_address: str = Field(..., min_length=1)
    required_specialty: str = Field(..., min_length=1)
    years_experience: int = Field(..., ge=0, le=80)
    monthly_salary_iqd: int | None = Field(
        default=None,
        ge=0,
        description="راتب شهري بالدينار العراقي (لعرض الشارة في الشاشة).",
    )
    shift_hours: int | None = Field(
        default=None,
        ge=0,
        le=24,
        description="عدد ساعات الوردية أو اليوم (مثل 12 لعرض «12 ساعة»).",
    )
    working_hours: str = Field(..., min_length=1)
    description: str | None = Field(
        default=None,
        description="نص تعريفي اختياري عن الوظيفة (حول الوظيفة).",
    )
    education: JobEducation
    languages: list[JobLanguage] = Field(default_factory=list)
    core_skills: list[str] = Field(default_factory=list)
    application_deadline: datetime | None = Field(
        default=None,
        description="آخر موعد للتقديم على الوظيفة (UTC).",
    )

    status: JobRequestStatus = JobRequestStatus.PENDING
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    updated_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

    class Settings:
        name = "job_postings"


class JobApplication(Document):
    job_id: Indexed(PydanticObjectId)
    applicant_id: Indexed(PydanticObjectId)

    status: JobRequestStatus = JobRequestStatus.PENDING
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    updated_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

    class Settings:
        name = "job_applications"
