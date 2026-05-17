"""بروفايل الطبيب — حقول موسّعة مرتبطة بحساب [User] (MongoDB / Beanie)."""

from datetime import date, datetime, timezone
from enum import Enum

from beanie import Document, Indexed, PydanticObjectId
from pydantic import BaseModel, Field


class DegreeType(str, Enum):
    """نوع الشهادة / التعليم."""

    DIPLOMA = "diploma"  # دبلوم
    BACHELOR = "bachelor"  # بكالوريوس
    MASTER = "master"  # ماجستير
    DOCTORATE = "doctorate"  # دكتوراه


class EducationEntry(BaseModel):
    degree_type: DegreeType
    specialty: str = Field(default="", description="التخصص")
    university: str = Field(..., min_length=1, description="الجامعة أو المعهد")
    start_year: int | None = Field(None, ge=1900, le=2100, description="سنة البداية")
    graduation_year: int | None = Field(
        None, ge=1900, le=2100, description="سنة التخرج"
    )
    graduation_date: date | None = Field(
        None, description="تاريخ التخرج (اختياري)"
    )


class WorkExperience(BaseModel):
    experience_type: str = Field(
        default="", description="نوع الخبرة (مثلاً: عيادة، مستشفى، تدريب)"
    )
    workplace: str = Field(default="", description="مكان العمل")
    period_start: date | None = Field(None, description="بداية فترة العمل")
    period_end: date | None = Field(None, description="نهاية فترة العمل (فارغ إن كانت مستمرة)")
    description: str | None = Field(
        None, description="نبذة أو شرح مبسط عن الخبرة"
    )


class GalleryItem(BaseModel):
    """مكتبة الصور: صورة أو صورتان مع شرح."""

    images: list[str] = Field(
        default_factory=list,
        description="روابط الصور (واحدة أو اثنتان كحد أقصى)",
    )
    caption: str = Field(default="", description="شرح أو وصف قصير")


class CertificateImage(BaseModel):
    """شهادة مرفوعة كصورة."""

    url: str = Field(..., min_length=1)
    title: str | None = Field(None, description="عنوان اختياري للشهادة")
    issuer: str | None = Field(None, description="مصدر الشهادة (مثلاً الجهة المانحة)")


class PracticeLicenseStatus(str, Enum):
    """حالة التحقق من شهادة ممارسة المهنة."""

    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"


# نقاط الدورات المعتمدة (تُمنح عند الموافقة الإدارية فقط).
ACCREDITED_COURSE_POINTS_EACH = 2
ACCREDITED_COURSE_POINTS_MAX = 10


class AccreditedCourse(BaseModel):
    """دورة معتمدة مرفوعة للتحقق — 2 نقطة لكل دورة معتمدة (حد أقصى 10)."""

    id: str = Field(..., min_length=1, description="معرّف فريد للطلب")
    title: str = Field(..., min_length=1, max_length=200)
    image_url: str = Field(..., min_length=1)
    explanation: str = Field(default="", max_length=2000)
    status: PracticeLicenseStatus = PracticeLicenseStatus.PENDING
    points_awarded: int = Field(default=0, ge=0, le=ACCREDITED_COURSE_POINTS_EACH)
    rejection_reason: str | None = None
    submitted_at: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc)
    )
    reviewed_at: datetime | None = None


class PracticeLicense(BaseModel):
    """طلب توثيق شهادة ممارسة المهنة — تُراجع إدارياً قبل احتساب النقاط."""

    image_url: str = Field(..., min_length=1)
    explanation: str = Field(
        default="",
        max_length=2000,
        description="شرح أو ملاحظات من الطبيب للمراجعة",
    )
    status: PracticeLicenseStatus = PracticeLicenseStatus.PENDING
    rejection_reason: str | None = Field(
        None, description="سبب الرفض (يظهر للطبيب)"
    )
    submitted_at: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc)
    )
    reviewed_at: datetime | None = None


class ExperienceTier(str, Enum):
    """تصنيف خبرة الطبيب حسب مجموع النقاط."""

    SILVER = "silver"
    GOLD = "gold"
    PLATINUM = "platinum"
    DIAMOND = "diamond"


class ExperienceTaskVerification(str, Enum):
    """حالة تحقق المهام التي تتطلب مراجعة إدارية."""

    NONE = "none"
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"


class ExperienceTaskScore(BaseModel):
    """تفصيل نقاط مهمة واحدة ضمن نظام الخبرة."""

    id: str = Field(..., min_length=1)
    title: str = Field(..., min_length=1)
    earned: int = Field(default=0, ge=0)
    max: int = Field(default=0, ge=0)
    coming_soon: bool = False
    verification: ExperienceTaskVerification = ExperienceTaskVerification.NONE
    opens_submit_dialog: bool = False


class ExperienceScoreSnapshot(BaseModel):
    """لقطة نقاط الخبرة المخزنة لطبيب معيّن."""

    total_earned: int = Field(default=0, ge=0)
    total_max: int = Field(default=0, ge=0)
    tier: ExperienceTier = ExperienceTier.SILVER
    tasks: list[ExperienceTaskScore] = Field(default_factory=list)
    peer_ratings_received: int = Field(default=0, ge=0)
    peer_ratings_given: int = Field(default=0, ge=0)
    computed_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))


class DoctorProfile(Document):
    """بيانات بروفايل الطبيب المرتبطة بمستخدم واحد."""

    user_id: Indexed(PydanticObjectId, unique=True)

    governorate: str | None = Field(None, description="المحافظة")
    professional_title: str | None = Field(None, description="تخصص الطبيب")
    bio: str | None = Field(None, description="نبذة تعريفية")
    years_experience: int | None = Field(
        None, ge=0, le=80, description="سنوات الخبرة"
    )

    languages: list[str] = Field(default_factory=list, description="لغات (واحدة أو أكثر)")
    education: list[EducationEntry] = Field(
        default_factory=list, description="شهادات / تعليم (واحدة أو أكثر)"
    )
    experiences: list[WorkExperience] = Field(
        default_factory=list, description="خبرات عمل"
    )
    skill_ids: list[str] = Field(
        default_factory=list,
        description="معرّفات مهارات من قائمة ثابتة (تُضاف لاحقاً)",
    )
    gallery: list[GalleryItem] = Field(
        default_factory=list, description="مكتبة الصور مع شرح"
    )
    certificate_images: list[CertificateImage] = Field(
        default_factory=list, description="مكتبة الشهادات (صور)"
    )
    practice_license: PracticeLicense | None = Field(
        None, description="شهادة ممارسة المهنة — مراجعة إدارية"
    )
    accredited_courses: list[AccreditedCourse] = Field(
        default_factory=list,
        description="دورات معتمدة — مراجعة إدارية",
    )
    experience_score: ExperienceScoreSnapshot | None = Field(
        None,
        description="النتيجة المخزنة لنظام نقاط الخبرة",
    )
    experience_score_updated_at: datetime | None = Field(
        None,
        description="آخر وقت تم فيه تحديث نقاط الخبرة",
    )

    created_at: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc)
    )
    updated_at: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc)
    )

    class Settings:
        name = "doctor_profiles"
