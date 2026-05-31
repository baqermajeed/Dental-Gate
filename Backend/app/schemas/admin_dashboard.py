from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

from app.models.doctor_profile import ExperienceTier, PracticeLicenseStatus
from app.models.job import JobRequestStatus


class DashboardKpiOut(BaseModel):
    total_dentists: int = 0
    new_dentists_last_30_days: int = 0
    dentists_with_fcm: int = 0
    total_jobs: int = 0
    active_jobs: int = 0
    expired_jobs: int = 0
    total_applications: int = 0
    pending_applications: int = 0
    accepted_applications: int = 0
    rejected_applications: int = 0
    pending_practice_licenses: int = 0
    pending_courses: int = 0
    unread_notifications: int = 0
    total_peer_ratings: int = 0
    avg_peer_rating: float = 0


class DashboardOverviewOut(BaseModel):
    generated_at: datetime
    kpis: DashboardKpiOut
    jobs_by_status: dict[str, int] = Field(default_factory=dict)
    applications_by_status: dict[str, int] = Field(default_factory=dict)
    users_by_governorate: dict[str, int] = Field(default_factory=dict)
    users_by_professional_title: dict[str, int] = Field(default_factory=dict)
    users_by_tier: dict[str, int] = Field(default_factory=dict)


class AdminUserListItemOut(BaseModel):
    id: str
    name: str | None = None
    phone: str
    email: str
    gender: str | None = None
    age: int | None = None
    governorate: str | None = None
    professional_title: str | None = None
    years_experience: int | None = None
    experience_tier: ExperienceTier | None = None
    jobs_posted_count: int = 0
    applications_count: int = 0
    saved_jobs_count: int = 0
    saved_doctors_count: int = 0
    created_at: datetime


class PaginatedAdminUsersOut(BaseModel):
    items: list[AdminUserListItemOut]
    total: int
    limit: int
    offset: int


class PracticeLicenseReviewItemOut(BaseModel):
    user_id: str
    user_name: str | None = None
    user_phone: str
    governorate: str | None = None
    professional_title: str | None = None
    image_url: str
    explanation: str
    status: PracticeLicenseStatus
    rejection_reason: str | None = None
    submitted_at: datetime
    reviewed_at: datetime | None = None


class AccreditedCourseReviewItemOut(BaseModel):
    user_id: str
    user_name: str | None = None
    user_phone: str
    governorate: str | None = None
    professional_title: str | None = None
    course_id: str
    title: str
    image_url: str
    explanation: str
    status: PracticeLicenseStatus
    points_awarded: int
    rejection_reason: str | None = None
    submitted_at: datetime
    reviewed_at: datetime | None = None


class VerificationQueueOut(BaseModel):
    practice_licenses: list[PracticeLicenseReviewItemOut]
    accredited_courses: list[AccreditedCourseReviewItemOut]


class ReviewDecisionIn(BaseModel):
    decision: PracticeLicenseStatus
    rejection_reason: str | None = Field(default=None, max_length=500)


class AdminJobListItemOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    workplace_name: str
    workplace_address: str
    required_specialty: str
    years_experience: int
    monthly_salary_iqd: int | None = None
    shift_hours: int | None = None
    working_hours: str
    description: str | None = None
    status: JobRequestStatus
    posted_by: str
    poster_name: str | None = None
    created_at: datetime
    updated_at: datetime
    application_deadline: datetime | None = None
    applications_count: int = 0
    accepted_count: int = 0
    pending_count: int = 0
    rejected_count: int = 0


class PaginatedAdminJobsOut(BaseModel):
    items: list[AdminJobListItemOut]
    total: int
    limit: int
    offset: int


class JobStatusUpdateIn(BaseModel):
    status: JobRequestStatus


class AnnouncementLogItemOut(BaseModel):
    created_at: datetime
    title: str
    body: str
    recipients_count: int

