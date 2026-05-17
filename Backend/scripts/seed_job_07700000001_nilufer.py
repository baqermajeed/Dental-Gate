#!/usr/bin/env python3
"""
زرع وظيفة واحدة لصاحب الرقم 07700000001 (عيادة نيلوفر).

تشغيل مرة واحدة من مجلد backend:
  .\\.venv\\Scripts\\python.exe scripts/seed_job_07700000001_nilufer.py

إن وُجدت وظيفة بنفس اسم المكان لنفس المستخدم، يُطبع رسالة ولا يُكرّر الإدراج.
"""

from __future__ import annotations

import asyncio
import sys
from datetime import datetime, timezone
from pathlib import Path

_BACKEND = Path(__file__).resolve().parents[1]
if str(_BACKEND) not in sys.path:
    sys.path.insert(0, str(_BACKEND))

from beanie import PydanticObjectId, init_beanie
from motor.motor_asyncio import AsyncIOMotorClient

from app.config import get_settings
from app.constants import Role
from app.models.job import JobEducation, JobLanguage, JobPosting
from app.models.otp import OTPRequest
from app.models.user import User
from app.services.otp_service import normalize_iraqi_phone

PHONE_RAW = "07700000001"
SEED_EMAIL = "seed.job.07700000001@dentalgate.local"
SEED_NAME = "ناشر الوظيفة (تجريبي)"

JOB_SEEDS = [
    {
        "workplace_name": "عيادة نيلوفر",
        "workplace_address": "بابل ، شارع الأطباء",
        "required_specialty": "طبيب أسنان مساعد",
        "years_experience": 6,
        "monthly_salary_iqd": 1_000_000,
        "shift_hours": 12,
        "working_hours": "8 ساعات من 2 الى 10",
        "description": (
            "طبيبة أسنان تتمتع بخبرة واسعة تزيد عن 10 سنوات في مجال طب الأسنان العام و التجميلي . "
            "و تسعى دائماً لتطوير مهاراتها من خلال حضور المؤتمرات و ورش العمل"
        ),
        "core_skills": ["جراحة الفم", "تبييض الأسنان", "طب أسنان الأطفال"],
    },
    {
        "workplace_name": "مركز بغداد لطب الأسنان",
        "workplace_address": "بغداد ، الكرادة",
        "required_specialty": "أخصائي تقويم الأسنان",
        "years_experience": 4,
        "monthly_salary_iqd": 1_500_000,
        "shift_hours": 8,
        "working_hours": "من 9 صباحاً الى 5 مساءً",
        "description": "مطلوب طبيب تقويم أسنان للعمل ضمن فريق متخصص مع توفر أجهزة حديثة.",
        "core_skills": ["تركيب التقويم الثابت", "تحليل صور الأشعة", "خطة علاج تقويم"],
    },
    {
        "workplace_name": "عيادة الابتسامة الذهبية",
        "workplace_address": "النجف ، حي الأمير",
        "required_specialty": "طبيب أسنان تجميلي",
        "years_experience": 5,
        "monthly_salary_iqd": 1_300_000,
        "shift_hours": 10,
        "working_hours": "من 11 صباحاً الى 9 مساءً",
        "description": "فرصة عمل لطبيب أسنان تجميلي بخبرة في عدسات الأسنان وتبييض احترافي.",
        "core_skills": ["فينير", "هوليود سمايل", "إعادة تشكيل اللثة تجميلياً"],
    },
    {
        "workplace_name": "مستشفى الفرات التخصصي",
        "workplace_address": "كربلاء ، شارع الإسكان",
        "required_specialty": "جراح فم وفكين",
        "years_experience": 7,
        "monthly_salary_iqd": 2_000_000,
        "shift_hours": 12,
        "working_hours": "نظام شفتات صباحي ومسائي",
        "description": "مطلوب جراح فم وفكين لإدارة الحالات الجراحية المعقدة داخل المستشفى.",
        "core_skills": ["خلع جراحي", "زراعة الأسنان", "جراحات الفك البسيطة"],
    },
]


async def _init_db() -> None:
    settings = get_settings()
    client = AsyncIOMotorClient(settings.MONGODB_URI)
    db_name = settings.MONGODB_URI.rsplit("/", 1)[-1].split("?")[0]
    if not db_name:
        db_name = "dental_gate_db"
    await init_beanie(
        database=client[db_name],
        document_models=[User, OTPRequest, JobPosting],
    )


async def _resolve_user(phone: str) -> User:
    user = await User.find_one(User.phone == phone)
    if not user:
        variants = {PHONE_RAW.strip(), phone}
        if phone.startswith("9647") and len(phone) > 3:
            variants.add("0" + phone[3:])
        user = await User.find_one({"phone": {"$in": list(variants)}})

    if not user:
        print("لا يوجد مستخدم بهذا الرقم — إنشاء حساب بسيط للزرع...")
        user = User(
            name=SEED_NAME,
            phone=phone,
            email=SEED_EMAIL.strip().lower(),
            role=Role.DENTIST,
        )
        await user.insert()
        print("تم إنشاء المستخدم:", user.id)
    return user


async def main() -> None:
    await _init_db()
    phone = normalize_iraqi_phone(PHONE_RAW)
    user = await _resolve_user(phone)
    uid = PydanticObjectId(user.id)

    inserted_count = 0
    for payload in JOB_SEEDS:
        existing = await JobPosting.find_one(
            JobPosting.posted_by == uid,
            JobPosting.workplace_name == payload["workplace_name"],
        )
        if existing:
            print(
                f"الوظيفة ({payload['workplace_name']}) موجودة مسبقاً — لم يُضف سجل جديد."
            )
            print("  job_id:", existing.id)
            continue

        now = datetime.now(timezone.utc)
        job = JobPosting(
            posted_by=uid,
            workplace_name=payload["workplace_name"],
            workplace_address=payload["workplace_address"],
            required_specialty=payload["required_specialty"],
            years_experience=payload["years_experience"],
            monthly_salary_iqd=payload["monthly_salary_iqd"],
            shift_hours=payload["shift_hours"],
            working_hours=payload["working_hours"],
            description=payload["description"],
            education=JobEducation.BACHELOR,
            languages=[JobLanguage.ARABIC, JobLanguage.ENGLISH],
            core_skills=payload["core_skills"],
            created_at=now,
            updated_at=now,
        )
        await job.insert()
        inserted_count += 1
        print(f"تم إدراج الوظيفة: {payload['workplace_name']}")
        print("  posted_by (user_id):", user.id)
        print("  job_id:", job.id)

    print(f"اكتمل الزرع. الوظائف الجديدة المضافة: {inserted_count}")


if __name__ == "__main__":
    if sys.platform == "win32":
        try:
            sys.stdout.reconfigure(encoding="utf-8")
        except Exception:
            pass
    asyncio.run(main())
