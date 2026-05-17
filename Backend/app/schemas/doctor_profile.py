"""مخططات طلب/استجابة بروفايل الطبيب."""

from datetime import date, datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator

from app.models.doctor_profile import (
    AccreditedCourse,
    CertificateImage,
    DegreeType,
    EducationEntry,
    ExperienceScoreSnapshot,
    GalleryItem,
    PracticeLicense,
    PracticeLicenseStatus,
    WorkExperience,
)


class EducationEntryIn(BaseModel):
    degree_type: DegreeType
    specialty: str = ""
    university: str = Field(..., min_length=1)
    start_year: int | None = Field(None, ge=1900, le=2100)
    graduation_year: int | None = Field(None, ge=1900, le=2100)
    graduation_date: date | None = None


class WorkExperienceIn(BaseModel):
    experience_type: str = ""
    workplace: str = ""
    period_start: date | None = None
    period_end: date | None = None
    description: str | None = None


class GalleryItemIn(BaseModel):
    images: list[str] = Field(default_factory=list)
    caption: str = ""

    @field_validator("images")
    @classmethod
    def at_most_two_images(cls, v: list[str]) -> list[str]:
        if len(v) > 2:
            raise ValueError("يُسمح بصورتين كحد أقصى لكل عنصر في مكتبة الصور")
        if any(not (u or "").strip() for u in v):
            raise ValueError("روابط الصور يجب أن تكون غير فارغة")
        return v


class CertificateImageIn(BaseModel):
    url: str = Field(..., min_length=1)
    title: str | None = None
    issuer: str | None = None


class PracticeLicenseSubmitIn(BaseModel):
    """إرسال شهادة ممارسة للتحقق."""

    image_url: str = Field(..., min_length=1)
    explanation: str = Field(default="", max_length=2000)

    @field_validator("explanation", mode="before")
    @classmethod
    def strip_explanation(cls, v):
        if v is None:
            return ""
        if isinstance(v, str):
            return v.strip()
        return v


class AccreditedCourseSubmitIn(BaseModel):
    """إرسال دورة معتمدة للتحقق."""

    title: str = Field(..., min_length=1, max_length=200)
    image_url: str = Field(..., min_length=1)
    explanation: str = Field(default="", max_length=2000)

    @field_validator("title", "explanation", mode="before")
    @classmethod
    def strip_strings(cls, v):
        if v is None:
            return ""
        if isinstance(v, str):
            return v.strip()
        return v


class DoctorProfilePatch(BaseModel):
    """تحديث جزئي: الحقول غير المرسلة تُترك كما هي."""

    model_config = ConfigDict(extra="forbid")

    # يُحدّث جدول المستخدم [User] عند التمرير
    name: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[EmailStr] = None
    gender: Optional[str] = Field(None, description="male أو female")
    age: Optional[int] = Field(None, ge=1, le=120)
    imageUrl: Optional[str] = Field(None, description="صورة الطبيب (رابط)")

    governorate: Optional[str] = None
    professional_title: Optional[str] = None
    bio: Optional[str] = None
    years_experience: Optional[int] = Field(None, ge=0, le=80)

    languages: Optional[list[str]] = None
    education: Optional[list[EducationEntryIn]] = None
    experiences: Optional[list[WorkExperienceIn]] = None
    skill_ids: Optional[list[str]] = None
    gallery: Optional[list[GalleryItemIn]] = None
    certificate_images: Optional[list[CertificateImageIn]] = None

    @field_validator(
        "name",
        "professional_title",
        "governorate",
        "bio",
        mode="before",
    )
    @classmethod
    def strip_optional_strings(cls, v):
        if v is None:
            return None
        if isinstance(v, str):
            s = v.strip()
            return s if s else None
        return v

    @field_validator("phone", mode="before")
    @classmethod
    def strip_phone(cls, v):
        if v is None:
            return None
        if isinstance(v, str):
            return v.strip()
        return v

    @field_validator("email", mode="before")
    @classmethod
    def empty_email_to_none(cls, v):
        if v is None:
            return None
        if isinstance(v, str) and not v.strip():
            return None
        return str(v).strip().lower() if isinstance(v, str) else v


class DoctorProfileFullOut(BaseModel):
    """بروفايل كامل: بيانات الحساب + بروفايل الطبيب."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    name: Optional[str] = None
    phone: str
    email: str
    gender: Optional[str] = None
    age: Optional[int] = None
    imageUrl: Optional[str] = None

    governorate: Optional[str] = None
    professional_title: Optional[str] = None
    bio: Optional[str] = None
    years_experience: Optional[int] = None

    languages: list[str] = Field(default_factory=list)
    education: list[EducationEntry] = Field(default_factory=list)
    experiences: list[WorkExperience] = Field(default_factory=list)
    skill_ids: list[str] = Field(default_factory=list)
    gallery: list[GalleryItem] = Field(default_factory=list)
    certificate_images: list[CertificateImage] = Field(default_factory=list)
    practice_license: PracticeLicense | None = None
    accredited_courses: list[AccreditedCourse] = Field(default_factory=list)
    experience_score: ExperienceScoreSnapshot | None = None
    experience_score_updated_at: datetime | None = None


class DoctorSearchItemOut(BaseModel):
    """عنصر طبيب في نتائج البحث."""

    id: str
    name: Optional[str] = None
    professional_title: str | None = None
    imageUrl: Optional[str] = None
    years_experience: Optional[int] = None
    governorate: Optional[str] = None
    phone: str


class UploadOut(BaseModel):
    url: str
    filename: str
