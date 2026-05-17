from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.models.job import JobEducation, JobLanguage, JobRequestStatus


class JobPostingCreateIn(BaseModel):
    workplace_name: str = Field(..., min_length=1)
    workplace_address: str = Field(..., min_length=1)
    required_specialty: str = Field(..., min_length=1)
    years_experience: int = Field(..., ge=0, le=80)
    monthly_salary_iqd: int | None = None
    shift_hours: int | None = Field(default=None, ge=0, le=24)
    working_hours: str = Field(..., min_length=1)
    description: str | None = None
    education: JobEducation
    languages: list[JobLanguage] = Field(default_factory=list)
    core_skills: list[str] = Field(default_factory=list)
    application_deadline: datetime | None = None


class JobPostingOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    posted_by: str
    workplace_name: str
    workplace_address: str
    required_specialty: str
    years_experience: int
    monthly_salary_iqd: int | None
    shift_hours: int | None
    working_hours: str
    description: str | None
    education: JobEducation
    languages: list[JobLanguage]
    core_skills: list[str]
    application_deadline: datetime | None
    status: JobRequestStatus
    created_at: datetime
    updated_at: datetime


class JobApplicationCountOut(BaseModel):
    """عدد طلبات التقديم على وظيفة (لصاحب الإعلان فقط)."""

    count: int = Field(..., ge=0)


class JobApplicantItemOut(BaseModel):
    """متقدّم واحد على وظيفة (لصاحب الإعلان فقط) — بيانات للبطاقة."""

    application_id: str
    status: JobRequestStatus
    user_id: str
    name: str | None = None
    phone: str
    email: str
    image_url: str | None = None
    years_experience: int | None = None
    governorate: str | None = None
    professional_title: str | None = None


class JobApplicationOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    job_id: str
    applicant_id: str
    status: JobRequestStatus
    created_at: datetime
    updated_at: datetime


class JobApplicationDecisionIn(BaseModel):
    """قرار صاحب الإعلان على طلب تقديم (قيد المراجعة أو قبول أو رفض)."""

    status: JobRequestStatus

    @field_validator("status")
    @classmethod
    def allowed_owner_statuses(cls, v: JobRequestStatus) -> JobRequestStatus:
        if v not in (
            JobRequestStatus.PENDING,
            JobRequestStatus.ACCEPTED,
            JobRequestStatus.REJECTED,
        ):
            raise ValueError("يجب أن تكون الحالة pending أو accepted أو rejected")
        return v


class MyJobApplicationOut(BaseModel):
    """طلب توظيف للمستخدم الحالي مع تفاصيل الوظيفة المعروضة في البطاقة."""

    id: str
    status: JobRequestStatus
    created_at: datetime
    updated_at: datetime
    job: JobPostingOut
