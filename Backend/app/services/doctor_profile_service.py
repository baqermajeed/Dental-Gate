"""منطق دمج بروفايل الطبيب مع [User] وتحديثهما."""

import uuid
from datetime import datetime, timezone

from fastapi import HTTPException, status
from pymongo.errors import DuplicateKeyError

from app.models.doctor_profile import (
    ACCREDITED_COURSE_POINTS_EACH,
    ACCREDITED_COURSE_POINTS_MAX,
    AccreditedCourse,
    CertificateImage,
    DoctorProfile,
    EducationEntry,
    GalleryItem,
    PracticeLicense,
    PracticeLicenseStatus,
    WorkExperience,
)
from app.models.user import User
from app.schemas.doctor_profile import (
    AccreditedCourseSubmitIn,
    DoctorProfileFullOut,
    DoctorProfilePatch,
    PracticeLicenseSubmitIn,
)
from app.services.otp_service import iraqi_phone_for_display, normalize_iraqi_phone
from app.services import experience_score_service as experience_score_svc


async def _get_or_create_profile(user: User) -> DoctorProfile:
    dp = await DoctorProfile.find_one(DoctorProfile.user_id == user.id)
    if dp:
        return dp
    dp = DoctorProfile(user_id=user.id)
    await dp.insert()
    return dp


def _to_full_out(user: User, dp: DoctorProfile | None) -> DoctorProfileFullOut:
    if dp is None:
        return DoctorProfileFullOut(
            id=str(user.id),
            name=user.name,
            phone=iraqi_phone_for_display(user.phone),
            email=user.email,
            gender=user.gender,
            age=user.age,
            imageUrl=user.imageUrl,
            governorate=None,
            professional_title=None,
            bio=None,
            years_experience=None,
            languages=[],
            education=[],
            experiences=[],
            skill_ids=[],
            gallery=[],
            certificate_images=[],
            practice_license=None,
            accredited_courses=[],
            experience_score=None,
            experience_score_updated_at=None,
        )
    return DoctorProfileFullOut(
        id=str(user.id),
        name=user.name,
        phone=iraqi_phone_for_display(user.phone),
        email=user.email,
        gender=user.gender,
        age=user.age,
        imageUrl=user.imageUrl,
        governorate=dp.governorate,
        professional_title=dp.professional_title,
        bio=dp.bio,
        years_experience=dp.years_experience,
        languages=list(dp.languages),
        education=list(dp.education),
        experiences=list(dp.experiences),
        skill_ids=list(dp.skill_ids),
        gallery=list(dp.gallery),
        certificate_images=list(dp.certificate_images),
        practice_license=dp.practice_license,
        accredited_courses=list(dp.accredited_courses),
        experience_score=dp.experience_score,
        experience_score_updated_at=dp.experience_score_updated_at,
    )


def _accredited_course_points_earned(courses: list[AccreditedCourse]) -> int:
    total = sum(
        c.points_awarded
        for c in courses
        if c.status == PracticeLicenseStatus.APPROVED
    )
    return min(total, ACCREDITED_COURSE_POINTS_MAX)


async def get_merged_profile(user: User) -> DoctorProfileFullOut:
    dp = await experience_score_svc.recompute_and_persist_for_user(user.id)
    return _to_full_out(user, dp)


async def get_merged_profile_for_user(user: User) -> DoctorProfileFullOut:
    """بروفايل مدمج لأي مستخدم (قراءة فقط — يُستدعى من مسارات تتحقق من الصلاحية)."""
    dp = await experience_score_svc.recompute_and_persist_for_user(user.id)
    return _to_full_out(user, dp)


async def patch_merged_profile(
    user: User, payload: DoctorProfilePatch
) -> DoctorProfileFullOut:
    raw = payload.model_dump(exclude_unset=True)

    user_keys = {"name", "phone", "email", "gender", "age", "imageUrl"}
    profile_keys = {
        "governorate",
        "professional_title",
        "bio",
        "years_experience",
        "languages",
        "education",
        "experiences",
        "skill_ids",
        "gallery",
        "certificate_images",
    }

    if "name" in raw:
        user.name = raw["name"].strip() if raw["name"] else None
    if "phone" in raw:
        new_phone = normalize_iraqi_phone(str(raw["phone"]))
        current_phone_norm = normalize_iraqi_phone(user.phone or "")
        if new_phone != current_phone_norm:
            other = await User.find_one(User.phone == new_phone)
            if other is not None and other.id != user.id:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="رقم الهاتف مستخدم من قبل حساب آخر",
                )
        user.phone = new_phone
    if "email" in raw:
        new_email = str(raw["email"]).strip().lower()
        if new_email != (user.email or "").strip().lower():
            other = await User.find_one(User.email == new_email)
            if other is not None and other.id != user.id:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="البريد الإلكتروني مستخدم من قبل حساب آخر",
                )
        user.email = new_email
    if "gender" in raw:
        user.gender = raw["gender"]
    if "age" in raw:
        user.age = raw["age"]
    if "imageUrl" in raw:
        user.imageUrl = raw["imageUrl"]

    if any(k in raw for k in user_keys):
        user.updated_at = datetime.now(timezone.utc)
        try:
            await user.save()
        except DuplicateKeyError:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="رقم الهاتف أو البريد مستخدم من قبل حساب آخر",
            )

    prof_updates = {k: raw[k] for k in profile_keys if k in raw}
    if not prof_updates:
        dp = await DoctorProfile.find_one(DoctorProfile.user_id == user.id)
        return _to_full_out(user, dp)

    dp = await _get_or_create_profile(user)

    if "governorate" in prof_updates:
        dp.governorate = prof_updates["governorate"]
    if "professional_title" in prof_updates:
        dp.professional_title = (
            str(prof_updates["professional_title"]).strip()
            if prof_updates["professional_title"] is not None
            else None
        )
    if "bio" in prof_updates:
        dp.bio = prof_updates["bio"]
    if "years_experience" in prof_updates:
        dp.years_experience = prof_updates["years_experience"]
    if "languages" in prof_updates:
        dp.languages = list(prof_updates["languages"] or [])
    if "skill_ids" in prof_updates:
        dp.skill_ids = list(prof_updates["skill_ids"] or [])

    if "education" in prof_updates:
        dp.education = [
            EducationEntry(**x) for x in prof_updates["education"]
        ]
    if "experiences" in prof_updates:
        dp.experiences = [WorkExperience(**x) for x in prof_updates["experiences"]]
    if "gallery" in prof_updates:
        dp.gallery = [GalleryItem(**x) for x in prof_updates["gallery"]]
    if "certificate_images" in prof_updates:
        dp.certificate_images = [
            CertificateImage(**x) for x in prof_updates["certificate_images"]
        ]

    dp.updated_at = datetime.now(timezone.utc)
    await dp.save()
    dp = await experience_score_svc.recompute_and_persist_for_user(user.id)

    return _to_full_out(user, dp)


async def submit_practice_license(
    user: User, payload: PracticeLicenseSubmitIn
) -> DoctorProfileFullOut:
    """يرسل الطبيب شهادة ممارسة للمراجعة (أو يعيد الإرسال بعد الرفض)."""
    explanation = (payload.explanation or "").strip()
    if not explanation:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="أضف شرحاً مختصراً يساعد فريق المراجعة على التحقق",
        )
    image_url = (payload.image_url or "").strip()
    if not image_url:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="صورة الشهادة مطلوبة",
        )

    dp = await _get_or_create_profile(user)
    existing = dp.practice_license
    if existing is not None and existing.status == PracticeLicenseStatus.PENDING:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="طلبك قيد المراجعة حالياً. انتظر رد الإدارة.",
        )
    if existing is not None and existing.status == PracticeLicenseStatus.APPROVED:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="شهادة الممارسة موثّقة مسبقاً",
        )

    dp.practice_license = PracticeLicense(
        image_url=image_url,
        explanation=explanation,
        status=PracticeLicenseStatus.PENDING,
        rejection_reason=None,
        submitted_at=datetime.now(timezone.utc),
        reviewed_at=None,
    )
    dp.updated_at = datetime.now(timezone.utc)
    await dp.save()
    dp = await experience_score_svc.recompute_and_persist_for_user(user.id)
    return _to_full_out(user, dp)


async def submit_accredited_course(
    user: User, payload: AccreditedCourseSubmitIn
) -> DoctorProfileFullOut:
    """يرسل الطبيب دورة معتمدة للمراجعة."""
    title = (payload.title or "").strip()
    if not title:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="اسم الدورة مطلوب",
        )
    explanation = (payload.explanation or "").strip()
    if not explanation:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="أضف شرحاً مختصراً عن الدورة",
        )
    image_url = (payload.image_url or "").strip()
    if not image_url:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="صورة شهادة الدورة مطلوبة",
        )

    dp = await _get_or_create_profile(user)
    earned = _accredited_course_points_earned(dp.accredited_courses)
    if earned >= ACCREDITED_COURSE_POINTS_MAX:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="وصلت للحد الأقصى من نقاط الدورات المعتمدة",
        )

    pending = sum(
        1
        for c in dp.accredited_courses
        if c.status == PracticeLicenseStatus.PENDING
    )
    if pending >= 5:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="لديك عدة دورات قيد المراجعة. انتظر رد الإدارة.",
        )

    dp.accredited_courses.append(
        AccreditedCourse(
            id=uuid.uuid4().hex,
            title=title,
            image_url=image_url,
            explanation=explanation,
            status=PracticeLicenseStatus.PENDING,
            points_awarded=0,
            rejection_reason=None,
            submitted_at=datetime.now(timezone.utc),
            reviewed_at=None,
        )
    )
    dp.updated_at = datetime.now(timezone.utc)
    await dp.save()
    dp = await experience_score_svc.recompute_and_persist_for_user(user.id)
    return _to_full_out(user, dp)
