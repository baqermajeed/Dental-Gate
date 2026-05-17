#!/usr/bin/env python3
"""
تشغيل لمرة واحدة (من مجلد backend):
  .\\.venv\\Scripts\\python.exe scripts/seed_demo_doctor_077.py

يملأ/يحدّث بيانات الطبيب صاحب الرقم 07746818591 ويربط الصور بعد نسخها إلى uploads/.

ضع ملفات PNG في أحد المجلدين:
  - Dental Gate/Backend/   (Group 219.png, Group 220.png, ...)
  - backend/seed_assets/   (نسخة احتياطية)
"""

from __future__ import annotations

import asyncio
import shutil
import sys
from datetime import date, datetime, timezone
from pathlib import Path

# تشغيل السكربت من مجلد backend
_BACKEND = Path(__file__).resolve().parents[1]
if str(_BACKEND) not in sys.path:
    sys.path.insert(0, str(_BACKEND))

from beanie import init_beanie
from motor.motor_asyncio import AsyncIOMotorClient

from app.config import get_settings
from app.constants import Role
from app.models.doctor_profile import (
    CertificateImage,
    DegreeType,
    DoctorProfile,
    EducationEntry,
    GalleryItem,
    WorkExperience,
)
from app.models.otp import OTPRequest
from app.models.user import User
from app.services.otp_service import normalize_iraqi_phone

# --- بيانات ثابتة (تجربة) ---
PHONE_RAW = "07746818591"
EMAIL = "baqermajeed1212@gmail.com"
NAME = "بهجة علي رضا"
GENDER = "female"
AGE = 34

BIO = (
    "طبيبة أسنان تتمتع بخبرة واسعة تزيد عن 10 سنوات في مجال طب الأسنان العام و التجميلي . "
    "و تسعى دائماً لتطوير مهاراتها من خلال حضور المؤتمرات و ورش العمل , عرض المزيد . ."
)

GOVERNORATE = "بابل"
YEARS_EXP = 10

LANGUAGES = [
    "العربية ( اللغة الأُم )",
    "الأنجليزية  ( مُمتازة )",
]

SKILLS = [
    "جراحة الفم",
    "تبييض الأسنان",
    "طب أسنان الأطفال",
    "حشوات تجميلية",
    "علاج قناة الجذر المتقدم",
    "أجهزة التقويم",
]

# أسماء الملفات المتوقعة في مجلد Backend (أو seed_assets)
ASSET_MAP: list[tuple[str, str]] = [
    ("Group 219.png", "group_219.png"),
    ("Group 220.png", "group_220.png"),
    ("Group 220س.png", "group_220s.png"),
    ("Rectangle 79.png", "rectangle_79.png"),
    ("Rectangle 79ء.png", "rectangle_79_hamza.png"),
]


def _project_root() -> Path:
    return _BACKEND.parent


def _asset_roots() -> list[Path]:
    root = _project_root()
    return [
        root / "Backend",
        root / "backend" / "seed_assets",
        _BACKEND / "seed_assets",
    ]


def _find_source_file(preferred_name: str) -> Path | None:
    """يبحث عن ملف PNG بالاسم أو بأقرب تطابق (مثل Group 220س)."""
    roots = _asset_roots()
    for base in roots:
        if not base.is_dir():
            continue
        direct = base / preferred_name
        if direct.is_file():
            return direct
        # بدون حساسية لحالة الأحرف
        lower = preferred_name.lower()
        for f in base.iterdir():
            if f.is_file() and f.suffix.lower() == ".png" and f.name.lower() == lower:
                return f
    # ملف يحوي «220» وغير الاسم القياسي Group 220.png (مثل Group 220س.png)
    if preferred_name == "Group 220س.png":
        for base in roots:
            if not base.is_dir():
                continue
            for f in base.iterdir():
                if (
                    f.is_file()
                    and f.suffix.lower() == ".png"
                    and f.name.startswith("Group 220")
                    and f.name != "Group 220.png"
                ):
                    return f
    return None


def _copy_to_uploads(user_id: str, mapping: list[tuple[Path, str]]) -> dict[str, str]:
    """ينسخ إلى backend/uploads/{user_id}/ ويعيد اسم منطقي -> URL للـ API."""
    settings = get_settings()
    upload_root = (_BACKEND / settings.UPLOAD_DIR).resolve()
    dest_dir = upload_root / user_id
    dest_dir.mkdir(parents=True, exist_ok=True)
    urls: dict[str, str] = {}
    for src, dest_name in mapping:
        dest_path = dest_dir / dest_name
        shutil.copy2(src, dest_path)
        url = f"/static/uploads/{user_id}/{dest_name}"
        urls[dest_name] = url
    return urls


async def _init_db() -> None:
    settings = get_settings()
    client = AsyncIOMotorClient(settings.MONGODB_URI)
    db_name = settings.MONGODB_URI.rsplit("/", 1)[-1].split("?")[0]
    if not db_name:
        db_name = "dental_gate_db"
    await init_beanie(
        database=client[db_name],
        document_models=[User, OTPRequest, DoctorProfile],
    )


async def main() -> None:
    await _init_db()
    phone = normalize_iraqi_phone(PHONE_RAW)

    user = await User.find_one(User.phone == phone)
    if not user:
        variants = {PHONE_RAW.strip(), phone}
        if phone.startswith("9647") and len(phone) > 3:
            variants.add("0" + phone[3:])
        user = await User.find_one({"phone": {"$in": list(variants)}})

    if not user:
        print("لا يوجد مستخدم بهذا الرقم — إنشاء حساب تجريبي...")
        user = User(
            name=NAME,
            phone=phone,
            email=EMAIL.strip().lower(),
            role=Role.DENTIST,
            gender=GENDER,
            age=AGE,
        )
        try:
            await user.insert()
            print("تم إنشاء المستخدم:", user.id)
        except Exception as e:
            print("فشل إنشاء المستخدم (ربما البريد أو الهاتف مُستخدم):", e)
            raise
    else:
        user.name = NAME
        user.email = EMAIL.strip().lower()
        user.gender = GENDER
        user.age = AGE
        user.updated_at = datetime.now(timezone.utc)
        await user.save()
        print("تم تحديث المستخدم الموجود:", user.id)

    # جمع ملفات المصدر
    resolved: list[tuple[Path, str]] = []
    missing: list[str] = []
    for src_name, dest_name in ASSET_MAP:
        p = _find_source_file(src_name)
        if p is None:
            missing.append(src_name)
        else:
            resolved.append((p, dest_name))

    if missing:
        print(
            "تحذير: ملفات غير موجودة (ضعها في Dental Gate/Backend أو backend/seed_assets):",
            missing,
        )
    if not resolved:
        print("خطأ: لم يُعثر على أي PNG. أوقف التنفيذ.")
        raise SystemExit(1)

    uid = str(user.id)
    url_by_dest = _copy_to_uploads(uid, resolved)

    def u(dest: str) -> str:
        return url_by_dest.get(dest, "")

    # روابط حسب الأسماء المنطقية بعد النسخ
    url_219 = u("group_219.png")
    url_220 = u("group_220.png")
    url_220s = u("group_220s.png")
    url_r79 = u("rectangle_79.png")
    url_r79h = u("rectangle_79_hamza.png")

    user.imageUrl = url_219 or url_220 or next(iter(url_by_dest.values()), None)
    await user.save()

    grad = date(2025, 6, 30)
    education = [
        EducationEntry(
            degree_type=DegreeType.BACHELOR,
            university="Oxford University",
            graduation_date=grad,
        ),
        EducationEntry(
            degree_type=DegreeType.BACHELOR,
            university="Oxford University",
            graduation_date=grad,
        ),
    ]

    experiences = [
        WorkExperience(
            experience_type="مساعد طبيب",
            workplace="عيادة نيلوفر لطب الأسنان",
            period_start=date(2018, 1, 1),
            period_end=date(2020, 12, 31),
            description=None,
        ),
        WorkExperience(
            experience_type="متدرب",
            workplace="مستشفى الأساس التعليمي",
            period_start=date(2015, 1, 1),
            period_end=date(2018, 1, 1),
            description=None,
        ),
    ]

    gallery_images: list[str] = []
    if url_219:
        gallery_images.append(url_219)
    if url_220:
        gallery_images.append(url_220)
    if len(gallery_images) < 1:
        gallery_images = [next(iter(url_by_dest.values()))]

    gallery = [
        GalleryItem(
            images=gallery_images[:2],
            caption=(
                "تبييض الأسنان\n\n"
                "تبييض الأسنان بالليزر هو إجراء تجميلي يستخدم الليزر لتفعيل جل تبييض الأسنان ."
            ),
        )
    ]

    certs: list[CertificateImage] = []
    if url_220s:
        certs.append(
            CertificateImage(url=url_220s, title="Board of Oral Surgery")
        )
    if url_r79h:
        certs.append(CertificateImage(url=url_r79h, title="Oxford University"))
    if url_r79 and url_r79 not in {c.url for c in certs}:
        certs.append(CertificateImage(url=url_r79, title="شهادة إضافية"))

    dp = await DoctorProfile.find_one(DoctorProfile.user_id == user.id)
    if not dp:
        dp = DoctorProfile(user_id=user.id)

    dp.governorate = GOVERNORATE
    dp.bio = BIO
    dp.years_experience = YEARS_EXP
    dp.languages = LANGUAGES
    dp.education = education
    dp.experiences = experiences
    dp.skill_ids = SKILLS
    dp.gallery = gallery
    dp.certificate_images = certs
    dp.updated_at = datetime.now(timezone.utc)
    await dp.save()

    print("تم حفظ بروفايل الطبيب.")
    print("  user_id:", uid)
    print("  صورة الملف:", user.imageUrl)
    print("  المكتبة العملية:", len(gallery[0].images), "صورة(صور)")
    print("  الشهادات:", len(certs))


if __name__ == "__main__":
    asyncio.run(main())
