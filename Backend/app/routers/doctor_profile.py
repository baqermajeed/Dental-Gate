"""بروفايل الطبيب — قراءة وتحديث ورفع صور."""

import uuid
from pathlib import Path

from beanie import PydanticObjectId
from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile, status

from app.config import get_settings
from app.models.doctor_profile import DoctorProfile
from app.models.user import User
from app.schemas.doctor_profile import (
    DoctorProfileFullOut,
    DoctorProfilePatch,
    DoctorSearchItemOut,
    AccreditedCourseSubmitIn,
    PracticeLicenseSubmitIn,
    UploadOut,
    ExperienceScoreSnapshot,
)
from app.security import get_current_user
from app.services import doctor_peer_rating_service as peer_rating_svc
from app.services import doctor_profile_service as profile_svc
from app.services import experience_score_service as experience_score_svc
from app.schemas.doctor_peer_rating import (
    DoctorPeerRatingOut,
    DoctorPeerRatingSubmitIn,
    DoctorPeerRatingsListOut,
)
from app.services.otp_service import iraqi_phone_for_display

router = APIRouter(prefix="/profile", tags=["doctor-profile"])
settings = get_settings()

_ALLOWED_EXT = {".jpg", ".jpeg", ".png", ".webp", ".heic", ".heif"}
_CONTENT_TYPES = {
    "image/jpeg",
    "image/png",
    "image/webp",
    "image/heic",
    "image/heif",
}
_SUFFIX_TO_CONTENT_TYPE = {
    ".jpg": "image/jpeg",
    ".jpeg": "image/jpeg",
    ".png": "image/png",
    ".webp": "image/webp",
    ".heic": "image/heic",
    ".heif": "image/heif",
}

_DENTAL_SPECIALTIES = [
    "طبيب أسنان عام",
    "أخصائي تقويم الأسنان",
    "أخصائي جراحة الفم والوجه والفكين",
    "أخصائي علاج الجذور (العصب)",
    "أخصائي أمراض اللثة",
    "أخصائي التركيبات السنية",
    "أخصائي طب أسنان الأطفال",
    "أخصائي طب الفم",
    "أخصائي أشعة الفم والأسنان",
    "أخصائي صحة الفم العامة",
    "فني صناعة الأسنان",
    "مساعد طبيب أسنان",
    "فني صحة الأسنان",
    "تقني صناعة الأسنان",
    "تقني صحة الأسنان",
    "تقني تعويضات سنية",
    "تقني مختبر أسنان",
]

_EDUCATION_OPTIONS = [
    "دبلوم",
    "بكالوريوس",
    "ماجستير",
    "دكتوراه",
]

_LANGUAGE_OPTIONS = [
    "العربية",
    "الانجليزية",
]

_SKILL_OPTIONS = [
    "تبييض الأسنان",
    "حشوات تجميلية",
    "علاج قناة الجذر",
    "تقويم الأسنان",
    "جراحة الفم",
    "زراعة الأسنان",
    "تصميم الابتسامة",
    "الدقة والمهارة اليدوية",
    "التشخيص ووضع خطة العلاج",
    "التواصل مع المرضى",
    "إدارة الوقت وتنظيم المواعيد",
    "معرفة علمية قوية",
    "التعامل مع الأجهزة والتقنيات الحديثة",
    "التعقيم ومكافحة العدوى",
    "حل المشكلات واتخاذ القرارات",
    "الصبر والهدوء",
    "العمل ضمن فريق",
    "التطوير المستمر ومتابعة الجديد",
    "إدارة العيادة (مهارات إدارية)",
]

_UNIVERSITY_OPTIONS = [
    "جامعة بغداد",
    "الجامعة المستنصرية",
    "جامعة بابل",
    "جامعة الكوفة",
    "جامعة البصرة",
    "جامعة الموصل",
    "جامعة الأنبار",
    "جامعة تكريت",
    "جامعة ديالى",
    "جامعة القادسية",
    "جامعة كربلاء",
    "جامعة واسط",
    "جامعة المثنى",
    "جامعة ميسان",
    "جامعة ذي قار",
    "جامعة كركوك",
    "جامعة العراقية",
    "جامعة ابن سينا للعلوم الطبية والصيدلانية",
    "جامعة جابر بن حيان الطبية",
    "جامعة الكفيل",
    "جامعة الفراهيدي",
    "جامعة العين",
    "جامعة البيان",
    "جامعة العميد",
    "جامعة أورك",
    "جامعة الكتاب",
    "جامعة المعارف",
    "جامعة النور",
    "جامعة آشور",
    "جامعة القلم",
    "جامعة بلاد الرافدين",
    "جامعة التراث",
    "جامعة المستقبل",
    "جامعة الحلة",
    "جامعة أهل البيت",
    "الجامعة الإسلامية",
    "جامعة دجلة",
    "جامعة الصفوة",
    "جامعة الكوت",
    "جامعة الكنوز",
    "جامعة الفارابي",
    "جامعة المنارة للعلوم الطبية",
    "جامعة المشرق",
    "المعهد الطبي التقني بغداد",
    "المعهد الطبي التقني المنصور",
    "المعهد الطبي التقني الكوفة",
    "المعهد الطبي التقني بابل",
    "المعهد الطبي التقني البصرة",
    "المعهد الطبي التقني الموصل",
    "المعهد الطبي التقني كركوك",
    "المعهد الطبي التقني السليمانية",
    "المعهد الطبي التقني أربيل",
    "المعهد الطبي التقني دهوك",
    "الكلية التقنية الطبية بغداد",
    "الكلية التقنية الطبية الكوفة",
    "الكلية التقنية الطبية البصرة",
    "الكلية التقنية الطبية كركوك",
]


@router.get("/skill-options", response_model=list[str])
async def list_skill_options():
    """قائمة معرّفات المهارات الثابتة (تُحدَّث لاحقاً من الإدارة أو ملف ثابت)."""
    return _SKILL_OPTIONS


@router.get("/education-options", response_model=list[str])
async def list_education_options():
    """قائمة مستويات التعليم الثابتة."""
    return _EDUCATION_OPTIONS


@router.get("/language-options", response_model=list[str])
async def list_language_options():
    """قائمة اللغات الثابتة."""
    return _LANGUAGE_OPTIONS


@router.get("/university-options", response_model=list[str])
async def list_university_options():
    """قائمة الجامعات/المعاهد الثابتة لاستخدامها في اختيار التعليم."""
    return _UNIVERSITY_OPTIONS


@router.get("/specialties", response_model=list[str])
async def list_dental_specialties():
    """قائمة تخصصات أطباء الأسنان الثابتة للاستخدام في القوائم المنسدلة."""
    return _DENTAL_SPECIALTIES


@router.get("/me", response_model=DoctorProfileFullOut)
async def get_my_profile(current: User = Depends(get_current_user)):
    """بروفايل الطبيب الكامل: حقول الحساب + التعليم والخبرات والمكتبات."""
    return await profile_svc.get_merged_profile(current)


@router.get("/me/experience-score", response_model=ExperienceScoreSnapshot)
async def get_my_experience_score(current: User = Depends(get_current_user)):
    """نقاط الخبرة الخاصة بالمستخدم الحالي (مخزنة ومحدثة من الباكند)."""
    dp = await experience_score_svc.recompute_and_persist_for_user(current.id)
    if dp.experience_score is None:
        raise HTTPException(status_code=500, detail="Experience score unavailable")
    return dp.experience_score


@router.get("/doctors", response_model=list[DoctorSearchItemOut])
async def list_doctors_for_search(
    q: str | None = Query(None, description="نص بحث اختياري (اسم/تخصص/محافظة)"),
    current: User = Depends(get_current_user),
):
    """قائمة أطباء للبحث داخل التطبيق."""
    _ = current
    query = (q or "").strip().lower()
    users = await User.find_all().sort(-User.created_at).to_list()
    out: list[DoctorSearchItemOut] = []
    for u in users:
        dp = await DoctorProfile.find_one(DoctorProfile.user_id == u.id)
        if not dp:
            continue
        title = (dp.professional_title or "").strip() or "طبيب أسنان"
        gov = (dp.governorate or "").strip() or None
        disp_phone = iraqi_phone_for_display(u.phone)
        if query:
            hay = " ".join(
                [
                    (u.name or "").strip(),
                    title,
                    gov or "",
                    u.phone,
                    disp_phone,
                ]
            ).lower()
            if query not in hay:
                continue
        out.append(
            DoctorSearchItemOut(
                id=str(u.id),
                name=u.name,
                professional_title=title,
                imageUrl=u.imageUrl,
                years_experience=dp.years_experience,
                governorate=gov,
                phone=disp_phone,
            )
        )
    return out


@router.get(
    "/doctors/{user_id}/peer-ratings",
    response_model=DoctorPeerRatingsListOut,
)
async def list_doctor_peer_ratings(
    user_id: str,
    current: User = Depends(get_current_user),
):
    """تقييمات طبيب من زملائه — مع حالة تقييم المستخدم الحالي."""
    try:
        oid = PydanticObjectId(user_id.strip())
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid user id")
    return await peer_rating_svc.list_ratings_for_doctor(oid, current)


@router.post(
    "/doctors/{user_id}/peer-ratings",
    response_model=DoctorPeerRatingOut,
    status_code=201,
)
async def submit_doctor_peer_rating(
    user_id: str,
    payload: DoctorPeerRatingSubmitIn,
    current: User = Depends(get_current_user),
):
    """إرسال تقييم لطبيب — مرة واحدة فقط، يُعرض فوراً."""
    try:
        oid = PydanticObjectId(user_id.strip())
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid user id")
    return await peer_rating_svc.submit_peer_rating(current, oid, payload)


@router.get("/doctors/{user_id}", response_model=DoctorProfileFullOut)
async def get_doctor_profile_by_user_id(
    user_id: str,
    current: User = Depends(get_current_user),
):
    """بروفايل طبيب محدد (قراءة فقط) لصفحة البحث عن الأطباء."""
    _ = current
    try:
        oid = PydanticObjectId(user_id.strip())
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid user id")
    user = await User.get(oid)
    if not user:
        raise HTTPException(status_code=404, detail="Doctor not found")
    return await profile_svc.get_merged_profile_for_user(user)


@router.get("/doctors/{user_id}/experience-score", response_model=ExperienceScoreSnapshot)
async def get_doctor_experience_score_by_user_id(
    user_id: str,
    current: User = Depends(get_current_user),
):
    """نقاط خبرة طبيب محدد من الباكند."""
    _ = current
    try:
        oid = PydanticObjectId(user_id.strip())
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid user id")
    user = await User.get(oid)
    if not user:
        raise HTTPException(status_code=404, detail="Doctor not found")
    dp = await experience_score_svc.recompute_and_persist_for_user(user.id)
    if dp.experience_score is None:
        raise HTTPException(status_code=500, detail="Experience score unavailable")
    return dp.experience_score


@router.get(
    "/me/peer-ratings",
    response_model=DoctorPeerRatingsListOut,
)
async def list_my_peer_ratings(
    current: User = Depends(get_current_user),
):
    """تقييمات واردة لبروفايلي."""
    return await peer_rating_svc.list_ratings_for_doctor(current.id, current)


@router.patch("/me", response_model=DoctorProfileFullOut)
async def patch_my_profile(
    payload: DoctorProfilePatch,
    current: User = Depends(get_current_user),
):
    """تحديث جزئي لبيانات الحساب وبروفايل الطبيب."""
    return await profile_svc.patch_merged_profile(current, payload)


@router.post("/me/practice-license", response_model=DoctorProfileFullOut)
async def submit_practice_license(
    payload: PracticeLicenseSubmitIn,
    current: User = Depends(get_current_user),
):
    """إرسال شهادة ممارسة المهنة للتحقق الإداري."""
    return await profile_svc.submit_practice_license(current, payload)


@router.post("/me/accredited-courses", response_model=DoctorProfileFullOut)
async def submit_accredited_course(
    payload: AccreditedCourseSubmitIn,
    current: User = Depends(get_current_user),
):
    """إرسال دورة معتمدة للتحقق الإداري."""
    return await profile_svc.submit_accredited_course(current, payload)


@router.post("/me/upload", response_model=UploadOut)
async def upload_profile_file(
    current: User = Depends(get_current_user),
    file: UploadFile = File(..., description="صورة (jpg/png/webp)"),
    purpose: str = Query(
        "general",
        description="للتوثيق: avatar | general | gallery | certificate | practice_license | accredited_course",
    ),
):
    """
    رفع ملف صورة؛ يُعاد رابطاً نسبياً (`/static/uploads/...`) يُخزَّن في الحقول
    (مثل `imageUrl`، عناصر `gallery`، أو `certificate_images`).
    """
    _ = purpose
    raw_name = file.filename or "upload.bin"
    suffix = Path(raw_name).suffix.lower()
    if suffix not in _ALLOWED_EXT:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="امتداد الملف غير مدعوم",
        )

    ct = (file.content_type or "").split(";")[0].strip().lower()
    if ct == "image/jpg":
        ct = "image/jpeg"
    if ct in ("application/octet-stream", "binary/octet-stream", ""):
        ct = _SUFFIX_TO_CONTENT_TYPE.get(suffix, "")
    if ct and ct not in _CONTENT_TYPES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="نوع الملف غير مدعوم (استخدم jpg أو png أو webp)",
        )

    content = await file.read()
    max_b = settings.UPLOAD_MAX_BYTES
    if len(content) > max_b:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"حجم الملف يتجاوز {max_b // (1024 * 1024)} ميجابايت",
        )

    safe = f"{uuid.uuid4().hex}{suffix}"
    user_dir = Path(settings.UPLOAD_DIR) / str(current.id)
    user_dir.mkdir(parents=True, exist_ok=True)
    dest = user_dir / safe
    dest.write_bytes(content)

    url = f"/static/uploads/{current.id}/{safe}"
    return UploadOut(url=url, filename=safe)
